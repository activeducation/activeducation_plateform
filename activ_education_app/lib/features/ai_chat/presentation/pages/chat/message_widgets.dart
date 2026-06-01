// Partie de chat_page.dart (refacto : page de 758 lignes decoupee
// en parts pour la lisibilite). Widgets prives partages, imports
// herites de la librairie principale.
//
// Bulle de message, avatar AIDA, indicateur de frappe.
part of '../chat_page.dart';

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
              builder: (_, _) {
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
