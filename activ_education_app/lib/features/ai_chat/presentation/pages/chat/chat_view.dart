// Partie de chat_page.dart (refacto : page de 758 lignes decoupee
// en parts pour la lisibilite). Widgets prives partages, imports
// herites de la librairie principale.
//
// Vue interne du chat (liste messages, saisie, envoi).
part of '../chat_page.dart';


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
                    AppSnackbar.error(context, state.error!);
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
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context
                          .read<ChatBloc>()
                          .add(ClearChatSession());
                    },
                    child: Text(
                      'Recommencer',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

