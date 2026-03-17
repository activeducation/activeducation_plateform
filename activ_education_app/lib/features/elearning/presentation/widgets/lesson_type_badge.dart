import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          config.icon,
          size: 14,
          color: config.color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 13,
            color: config.color,
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.color,
              letterSpacing: 0.1,
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
          icon: Iconsax.play_circle,
          label: 'Vidéo',
        );
      case LessonType.article:
        return _BadgeConfig(
          color: AppColors.success,
          icon: Iconsax.document_text,
          label: 'Article',
        );
      case LessonType.quiz:
        return _BadgeConfig(
          color: AppColors.secondary,
          icon: Iconsax.message_question,
          label: 'Quiz',
        );
      case LessonType.pdf:
        return _BadgeConfig(
          color: AppColors.error,
          icon: Iconsax.document,
          label: 'PDF',
        );
      case LessonType.challenge:
        return _BadgeConfig(
          color: AppColors.categoryTechnology,
          icon: Iconsax.cup,
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
