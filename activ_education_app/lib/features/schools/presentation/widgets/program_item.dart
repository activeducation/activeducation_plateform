import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/school_model.dart';

class ProgramItem extends StatelessWidget {
  final SchoolProgram program;

  const ProgramItem({super.key, required this.program});

  IconData get _icon {
    final name = program.name.toLowerCase();
    if (name.contains('info') ||
        name.contains('logiciel') ||
        name.contains('dev') ||
        name.contains('cyber') ||
        name.contains('cloud') ||
        name.contains('reseau'))
      return Iconsax.code;
    if (name.contains('droit') || name.contains('juridique'))
      return Iconsax.book;
    if (name.contains('sante') || name.contains('medecine'))
      return Iconsax.health;
    if (name.contains('genie civil') ||
        name.contains('btp') ||
        name.contains('electricite') ||
        name.contains('mecanique') ||
        name.contains('froid') ||
        name.contains('maintenance'))
      return Iconsax.cpu;
    if (name.contains('marketing') ||
        name.contains('commerce') ||
        name.contains('communication'))
      return Iconsax.chart;
    if (name.contains('finance') ||
        name.contains('comptabilite') ||
        name.contains('banque'))
      return Iconsax.money_2;
    if (name.contains('management') ||
        name.contains('gestion') ||
        name.contains('rh') ||
        name.contains('logistique'))
      return Iconsax.briefcase;
    if (name.contains('agro') || name.contains('environnement'))
      return Iconsax.tree;
    if (name.contains('lettres') || name.contains('economie'))
      return Iconsax.document;
    return Iconsax.book_1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (program.description != null)
                  Text(
                    program.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (program.durationYears != null)
                  Text(
                    '${program.levelLabel} - ${program.durationLabel}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
