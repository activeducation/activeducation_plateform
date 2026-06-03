// Partie de course_detail_page.dart (refacto : page de 1454 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Bouton bas (inscription/continuer) + shimmer + erreur.
part of '../course_detail_page.dart';

// ─── Bottom Action ────────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final CourseDetail course;
  final bool isEnrolling;
  final Color color;
  final VoidCallback onEnroll;

  const _BottomAction({
    required this.course,
    required this.isEnrolling,
    required this.color,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: _buildButton(context)),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (isEnrolling) {
      return Container(
        height: 54,
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
      );
    }

    if (course.isEnrolled) {
      String? nextLessonId;
      outer:
      for (final module in course.modules) {
        if (module.isLocked) continue;
        for (final lesson in module.lessons) {
          if (lesson.status != LessonStatus.completed) {
            nextLessonId = lesson.id;
            break outer;
          }
        }
      }

      return Row(
        children: [
          if (nextLessonId != null && course.progressPct != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${course.progressPct}% complété',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ((course.progressPct ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GradientButton(
              text: nextLessonId != null ? 'Continuer' : 'Passer l\'examen',
              icon: nextLessonId != null ? Iconsax.play : Iconsax.medal_star,
              showArrow: nextLessonId != null,
              onPressed: nextLessonId != null
                  ? () => context.push('/elearning/lesson/$nextLessonId')
                  : () => context.push('/elearning/course/${course.id}/exam'),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'S\'inscrire gratuitement',
                icon: Iconsax.book_1,
                onPressed: onEnroll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.medal_star5,
                size: 13, color: AppColors.xpGoldDark),
            const SizedBox(width: 4),
            Text(
              'Gagnez +${course.pointsReward} XP en terminant ce cours',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.xpGoldDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark hero shimmer
        Container(height: 248, color: AppColors.darkBg2),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats strip
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    3,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Detail Error ─────────────────────────────────────────────────────────────

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _DetailError({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger le cours',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Réessayer',
                icon: Iconsax.refresh,
                showArrow: false,
                isSmall: true,
                width: 160,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
