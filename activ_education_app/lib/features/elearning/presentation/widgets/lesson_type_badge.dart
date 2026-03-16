import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/entities/course.dart';

class LessonTypeBadge extends StatelessWidget {
  final LessonType lessonType;
  final bool compact;

  const LessonTypeBadge({
    super.key,
    required this.lessonType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(lessonType);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxxs,
        ),
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        ),
        child: Icon(
          config.icon,
          size: AppSpacing.iconXs,
          color: config.color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: AppSpacing.iconXs,
            color: config.color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            config.label,
            style: AppTypography.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(LessonType type) {
    switch (type) {
      case LessonType.video:
        return _BadgeConfig(
          color: AppColors.info,
          icon: Icons.play_circle_outline_rounded,
          label: 'Vidéo',
        );
      case LessonType.article:
        return _BadgeConfig(
          color: AppColors.success,
          icon: Icons.article_outlined,
          label: 'Article',
        );
      case LessonType.quiz:
        return _BadgeConfig(
          color: AppColors.secondary,
          icon: Icons.quiz_outlined,
          label: 'Quiz',
        );
      case LessonType.pdf:
        return _BadgeConfig(
          color: AppColors.error,
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
        );
      case LessonType.challenge:
        return _BadgeConfig(
          color: const Color(0xFF7C3AED),
          icon: Icons.emoji_events_outlined,
          label: 'Challenge',
        );
    }
  }
}

class _BadgeConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _BadgeConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
