import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/entities/course.dart';

// CourseCardMode conservé pour compatibilité avec le code existant
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

Color _colorForCategory(String category) {
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

IconData _iconForCategory(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('info') || lower.contains('tech')) return Icons.computer_rounded;
  if (lower.contains('math')) return Icons.calculate_rounded;
  if (lower.contains('scien')) return Icons.science_rounded;
  if (lower.contains('orient')) return Icons.explore_rounded;
  if (lower.contains('hack')) return Icons.code_rounded;
  return Icons.school_rounded;
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
    final color = _colorForCategory(course.category);
    final difficultyColor = _colorForDifficulty(course.difficulty);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône + badge difficulté
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconForCategory(course.category),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
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
                            letterSpacing: 0.2,
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
                      height: 1.3,
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
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Durée + points
                  Row(
                    children: [
                      Icon(Iconsax.timer_1,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        '${course.durationMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.star_rounded,
                          size: 12, color: AppColors.secondary),
                      const SizedBox(width: 3),
                      Text(
                        '${course.pointsReward} pts',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Barre de progression si inscrit
                  if (course.isEnrolled && course.progressPct != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (course.progressPct! / 100).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
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
                  ],
                ],
              ),
            ),

            // Bandelette colorée gauche
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ],
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
    final color = _colorForCategory(course.category);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône + badge points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForCategory(course.category),
                      color: color,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${course.pointsReward} pts',
                      style: const TextStyle(
                        fontSize: 11,
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
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Durée + progression
              Row(
                children: [
                  Icon(Iconsax.timer_1,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${course.durationMinutes} min',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (course.isEnrolled && course.progressPct != null) ...[
                    const Spacer(),
                    Text(
                      '${course.progressPct}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
