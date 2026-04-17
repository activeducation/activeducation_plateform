import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import 'section_header.dart';
import 'school_card.dart';

class SchoolsSection extends StatelessWidget {
  final VoidCallback onViewAll;
  const SchoolsSection({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final schools = [
      SchoolPreview(
        name: 'Université de Lomé',
        shortName: 'UL',
        location: 'Lomé, Togo',
        programs: '120+ filières',
        color: AppColors.primary,
      ),
      SchoolPreview(
        name: 'UK (Kara)',
        shortName: 'UK',
        location: 'Kara, Togo',
        programs: '85+ filières',
        color: AppColors.categoryTechnology,
      ),
      SchoolPreview(
        name: 'ESIBA',
        shortName: 'ES',
        location: 'Lomé, Togo',
        programs: '25+ filières',
        color: AppColors.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Établissements',
          accentColor: AppColors.success,
          actionLabel: 'Annuaire',
          onAction: onViewAll,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal,
            ),
            itemCount: schools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                SchoolCard(school: schools[index], onTap: onViewAll),
          ),
        ),
      ],
    );
  }
}
