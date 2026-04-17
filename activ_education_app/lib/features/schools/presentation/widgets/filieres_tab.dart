import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/school_model.dart';
import 'program_item.dart';

class FilieresTab extends StatelessWidget {
  final SchoolDetail school;

  const FilieresTab({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    if (school.programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.book, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune filiere enregistree',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Grouper par niveau
    final grouped = <String, List<SchoolProgram>>{};
    for (final p in school.programs) {
      final key = p.levelLabel.isNotEmpty ? p.levelLabel : 'Autre';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    // Ordre de tri des niveaux
    const levelOrder = ['BTS', 'Licence', 'Master', 'Doctorat', 'Autre'];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = levelOrder.indexOf(a);
        final ib = levelOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final level in sortedKeys) ...[
            // Titre du groupe
            Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                level,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Programmes de ce niveau
            ...grouped[level]!.map((p) => ProgramItem(program: p)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
