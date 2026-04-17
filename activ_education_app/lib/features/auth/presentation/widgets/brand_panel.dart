import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import 'stat_pill.dart';

class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ActivEducation',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Plateforme d\'orientation gamifiée',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Grand headline
          Text(
            'Découvrez\nvotre voie.',
            style: AppTypography.heroDisplay.copyWith(
              fontSize: 44,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'La première plateforme d\'orientation scolaire\net professionnelle gamifiée.',
            style: AppTypography.heroSubtitle.copyWith(
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 40),

          // Stats
          Row(
            children: const [
              StatPill(value: '500+', label: 'Métiers'),
              SizedBox(width: 14),
              StatPill(value: '50+', label: 'Mentors'),
              SizedBox(width: 14),
              StatPill(value: '100%', label: 'Gratuit'),
            ],
          ),

          const Spacer(),

          // Footer
          Text(
            '© 2026 ActivEducation',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
