import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/datasources/chat_local_datasource.dart';

// ===========================================================================
// Events
// ===========================================================================

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

/// Charge l'historique persisté pour un utilisateur.
class LoadChatHistory extends ChatEvent {
  final String userId;
  const LoadChatHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SendMessage extends ChatEvent {
  final String message;
  const SendMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class ClearChatSession extends ChatEvent {}

// ===========================================================================
// States
// ===========================================================================

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatReady extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatReady({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatReady copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error];
}

// ===========================================================================
// BLoC
// ===========================================================================

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final ChatLocalDataSource _localStorage;
  final Map<String, dynamic>? orientationContext;

  /// Nombre max de messages envoyés au backend pour le seeding.
  static const int _maxBackendHistory = 8;

  late String _sessionId;
  String? _userId;

  ChatBloc(
    this._repository,
    this._localStorage, {
    this.orientationContext,
  }) : super(ChatInitial()) {
    on<LoadChatHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage);
    on<ClearChatSession>(_onClearSession);
  }

  // ---- Load history ----

  Future<void> _onLoadHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    _userId = event.userId;

    // Tenter de restaurer la session précédente
    final savedMessages = _localStorage.loadMessages(event.userId);
    final savedSessionId = _localStorage.loadSessionId(event.userId);

    if (savedMessages.isNotEmpty && savedSessionId != null) {
      // Restaurer la session existante
      _sessionId = savedSessionId;
      emit(ChatReady(messages: savedMessages));
    } else {
      // Nouvelle session
      _sessionId = const Uuid().v4();
      await _localStorage.saveSessionId(event.userId, _sessionId);

      final welcome = ChatMessageModel(
        id: const Uuid().v4(),
        content: orientationContext != null
            ? _buildWelcomeWithContext(orientationContext!)
            : 'Bonjour ! Je suis **AÏDA**, votre conseillère d\'orientation. '
                'Posez-moi toutes vos questions sur les filières, les métiers '
                'ou votre avenir professionnel. Je suis là pour vous guider !',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      await _localStorage.saveMessages(event.userId, [welcome]);
      emit(ChatReady(messages: [welcome]));
    }
  }

  // ---- Send message ----

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state is ChatReady
        ? state as ChatReady
        : const ChatReady();

    // Ajouter le message utilisateur immédiatement
    final userMsg = ChatMessageModel.fromUser(event.message);
    final messagesWithUser = [...current.messages, userMsg];

    emit(current.copyWith(
      messages: messagesWithUser,
      isLoading: true,
      clearError: true,
    ));

    try {
      final reply = await _repository.sendMessage(
        message: event.message,
        sessionId: _sessionId,
        orientationContext: orientationContext,
        history: _buildBackendHistory(messagesWithUser),
      );

      final updated = state as ChatReady;
      final allMessages = [...updated.messages, reply];

      emit(updated.copyWith(
        messages: allMessages,
        isLoading: false,
      ));

      // Persister après chaque échange
      if (_userId != null) {
        final models = allMessages
            .whereType<ChatMessageModel>()
            .toList();
        await _localStorage.saveMessages(_userId!, models);
      }
    } catch (e) {
      final updated = state as ChatReady;
      emit(updated.copyWith(
        isLoading: false,
        error: 'Impossible de contacter AÏDA. Vérifiez votre connexion.',
      ));

      // Sauvegarder quand même le message utilisateur
      if (_userId != null) {
        final models = messagesWithUser
            .whereType<ChatMessageModel>()
            .toList();
        await _localStorage.saveMessages(_userId!, models);
      }
    }
  }

  // ---- Clear session ----

  Future<void> _onClearSession(
    ClearChatSession event,
    Emitter<ChatState> emit,
  ) async {
    // Effacer côté serveur
    try {
      await _repository.clearSession(_sessionId);
    } catch (_) {}

    // Effacer le localStorage
    if (_userId != null) {
      await _localStorage.clearHistory(_userId!);
    }

    // Nouvelle session
    _sessionId = const Uuid().v4();
    if (_userId != null) {
      await _localStorage.saveSessionId(_userId!, _sessionId);
    }

    final welcome = ChatMessageModel(
      id: const Uuid().v4(),
      content: 'Conversation réinitialisée. Comment puis-je vous aider ?',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    if (_userId != null) {
      await _localStorage.saveMessages(_userId!, [welcome]);
    }

    emit(ChatReady(messages: [welcome]));
  }

  // ---- Helpers ----

  /// Construit l'historique à envoyer au backend pour le seeding de session.
  List<Map<String, String>>? _buildBackendHistory(List<ChatMessage> messages) {
    if (messages.length <= 1) return null;

    final recent = messages.length > _maxBackendHistory
        ? messages.sublist(messages.length - _maxBackendHistory)
        : messages;

    return recent.map((m) => {
      'role': m.role == MessageRole.user ? 'user' : 'assistant',
      'content': m.content,
    }).toList();
  }

  String _buildWelcomeWithContext(Map<String, dynamic> ctx) {
    final code = ctx['profile_code'] as String?;
    final traits = (ctx['dominant_traits'] as List?)?.take(2).join(' et ');
    if (code != null && traits != null) {
      return 'Bonjour ! Je suis **AÏDA**, votre conseillère d\'orientation. '
          'J\'ai bien analysé votre profil **$code** avec vos traits $traits. '
          'Vous avez des questions sur vos résultats, les filières conseillées '
          'ou votre avenir professionnel ? Je suis là !';
    }
    return 'Bonjour ! Je suis **AÏDA**. J\'ai analysé vos résultats d\'orientation '
        'et je suis prête à répondre à toutes vos questions sur votre avenir !';
  }
}
