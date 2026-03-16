import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/entities/course.dart';

enum CourseCardMode { compact, full }

class CourseCard extends StatelessWidget {
  final Course course;
  final CourseCardMode mode;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.mode = CourseCardMode.full,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == CourseCardMode.compact) {
      return _CompactCourseCard(course: course, onTap: onTap);
    }
    return _FullCourseCard(course: course, onTap: onTap);
  }
}

// ─── Full Card (for grid) ──────────────────────────────────────────────────────

class _FullCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _FullCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailWidget(
                thumbnailUrl: course.thumbnailUrl,
                category: course.category,
                height: 110,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTypography.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          _DifficultyChip(difficulty: course.difficulty),
                          const Spacer(),
                          Icon(
                            Icons.star_rounded,
                            size: AppSpacing.iconXs,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${course.pointsReward} pts',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: AppSpacing.iconXs,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${course.durationMinutes} min',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                      if (course.isEnrolled && course.progressPct != null) ...[
                        const Spacer(),
                        _ProgressBar(progressPct: course.progressPct!),
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

// ─── Compact Card (for horizontal list / my courses) ─────────────────────────

class _CompactCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const _CompactCourseCard({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailWidget(
                thumbnailUrl: course.thumbnailUrl,
                category: course.category,
                height: 90,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: AppTypography.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (course.isEnrolled && course.progressPct != null)
                      _ProgressBar(progressPct: course.progressPct!),
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _ThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final String category;
  final double height;
  final BorderRadius borderRadius;

  const _ThumbnailWidget({
    required this.thumbnailUrl,
    required this.category,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => _GradientPlaceholder(
            category: category,
            height: height,
            borderRadius: borderRadius,
          ),
          errorWidget: (context, url, error) => _GradientPlaceholder(
            category: category,
            height: height,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    return _GradientPlaceholder(
      category: category,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final String category;
  final double height;
  final BorderRadius borderRadius;

  const _GradientPlaceholder({
    required this.category,
    required this.height,
    required this.borderRadius,
  });

  LinearGradient _gradientForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('info') || lower.contains('tech')) {
      return const LinearGradient(
        colors: [Color(0xFF1060CF), Color(0xFF3B49DF)],
      );
    } else if (lower.contains('math')) {
      return const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
      );
    } else if (lower.contains('scien')) {
      return const LinearGradient(
        colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
      );
    } else if (lower.contains('orient')) {
      return const LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
      );
    } else if (lower.contains('hack')) {
      return const LinearGradient(
        colors: [Color(0xFFF2A423), Color(0xFFD98E1B)],
      );
    }
    return AppColors.primaryGradient;
  }

  IconData _iconForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('info') || lower.contains('tech')) {
      return Icons.computer_rounded;
    } else if (lower.contains('math')) {
      return Icons.calculate_rounded;
    } else if (lower.contains('scien')) {
      return Icons.science_rounded;
    } else if (lower.contains('orient')) {
      return Icons.explore_rounded;
    } else if (lower.contains('hack')) {
      return Icons.code_rounded;
    }
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _gradientForCategory(category),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          _iconForCategory(category),
          size: height * 0.4,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final CourseDifficulty difficulty;

  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      CourseDifficulty.debutant => ('Débutant', AppColors.success),
      CourseDifficulty.intermediaire => ('Intermédiaire', AppColors.warning),
      CourseDifficulty.avance => ('Avancé', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int progressPct;

  const _ProgressBar({required this.progressPct});

  @override
  Widget build(BuildContext context) {
    final progress = (progressPct / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: AppTypography.labelSmall,
            ),
            Text(
              '$progressPct%',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: AppSpacing.progressBarHeight,
          ),
        ),
      ],
    );
  }
}
