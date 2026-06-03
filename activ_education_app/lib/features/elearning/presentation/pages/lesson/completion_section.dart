// Partie de lesson_page.dart (refacto : page de 1231 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Bouton de completion, vue terminee, quiz, painter de fond.
part of '../lesson_page.dart';


class _SimpleMarkdown extends StatelessWidget {
  final String content;

  const _SimpleMarkdown({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            line.substring(2),
            style: AppTypography.headlineSmall.copyWith(
              letterSpacing: -0.3,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: Text(
            line.substring(3),
            style: AppTypography.titleLarge.copyWith(
              letterSpacing: -0.2,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 2),
          child: Text(
            line.substring(4),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _InlineText(text: line.substring(2)),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _InlineText(text: line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _InlineText extends StatelessWidget {
  final String text;

  const _InlineText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: AppTypography.bodyMedium.copyWith(height: 1.6),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: AppTypography.bodyMedium.copyWith(height: 1.6),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ─── Bottom Complete Button ───────────────────────────────────────────────────

class _BottomCompleteButton extends StatelessWidget {
  final LessonType lessonType;
  final bool canComplete;
  final bool isCompleting;
  final VoidCallback onComplete;

  const _BottomCompleteButton({
    required this.lessonType,
    required this.canComplete,
    required this.isCompleting,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isQuiz = lessonType == LessonType.quiz;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: isCompleting
              ? Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : GradientButton(
                  text: isQuiz && !canComplete
                      ? 'Terminez le quiz d\'abord'
                      : 'Valider cette leçon',
                  icon: isQuiz
                      ? Iconsax.tick_circle
                      : Iconsax.verify,
                  onPressed: canComplete ? onComplete : null,
                  showArrow: false,
                ),
        ),
      ),
    );
  }
}

// ─── Lesson Completed ─────────────────────────────────────────────────────────

class _LessonCompletedView extends StatelessWidget {
  final int pointsEarned;
  final int? courseProgressPct;
  final VoidCallback onBack;

  const _LessonCompletedView({
    required this.pointsEarned,
    this.courseProgressPct,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.cup,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Leçon validée !',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Points card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.medal_star5,
                            color: AppColors.secondary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '+$pointsEarned points',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (courseProgressPct != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression du cours',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$courseProgressPct%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (courseProgressPct! / 100).clamp(0.0, 1.0),
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              GradientButton(
                text: 'Retour au cours',
                icon: Iconsax.arrow_left_2,
                showArrow: false,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quiz Completed Message ───────────────────────────────────────────────────

class _QuizCompletedMessage extends StatelessWidget {
  final int score;

  const _QuizCompletedMessage({required this.score});

  @override
  Widget build(BuildContext context) {
    final passed = score >= 60;
    final resultColor = passed ? AppColors.success : AppColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Iconsax.cup : Iconsax.refresh,
                size: 36,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz terminé',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score : $score%',
              style: AppTypography.titleMedium.copyWith(
                color: resultColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Validez la leçon pour enregistrer votre résultat.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot Pattern Painter (for video bg) ───────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
