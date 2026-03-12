import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/ai_chat/data/datasources/chat_local_datasource.dart';
import 'package:activ_education_app/features/ai_chat/domain/entities/chat_message.dart';
import 'package:activ_education_app/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:activ_education_app/features/ai_chat/presentation/bloc/chat_bloc.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

// ============================================================================
// Fixtures
// ============================================================================

final tUserMessage = ChatMessage(
  id: 'msg-1',
  content: 'Quelles filières correspondent à mon profil RSI ?',
  role: MessageRole.user,
  timestamp: DateTime(2025, 3, 12, 10, 0),
);

final tAssistantMessage = ChatMessage(
  id: 'msg-2',
  content: 'Avec un profil RSI, je vous recommande les filières en ingénierie sociale, '
      'médecine communautaire ou travail social technique.',
  role: MessageRole.assistant,
  timestamp: DateTime(2025, 3, 12, 10, 0, 1),
);

const tSessionId = 'session-abc-123';
const tUserId = 'user-123';

// ============================================================================
// Tests
// ============================================================================

void main() {
  late MockChatRepository mockRepository;
  late MockChatLocalDataSource mockLocalDataSource;
  late ChatBloc chatBloc;

  setUpAll(() {
    registerFallbackValue(tUserMessage);
  });

  setUp(() {
    mockRepository = MockChatRepository();
    mockLocalDataSource = MockChatLocalDataSource();

    // Defaults
    when(() => mockLocalDataSource.getSessionId(any()))
        .thenAnswer((_) async => tSessionId);
    when(() => mockLocalDataSource.getMessages(any()))
        .thenAnswer((_) async => []);
    when(() => mockLocalDataSource.saveMessages(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveSessionId(any(), any()))
        .thenAnswer((_) async {});

    chatBloc = ChatBloc(mockRepository, mockLocalDataSource);
  });

  tearDown(() => chatBloc.close());

  // --------------------------------------------------------------------------
  // État initial
  // --------------------------------------------------------------------------

  test('état initial est ChatInitial', () {
    expect(chatBloc.state, isA<ChatInitial>());
  });

  // --------------------------------------------------------------------------
  // LoadChatHistory
  // --------------------------------------------------------------------------

  group('LoadChatHistory', () {
    blocTest<ChatBloc, ChatState>(
      'émet ChatReady avec historique vide pour une nouvelle session',
      build: () {
        when(() => mockLocalDataSource.getMessages(any()))
            .thenAnswer((_) async => []);
        return chatBloc;
      },
      act: (bloc) => bloc.add(LoadChatHistory(tUserId)),
      expect: () => [
        predicate<ChatState>(
          (s) => s is ChatReady && s.messages.isNotEmpty,
          'ChatReady avec message de bienvenue',
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'émet ChatReady avec historique existant',
      build: () {
        when(() => mockLocalDataSource.getMessages(any()))
            .thenAnswer((_) async => [tUserMessage, tAssistantMessage]);
        return chatBloc;
      },
      act: (bloc) => bloc.add(LoadChatHistory(tUserId)),
      expect: () => [
        predicate<ChatState>(
          (s) => s is ChatReady && s.messages.any((m) => m.id == tUserMessage.id),
          'ChatReady avec messages existants',
        ),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // SendMessage
  // --------------------------------------------------------------------------

  group('SendMessage', () {
    blocTest<ChatBloc, ChatState>(
      'émet [ChatReady(loading=true), ChatReady(loading=false)] sur succès',
      build: () {
        when(() => mockLocalDataSource.getMessages(any()))
            .thenAnswer((_) async => []);
        when(() => mockRepository.sendMessage(
              message: any(named: 'message'),
              sessionId: any(named: 'sessionId'),
              orientationContext: any(named: 'orientationContext'),
              history: any(named: 'history'),
            )).thenAnswer((_) async => tAssistantMessage);
        return chatBloc;
      },
      seed: () => ChatReady(messages: [tUserMessage]),
      act: (bloc) => bloc.add(const SendMessage('Mon message')),
      expect: () => [
        predicate<ChatState>(
          (s) => s is ChatReady && s.isLoading,
          'ChatReady avec isLoading=true',
        ),
        predicate<ChatState>(
          (s) => s is ChatReady && !s.isLoading && s.messages.isNotEmpty,
          'ChatReady avec réponse ajoutée',
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'émet ChatReady avec error sur erreur réseau',
      build: () {
        when(() => mockLocalDataSource.getMessages(any()))
            .thenAnswer((_) async => []);
        when(() => mockRepository.sendMessage(
              message: any(named: 'message'),
              sessionId: any(named: 'sessionId'),
              orientationContext: any(named: 'orientationContext'),
              history: any(named: 'history'),
            )).thenThrow(Exception('Réseau indisponible'));
        return chatBloc;
      },
      seed: () => ChatReady(messages: []),
      act: (bloc) => bloc.add(const SendMessage('Mon message')),
      expect: () => [
        predicate<ChatState>((s) => s is ChatReady && s.isLoading, 'loading'),
        predicate<ChatState>(
          (s) => s is ChatReady && s.error != null,
          'ChatReady avec error',
        ),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // ClearChatSession
  // --------------------------------------------------------------------------

  group('ClearChatSession', () {
    blocTest<ChatBloc, ChatState>(
      'efface les messages et crée une nouvelle session',
      build: () {
        when(() => mockRepository.clearSession(any()))
            .thenAnswer((_) async {});
        when(() => mockLocalDataSource.clearMessages(any()))
            .thenAnswer((_) async {});
        return chatBloc;
      },
      seed: () => ChatReady(messages: [tUserMessage, tAssistantMessage]),
      act: (bloc) => bloc.add(ClearChatSession()),
      expect: () => [
        predicate<ChatState>(
          (s) => s is ChatReady && s.messages.length == 1,
          'ChatReady avec seulement le message de bienvenue',
        ),
      ],
    );
  });
}
