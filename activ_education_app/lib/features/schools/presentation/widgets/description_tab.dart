import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/school_model.dart';
import 'stat_card.dart';

class DescriptionTab extends StatelessWidget {
  final SchoolDetail school;

  const DescriptionTab({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'A propos',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              school.description ?? 'Aucune description disponible.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chiffres cles
          Text(
            'Chiffres cles',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (school.foundingYear != null)
                Expanded(
                  child: StatCard(
                    icon: Iconsax.calendar,
                    label: 'Fondation',
                    value: '${school.foundingYear}',
                  ),
                ),
              if (school.studentCount != null)
                Expanded(
                  child: StatCard(
                    icon: Iconsax.people,
                    label: 'Etudiants',
                    value: _formatNumber(school.studentCount!),
                  ),
                ),
              Expanded(
                child: StatCard(
                  icon: Iconsax.book_1,
                  label: 'Filieres',
                  value: '${school.programs.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Domaines
          if (school.programsOffered.isNotEmpty) ...[
            Text(
              'Domaines de formation',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: school.programsOffered.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
