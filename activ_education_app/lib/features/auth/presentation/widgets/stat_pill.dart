import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class StatPill extends StatelessWidget {
  final String value;
  final String label;
  const StatPill({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.statValueSmall.copyWith(
              color: AppColors.darkAccentAmber,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}
