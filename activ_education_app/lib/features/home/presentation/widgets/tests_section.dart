import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../orientation/domain/entities/orientation_test.dart';
import 'section_header.dart';
import 'test_card.dart';

class TestsSection extends StatelessWidget {
  final Future<List<OrientationTest>> testsFuture;
  final void Function(OrientationTest) onTestTap;
  final VoidCallback onViewAll;

  const TestsSection({
    super.key,
    required this.testsFuture,
    required this.onTestTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Explore tes talents',
          accentColor: AppColors.primary,
          actionLabel: 'Tout voir',
          onAction: onViewAll,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: FutureBuilder<List<OrientationTest>>(
            future: testsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              final tests = snapshot.data ?? <OrientationTest>[];
              if (tests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Aucun test disponible pour le moment.',
                    style: AppTypography.bodyMedium,
                  ),
                );
              }

              final cards = tests
                  .take(4)
                  .map(
                    (test) => TestCardData(
                      test: test,
                      title: test.name,
                      subtitle: _subtitleFromType(test.type),
                      icon: _iconFromType(test.type),
                      color: _colorFromType(test.type),
                      duration: '${test.durationMinutes} min',
                    ),
                  )
                  .toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => TestCard(
                  data: cards[index],
                  onTap: () => onTestTap(cards[index].test),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _subtitleFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return 'Intérêts professionnels';
      case TestType.personality:
        return 'Traits de caractère';
      case TestType.skills:
        return 'Points forts';
      case TestType.interests:
        return 'Tes priorités';
      case TestType.aptitude:
        return 'Aptitudes naturelles';
    }
  }

  IconData _iconFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return Iconsax.chart;
      case TestType.personality:
        return Iconsax.user;
      case TestType.skills:
        return Iconsax.medal_star;
      case TestType.interests:
        return Iconsax.heart;
      case TestType.aptitude:
        return Iconsax.flash;
    }
  }

  Color _colorFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return AppColors.primary;
      case TestType.personality:
        return AppColors.secondary;
      case TestType.skills:
        return AppColors.categoryTechnology;
      case TestType.interests:
        return AppColors.streakFire;
      case TestType.aptitude:
        return AppColors.categoryScience;
    }
  }
}
