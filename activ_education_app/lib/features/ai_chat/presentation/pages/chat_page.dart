import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/orientation/domain/entities/test_result.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';

// ---------------------------------------------------------------------------
// Arguments de navigation
// ---------------------------------------------------------------------------

class ChatPageArgs {
  final TestResult? orientationResult;

  const ChatPageArgs({this.orientationResult});

  Map<String, dynamic>? toContextMap() {
    final r = orientationResult;
    if (r == null) return null;

    final interp = r.interpretation;
    return {
      if (interp?.profileCode != null) 'profile_code': interp!.profileCode,
      if (r.dominantTraits.isNotEmpty) 'dominant_traits': r.dominantTraits,
      if (interp?.profileSummary.isNotEmpty == true)
        'profile_summary': interp!.profileSummary,
      if (interp?.strengths.isNotEmpty == true)
        'strengths': interp!.strengths,
      if (r.recommendations.isNotEmpty)
        'recommendations': r.recommendations
            .take(5)
            .map((c) => {'name': c.name, 'sector': c.sector})
            .toList(),
      if (interp?.recommendedSectors.isNotEmpty == true)
        'recommended_sectors': interp!.recommendedSectors,
    };
  }
}

// ---------------------------------------------------------------------------
// Page principale
// ---------------------------------------------------------------------------

class ChatPage extends StatefulWidget {
  final ChatPageArgs args;

  const ChatPage({super.key, required this.args});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final tokenStorage = getIt<TokenStorage>();
    final hasTokens = await tokenStorage.hasValidTokens();
    if (hasTokens) {
      _userId = await tokenStorage.getUserId();
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = hasTokens;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isAuthenticated) {
      return _AuthRequiredScreen();
    }

    final localStorage = ChatLocalDataSource(getIt<SharedPreferences>());

    return BlocProvider(
      create: (_) => ChatBloc(
        ChatRepositoryImpl(
          ChatRemoteDataSourceImpl(getIt<Dio>(instanceName: 'apiClient')),
        ),
        localStorage,
        orientationContext: widget.args.toContextMap(),
      )..add(LoadChatHistory(_userId ?? 'anonymous')),
      child: _ChatView(hasContext: widget.args.orientationResult != null),
    );
  }
}

// ---------------------------------------------------------------------------
// Ecran affiché quand l'utilisateur n'est pas connecté
// ---------------------------------------------------------------------------

class _AuthRequiredScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AÏDA',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connecte-toi pour discuter avec AÏDA',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AÏDA est ta conseillère d\'orientation personnelle. '
                'Crée un compte ou connecte-toi pour commencer.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Se connecter',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(
                  'Pas encore de compte ? S\'inscrire',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vue interne
// ---------------------------------------------------------------------------

class _ChatView extends StatefulWidget {
  final bool hasContext;
  const _ChatView({required this.hasContext});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Questions de démarrage rapide
  static const _suggestions = [
    'Quelles filières me correspondent ?',
    'Quels métiers pour mon profil ?',
    'Quelles écoles au Togo ?',
    'Quel salaire attendre ?',
    'Comment choisir ma série ?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    context.read<ChatBloc>().add(SendMessage(msg));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatReady) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatReady) {
                  return _buildMessageList(state);
                }
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textSecondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AÏDA',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Conseillère d\'orientation',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.success,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, size: 22),
          color: AppColors.textSecondary,
          tooltip: 'Nouvelle conversation',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Nouvelle conversation'),
                content: const Text(
                  'Voulez-vous effacer cette conversation et en commencer une nouvelle ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context
                          .read<ChatBloc>()
                          .add(ClearChatSession());
                    },
                    child: const Text('Recommencer'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildMessageList(ChatReady state) {
    final showSuggestions =
        state.messages.length == 1 && !state.isLoading;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length +
          (state.isLoading ? 1 : 0) +
          (showSuggestions ? 1 : 0),
      itemBuilder: (context, index) {
        // Suggestions rapides sous le premier message AÏDA
        if (showSuggestions && index == 1) {
          return _buildSuggestions();
        }

        final msgIndex = showSuggestions && index > 1 ? index - 1 : index;

        if (state.isLoading && msgIndex == state.messages.length) {
          return _TypingIndicator();
        }

        if (msgIndex >= state.messages.length) return const SizedBox.shrink();

        final message = state.messages[msgIndex];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: _suggestions.map((s) {
          return ActionChip(
            label: Text(
              s,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
            backgroundColor: AppColors.primarySurface,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onPressed: () => _sendMessage(s),
          );
        }).toList(),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Posez une question à AÏDA...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isLoading =
                    state is ChatReady && state.isLoading;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLoading
                        ? const LinearGradient(
                            colors: [AppColors.textTertiary, AppColors.border])
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: isLoading
                          ? null
                          : () => _sendMessage(_controller.text),
                      child: Icon(
                        isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulle de message
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _AidaAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: AppColors.cardShadow,
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
              ),
              child: _buildContent(isUser),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildContent(bool isUser) {
    // Rendu Markdown basique : **gras**
    final text = message.content;
    if (!text.contains('**')) {
      return Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: isUser ? Colors.white : AppColors.textPrimary,
          height: 1.5,
        ),
      );
    }

    // Parse **bold** inline
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(
          color: isUser ? Colors.white : AppColors.textPrimary,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar AÏDA
// ---------------------------------------------------------------------------

class _AidaAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Indicateur de frappe (typing…)
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AidaAvatar(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: AppColors.cardShadow,
            ),
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final offset = ((_animCtrl.value - delay) % 1.0);
                    final opacity =
                        (offset < 0.5 ? offset * 2 : (1.0 - offset) * 2)
                            .clamp(0.3, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3.5),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
