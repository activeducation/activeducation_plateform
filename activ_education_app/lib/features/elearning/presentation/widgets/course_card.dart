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
      if (lower.contains('info') || lower.contains('tech')) {
        return AppColors.primary;
      }
      if (lower.contains('math')) return AppColors.categoryTechnology;
      if (lower.contains('scien')) return AppColors.categoryScience;
      if (lower.contains('orient')) return AppColors.categoryEconomics;
      if (lower.contains('hack')) return AppColors.secondary;
      return AppColors.categoryScience;
  }
}

IconData iconForCategory(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('info') || lower.contains('tech')) {
    return Iconsax.monitor;
  }
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
    final difficultyColor = _colorForDifficulty(course.difficulty);
    final hasProgress = course.isEnrolled && course.progressPct != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasProgress
                  ? color.withValues(alpha: 0.2)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header zone avec gradient ──
              Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.08),
                      color.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône catégorie
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        iconForCategory(course.category),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    // Badge difficulté
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _labelForDifficulty(course.difficulty),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: difficultyColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Contenu ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
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
                      const SizedBox(height: 4),
                      // Description
                      Expanded(
                        child: Text(
                          course.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Méta : durée + points
                      Row(
                        children: [
                          Icon(Iconsax.clock,
                              size: 13, color: AppColors.textTertiary),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.medal_star5,
                                    size: 11,
                                    color: AppColors.secondaryDark),
                                const SizedBox(width: 3),
                                Text(
                                  '${course.pointsReward}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryDark,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Barre de progression si inscrit
                      if (hasProgress) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (course.progressPct! / 100)
                                      .clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor:
                                      color.withValues(alpha: 0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${course.progressPct}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasProgress
                  ? color.withValues(alpha: 0.2)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini header teinté
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + points
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconForCategory(course.category),
                              color: color,
                              size: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${course.pointsReward} pts',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Titre
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
                      // Durée + progression
                      if (hasProgress) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (course.progressPct! / 100)
                                      .clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor:
                                      color.withValues(alpha: 0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${course.progressPct}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          children: [
                            Icon(Iconsax.clock,
                                size: 12, color: AppColors.textTertiary),
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
