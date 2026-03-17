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

Color _colorForCategory(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('info') || lower.contains('tech')) return AppColors.primary;
  if (lower.contains('math')) return AppColors.categoryTechnology;
  if (lower.contains('scien')) return AppColors.categoryScience;
  if (lower.contains('orient')) return AppColors.categoryEconomics;
  if (lower.contains('hack')) return AppColors.secondary;
  return AppColors.primary;
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

// ─── Full Card — Pattern _TestCard ────────────────────────────────────────────

class _FullCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _FullCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(course.category);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + 3,
                top: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: icon + duration badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconForCategory(course.category),
                          color: color,
                          size: 22,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${course.durationMinutes} min',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom: title + category + progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.category,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${course.pointsReward}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: course.isEnrolled && course.progressPct != null
                              ? (course.progressPct! / 100).clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 3,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Left color accent strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
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

// ─── Compact Card — Pattern _SchoolCard ───────────────────────────────────────

class _CompactCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _CompactCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(course.category);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0F5FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.08),
                          color.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForCategory(course.category),
                      color: color,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${course.pointsReward} pts',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Iconsax.timer_1,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.durationMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (course.isEnrolled && course.progressPct != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${course.progressPct}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
