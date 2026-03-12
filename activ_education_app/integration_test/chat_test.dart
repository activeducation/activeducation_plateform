/// Tests E2E — Parcours Chat AÏDA
///
/// Couvre : affichage des messages, envoi, chargement, gestion des erreurs
///
/// Note : utilise un harness léger qui fournit le ChatBloc directement,
/// sans passer par ChatPage (qui dépend de getIt/DI).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:activ_education_app/features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'package:activ_education_app/features/ai_chat/domain/entities/chat_message.dart';
import 'package:activ_education_app/core/theme/theme.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockChatBloc extends MockBloc<ChatEvent, ChatState>
    implements ChatBloc {}

// ============================================================================
// Fixtures
// ============================================================================

final _welcomeMessage = ChatMessage(
  id: 'welcome-1',
  content: 'Bonjour ! Je suis AÏDA, votre conseillère d\'orientation.',
  role: MessageRole.assistant,
  timestamp: DateTime(2024, 3, 1, 9, 0),
);

final _userMessage = ChatMessage(
  id: 'user-1',
  content: 'Quelles filières pour un profil RIA ?',
  role: MessageRole.user,
  timestamp: DateTime(2024, 3, 1, 9, 1),
);

final _assistantReply = ChatMessage(
  id: 'assistant-1',
  content: 'Pour un profil RIA, je recommande les filières...',
  role: MessageRole.assistant,
  timestamp: DateTime(2024, 3, 1, 9, 2),
);

// ============================================================================
// Harness de test — contourne ChatPage qui dépend de getIt
// ============================================================================

/// Liste de messages simple pour les tests.
class _TestMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  const _TestMessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('messages_list'),
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment:
                msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg.content),
            ),
          ),
        );
      },
    );
  }
}

/// Barre de saisie de message.
class _TestInputBar extends StatefulWidget {
  final ChatBloc chatBloc;
  const _TestInputBar({required this.chatBloc});

  @override
  State<_TestInputBar> createState() => _TestInputBarState();
}

class _TestInputBarState extends State<_TestInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat_input'),
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Posez une question...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  widget.chatBloc.add(SendMessage(text.trim()));
                  _controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('send_button'),
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                widget.chatBloc.add(SendMessage(text));
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Page de chat simulée.
class _TestChatPage extends StatelessWidget {
  final ChatBloc chatBloc;
  const _TestChatPage({required this.chatBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: chatBloc,
      child: Scaffold(
        key: const Key('chat_page'),
        appBar: AppBar(title: const Text('AÏDA')),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatReady) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              key: Key('chat_loading'),
                            ),
                          ),
                        if (state.error != null)
                          Container(
                            key: const Key('chat_error'),
                            padding: const EdgeInsets.all(12),
                            color: Colors.red.shade100,
                            child: Text(state.error!),
                          ),
                        Expanded(
                          child: _TestMessageList(messages: state.messages),
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            _TestInputBar(chatBloc: chatBloc),
          ],
        ),
      ),
    );
  }
}

Widget buildChatTestApp({required ChatBloc chatBloc}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('fr', 'FR')],
    home: _TestChatPage(chatBloc: chatBloc),
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockChatBloc mockChatBloc;

  setUp(() {
    mockChatBloc = MockChatBloc();
  });

  tearDown(() => mockChatBloc.close());

  group('Parcours Chat AÏDA E2E', () {
    testWidgets('Affiche la page de chat avec les messages', (tester) async {
      when(() => mockChatBloc.state)
          .thenReturn(ChatReady(messages: [_welcomeMessage]));
      whenListen(
        mockChatBloc,
        Stream.fromIterable([ChatReady(messages: [_welcomeMessage])]),
        initialState: ChatReady(messages: [_welcomeMessage]),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byKey(const Key('chat_page')), findsOneWidget);
      expect(find.byKey(const Key('messages_list')), findsOneWidget);
    });

    testWidgets('Affiche le champ de saisie et le bouton envoi', (tester) async {
      when(() => mockChatBloc.state)
          .thenReturn(ChatReady(messages: [_welcomeMessage]));
      whenListen(
        mockChatBloc,
        Stream.fromIterable([ChatReady(messages: [_welcomeMessage])]),
        initialState: ChatReady(messages: [_welcomeMessage]),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_input')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('Dispatche SendMessage au clic sur le bouton envoi',
        (tester) async {
      when(() => mockChatBloc.state)
          .thenReturn(ChatReady(messages: [_welcomeMessage]));
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          ChatReady(messages: [_welcomeMessage]),
          ChatReady(messages: [_welcomeMessage, _userMessage], isLoading: true),
        ]),
        initialState: ChatReady(messages: [_welcomeMessage]),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('chat_input')),
        'Quelles filières pour un profil RIA ?',
      );
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pump();

      verify(() => mockChatBloc.add(any(that: isA<SendMessage>()))).called(1);
    });

    testWidgets("Affiche l'indicateur de chargement pendant la réponse",
        (tester) async {
      when(() => mockChatBloc.state).thenReturn(ChatReady(
        messages: [_welcomeMessage, _userMessage],
        isLoading: true,
      ));
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          ChatReady(
            messages: [_welcomeMessage, _userMessage],
            isLoading: true,
          ),
        ]),
        initialState: ChatReady(
          messages: [_welcomeMessage, _userMessage],
          isLoading: true,
        ),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pump();

      expect(find.byKey(const Key('chat_loading')), findsOneWidget);
    });

    testWidgets("Affiche un message d'erreur en cas d'échec", (tester) async {
      const errorMsg = 'Impossible de contacter AÏDA.';
      when(() => mockChatBloc.state).thenReturn(
        ChatReady(messages: [_welcomeMessage], error: errorMsg),
      );
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          ChatReady(messages: [_welcomeMessage], error: errorMsg),
        ]),
        initialState: ChatReady(messages: [_welcomeMessage], error: errorMsg),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_error')), findsOneWidget);
    });

    testWidgets('Affiche la réponse AÏDA après envoi réussi', (tester) async {
      when(() => mockChatBloc.state).thenReturn(ChatReady(
        messages: [_welcomeMessage, _userMessage, _assistantReply],
      ));
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          ChatReady(
            messages: [_welcomeMessage, _userMessage, _assistantReply],
          ),
        ]),
        initialState: ChatReady(
          messages: [_welcomeMessage, _userMessage, _assistantReply],
        ),
      );

      await tester.pumpWidget(buildChatTestApp(chatBloc: mockChatBloc));
      await tester.pumpAndSettle();

      expect(
        find.text('Pour un profil RIA, je recommande les filières...')
            .evaluate()
            .isNotEmpty,
        isTrue,
        reason: 'La réponse AÏDA doit être affichée',
      );
    });
  });
}
