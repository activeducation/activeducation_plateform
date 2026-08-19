import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/ai_chat/data/datasources/chat_local_datasource.dart';
import 'package:activ_education_app/features/ai_chat/data/models/chat_message_model.dart';
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

final tUserMessage = ChatMessageModel(
  id: 'msg-1',
  content: 'Quelles filières correspondent à mon profil RSI ?',
  role: MessageRole.user,
  timestamp: DateTime(2025, 3, 12, 10, 0),
);

final tAssistantMessage = ChatMessageModel(
  id: 'msg-2',
  content:
      'Avec un profil RSI, je vous recommande les filières en ingénierie sociale, '
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

    // Defaults — loadMessages et loadSessionId sont synchrones
    when(() => mockLocalDataSource.loadSessionId(any())).thenReturn(null);
    when(() => mockLocalDataSource.loadMessages(any())).thenReturn([]);
    when(
      () => mockLocalDataSource.saveMessages(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.saveSessionId(any(), any()),
    ).thenAnswer((_) async {});

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
      'émet ChatReady avec message de bienvenue pour une nouvelle session',
      build: () {
        when(() => mockLocalDataSource.loadMessages(any())).thenReturn([]);
        when(() => mockLocalDataSource.loadSessionId(any())).thenReturn(null);
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
        when(
          () => mockLocalDataSource.loadMessages(any()),
        ).thenReturn([tUserMessage, tAssistantMessage]);
        when(
          () => mockLocalDataSource.loadSessionId(any()),
        ).thenReturn(tSessionId);
        return chatBloc;
      },
      act: (bloc) => bloc.add(LoadChatHistory(tUserId)),
      expect: () => [
        predicate<ChatState>(
          (s) =>
              s is ChatReady && s.messages.any((m) => m.id == tUserMessage.id),
          'ChatReady avec messages existants',
        ),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // SendMessage
  // --------------------------------------------------------------------------

  group('SendMessage', () {
    // Le streaming émet un nombre variable d'états (un par fragment). On pose
    // l'attente AVANT d'ajouter l'event (le stream du bloc est broadcast : un
    // abonnement tardif raterait les premiers états), et on matche via
    // emitsThrough sur l'état final voulu.

    test('streaming agrège les fragments en une réponse assistant', () async {
      when(
        () => mockRepository.streamMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenAnswer((_) => Stream<String>.fromIterable(['Bonjour', ' à toi']));

      final expectation = expectLater(
        chatBloc.stream,
        emitsThrough(predicate<ChatState>(
          (s) =>
              s is ChatReady &&
              !s.isLoading &&
              !s.isStreaming &&
              s.messages.any((m) => m.isAssistant && m.content == 'Bonjour à toi'),
          'ChatReady final avec la réponse agrégée',
        )),
      );

      chatBloc.add(const SendMessage('Salut'));
      await expectation;
    });

    test('passe par isStreaming=true pendant la réception des fragments', () async {
      when(
        () => mockRepository.streamMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenAnswer((_) => Stream<String>.fromIterable(['fragment']));

      final expectation = expectLater(
        chatBloc.stream,
        emitsThrough(predicate<ChatState>(
          (s) => s is ChatReady && s.isStreaming,
          'ChatReady en cours de streaming',
        )),
      );

      chatBloc.add(const SendMessage('Salut'));
      await expectation;
    });

    test('repli sur sendMessage si le stream ne renvoie aucun fragment', () async {
      when(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenAnswer((_) async => tAssistantMessage);
      when(
        () => mockRepository.streamMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenAnswer((_) => const Stream<String>.empty());

      final expectation = expectLater(
        chatBloc.stream,
        emitsThrough(predicate<ChatState>(
          (s) =>
              s is ChatReady &&
              !s.isLoading &&
              s.messages.any((m) => m.id == tAssistantMessage.id),
          'ChatReady avec la réponse du fallback',
        )),
      );

      chatBloc.add(const SendMessage('Salut'));
      await expectation;

      verify(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).called(1);
    });

    test('affiche une erreur si stream et repli échouent', () async {
      when(
        () => mockRepository.streamMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenAnswer((_) => Stream<String>.error(Exception('SSE bloqué')));
      when(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          orientationContext: any(named: 'orientationContext'),
          history: any(named: 'history'),
        ),
      ).thenThrow(Exception('Réseau indisponible'));

      final expectation = expectLater(
        chatBloc.stream,
        emitsThrough(predicate<ChatState>(
          (s) => s is ChatReady && !s.isLoading && s.error != null,
          'ChatReady avec erreur',
        )),
      );

      chatBloc.add(const SendMessage('Salut'));
      await expectation;
    });
  });

  // --------------------------------------------------------------------------
  // ClearChatSession
  // --------------------------------------------------------------------------

  group('ClearChatSession', () {
    blocTest<ChatBloc, ChatState>(
      'efface les messages et crée une nouvelle session',
      build: () {
        when(
          () => mockLocalDataSource.loadMessages(any()),
        ).thenReturn([tUserMessage, tAssistantMessage]);
        when(
          () => mockLocalDataSource.loadSessionId(any()),
        ).thenReturn(tSessionId);
        when(() => mockRepository.clearSession(any())).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.clearHistory(any()),
        ).thenAnswer((_) async {});
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
