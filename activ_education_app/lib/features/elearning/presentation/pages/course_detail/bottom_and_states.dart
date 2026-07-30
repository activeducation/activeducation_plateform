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

      final allCompleted = nextLessonId == null;

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
            Expanded(
              child: GradientButton(
                text: 'Continuer',
                icon: Iconsax.play,
                showArrow: true,
                onPressed: () => context.push('/elearning/lesson/$nextLessonId'),
              ),
            ),
          ],
          if (allCompleted) ...[
            Expanded(
              child: GradientButton(
                text: 'Certificat',
                icon: Iconsax.document_text,
                showArrow: false,
                onPressed: () => _downloadCertificate(context, course.id, color),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.push('/elearning/course/${course.id}/exam'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Iconsax.medal_star, size: 20),
            ),
          ],
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

void _downloadCertificate(BuildContext context, String courseId, Color color) async {
  try {
    final dio = getIt<Dio>(instanceName: 'apiClient');
    final res = await dio.get(
      ApiEndpoints.elearningCourseExam(courseId).replaceAll('/exam', '/certificate'),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data as List<int>;

    // Audit #7 (2026-07-30) : avant ce fix, on affichait un snackbar de
    // succes sans rien faire (les bytes etaient perdus). On ouvre
    // maintenant le PDF reellement cote navigateur via une Data URL
    // base64, ce qui marche sans nouvelle dep (url_launcher deja
    // present). Pour mobile/desktop (non servis en prod), on affiche
    // un message d'info.
    if (!kIsWeb) {
      if (context.mounted) {
        AppSnackbar.info(context,
            'Certificat disponible sur le web — ouvrez la version navigateur.');
      }
      return;
    }

    final b64 = base64Encode(bytes);
    final dataUrl = 'data:application/pdf;base64,$b64';
    final uri = Uri.parse(dataUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (context.mounted) {
      if (opened) {
        AppSnackbar.success(context, 'Certificat ouvert dans un nouvel onglet.');
      } else {
        AppSnackbar.error(context,
            "Impossible d'ouvrir le certificat. Réessayez ou contactez le support.");
      }
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
      if (context.mounted) {
        AppSnackbar.info(context, 'Terminez toutes les leçons pour obtenir votre certificat.');
      }
    } else if (e.response?.statusCode == 501) {
      if (context.mounted) {
        AppSnackbar.info(context, 'Génération de certificat temporairement indisponible.');
      }
    } else {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erreur lors du téléchargement.');
      }
    }
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.error(context, 'Erreur lors du téléchargement.');
    }
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
        Container(height: 200, color: AppColors.darkBg2),
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
