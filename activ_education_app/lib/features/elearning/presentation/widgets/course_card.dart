import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/entities/course.dart';

enum CourseCardMode { compact, full }

class CourseCard extends StatelessWidget {
  final Course course;
  final CourseCardMode mode;
  final bool compact;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.mode = CourseCardMode.full,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact || mode == CourseCardMode.compact) {
      return _CompactCourseCard(course: course, onTap: onTap);
    }
    return _FullCourseCard(course: course, onTap: onTap);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color colorForCategory(String category) {
  switch (category.trim()) {
    case 'Informatique':
      return AppColors.primary;
    case 'Mathématiques':
      return AppColors.categoryTechnology;
    case 'Sciences':
      return AppColors.categoryScience;
    case 'Orientation':
      return AppColors.categoryEconomics;
    case 'Hackathons':
      return AppColors.secondary;
    default:
      final lower = category.toLowerCase();
      if (lower.contains('info') || lower.contains('tech')) return AppColors.primary;
      if (lower.contains('math')) return AppColors.categoryTechnology;
      if (lower.contains('scien')) return AppColors.categoryScience;
      if (lower.contains('orient')) return AppColors.categoryEconomics;
      if (lower.contains('hack')) return AppColors.secondary;
      return AppColors.categoryScience;
  }
}

IconData iconForCategory(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('info') || lower.contains('tech')) return Iconsax.monitor;
  if (lower.contains('math')) return Iconsax.math;
  if (lower.contains('scien')) return Iconsax.discover_1;
  if (lower.contains('orient')) return Iconsax.routing_2;
  if (lower.contains('hack')) return Iconsax.code;
  return Iconsax.book_1;
}

Color _colorForDifficulty(CourseDifficulty difficulty) {
  switch (difficulty) {
    case CourseDifficulty.debutant:
      return AppColors.success;
    case CourseDifficulty.intermediaire:
      return AppColors.secondary;
    case CourseDifficulty.avance:
      return AppColors.error;
  }
}

String _labelForDifficulty(CourseDifficulty difficulty) {
  switch (difficulty) {
    case CourseDifficulty.debutant:
      return 'Débutant';
    case CourseDifficulty.intermediaire:
      return 'Intermédiaire';
    case CourseDifficulty.avance:
      return 'Avancé';
  }
}

// ─── Full Card ────────────────────────────────────────────────────────────────

class _FullCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _FullCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(course.category);
    final diffColor = _colorForDifficulty(course.difficulty);
    final diffLabel = _labelForDifficulty(course.difficulty);
    final hasProgress = course.isEnrolled && course.progressPct != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasProgress ? color.withValues(alpha: 0.22) : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasProgress
                    ? color.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.055),
                blurRadius: hasProgress ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image de presentation (remplit l'espace dispo, plus de vide) ──
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CourseCover(course: course, color: color),

                    // Badge difficulte (haut droite)
                    Positioned(
                      top: 11,
                      right: 11,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          diffLabel,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // Badge XP (bas gauche)
                    Positioned(
                      bottom: 11,
                      left: 11,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.xpGold,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.xpGold.withValues(alpha: 0.55),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.medal_star5,
                                size: 11, color: AppColors.textOnAccent),
                            const SizedBox(width: 3),
                            Text(
                              '+${course.pointsReward} XP',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textOnAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Contenu compact (taille intrinseque, pas d'etirement) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    if (hasProgress)
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (course.progressPct! / 100)
                                    .clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: color.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${course.progressPct}%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Iconsax.clock,
                              size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${course.durationMinutes} min',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: diffColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diffLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: diffColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Couverture du cours : affiche [course.thumbnailUrl] si disponible, sinon un
/// degrade colore par categorie avec une grande icone. Un voile sombre en bas
/// garantit la lisibilite des badges (difficulte / XP).
class _CourseCover extends StatelessWidget {
  final Course course;
  final Color color;

  const _CourseCover({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    final hasThumb =
        course.thumbnailUrl != null && course.thumbnailUrl!.trim().isNotEmpty;

    final fallback = _GradientCover(color: color, course: course);

    final Widget background = hasThumb
        ? Image.network(
            course.thumbnailUrl!.trim(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : fallback,
          )
        : fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        // Voile degrade en bas pour lisibilite des badges sur les images.
        if (hasThumb)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.40),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
      ],
    );
  }
}

/// Degrade colore + grande icone de categorie (placeholder quand pas d'image).
class _GradientCover extends StatelessWidget {
  final Color color;
  final Course course;

  const _GradientCover({required this.color, required this.course});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.68)],
        ),
      ),
      child: Center(
        child: Icon(
          iconForCategory(course.category),
          color: Colors.white.withValues(alpha: 0.92),
          size: 56,
        ),
      ),
    );
  }
}

// ─── Compact Card ─────────────────────────────────────────────────────────────

class _CompactCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _CompactCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(course.category);
    final hasProgress = course.isEnrolled && course.progressPct != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              iconForCategory(course.category),
                              color: color,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.xpGoldSurface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '+${course.pointsReward} XP',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.xpGoldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (hasProgress) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (course.progressPct! / 100).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${course.progressPct}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          children: [
                            Icon(Iconsax.clock, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${course.durationMinutes} min',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
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
