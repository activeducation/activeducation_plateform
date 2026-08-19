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

  /// True pendant qu'une réponse arrive en flux (SSE) : la dernière bulle
  /// assistant grandit en direct et l'indicateur de frappe est masqué.
  final bool isStreaming;
  final String? error;

  const ChatReady({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
  });

  ChatReady copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    bool clearError = false,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isStreaming, error];
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

  // Valeur par défaut pour éviter tout LateInitializationError si un message
  // est envoyé avant LoadChatHistory ; écrasée dès le chargement de l'historique.
  String _sessionId = const Uuid().v4();
  String? _userId;

  ChatBloc(this._repository, this._localStorage, {this.orientationContext})
    : super(ChatInitial()) {
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
    final current = state is ChatReady ? state as ChatReady : const ChatReady();

    // Ajouter le message utilisateur immédiatement
    final userMsg = ChatMessageModel.fromUser(event.message);
    final messagesWithUser = [...current.messages, userMsg];
    final history = _buildBackendHistory(messagesWithUser);

    emit(
      current.copyWith(
        messages: messagesWithUser,
        isLoading: true,
        isStreaming: false,
        clearError: true,
      ),
    );

    // Chemin principal : streaming SSE (premier token < 500 ms).
    final assistantId = const Uuid().v4();
    final buffer = StringBuffer();

    try {
      await for (final chunk in _repository.streamMessage(
        message: event.message,
        sessionId: _sessionId,
        orientationContext: orientationContext,
        history: history,
      )) {
        buffer.write(chunk);
        final streamingMsg = ChatMessageModel(
          id: assistantId,
          content: buffer.toString(),
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        );
        emit(
          ChatReady(
            messages: [...messagesWithUser, streamingMsg],
            isLoading: true,
            isStreaming: true,
          ),
        );
      }

      if (buffer.isEmpty) {
        // Aucun fragment reçu (SSE bufferisé par un proxy, non supporté web…)
        await _sendViaFallback(event, messagesWithUser, history, emit);
        return;
      }

      await _finalizeAssistant(assistantId, buffer.toString(), messagesWithUser, emit);
    } catch (e) {
      if (buffer.isNotEmpty) {
        // On garde le texte déjà streamé plutôt que de tout perdre.
        await _finalizeAssistant(assistantId, buffer.toString(), messagesWithUser, emit);
        return;
      }
      // Rien reçu → repli sur le mode JSON non-streaming.
      await _sendViaFallback(event, messagesWithUser, history, emit);
    }
  }

  /// Finalise la bulle assistant (fin du stream) et persiste l'échange.
  Future<void> _finalizeAssistant(
    String assistantId,
    String content,
    List<ChatMessage> messagesWithUser,
    Emitter<ChatState> emit,
  ) async {
    final finalMessages = [
      ...messagesWithUser,
      ChatMessageModel(
        id: assistantId,
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    ];
    emit(ChatReady(messages: finalMessages, isLoading: false, isStreaming: false));
    await _persist(finalMessages);
  }

  /// Repli non-streaming (POST /message) si le SSE échoue avant tout fragment.
  Future<void> _sendViaFallback(
    SendMessage event,
    List<ChatMessage> messagesWithUser,
    List<Map<String, String>>? history,
    Emitter<ChatState> emit,
  ) async {
    try {
      final reply = await _repository.sendMessage(
        message: event.message,
        sessionId: _sessionId,
        orientationContext: orientationContext,
        history: history,
      );
      final allMessages = [...messagesWithUser, reply];
      emit(ChatReady(messages: allMessages, isLoading: false, isStreaming: false));
      await _persist(allMessages);
    } catch (_) {
      emit(
        ChatReady(
          messages: messagesWithUser,
          isLoading: false,
          isStreaming: false,
          error: 'Impossible de contacter AÏDA. Vérifiez votre connexion.',
        ),
      );
      await _persist(messagesWithUser);
    }
  }

  /// Persiste les messages en local (après chaque échange).
  Future<void> _persist(List<ChatMessage> messages) async {
    if (_userId != null) {
      final models = messages.whereType<ChatMessageModel>().toList();
      await _localStorage.saveMessages(_userId!, models);
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

    return recent
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
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
