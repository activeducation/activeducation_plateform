import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class OnboardingGoalsPage extends StatefulWidget {
  const OnboardingGoalsPage({super.key});

  @override
  State<OnboardingGoalsPage> createState() => _OnboardingGoalsPageState();
}

class _OnboardingGoalsPageState extends State<OnboardingGoalsPage> {
  String? _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'discover',
      'icon': Icons.explore_rounded,
      'title': 'Découvrir des métiers',
      'subtitle': 'Explorer différentes carrières',
    },
    {
      'id': 'orientation',
      'icon': Icons.route_rounded,
      'title': 'M\'orienter',
      'subtitle': 'Clarifier mon projet professionnel',
    },
    {
      'id': 'school',
      'icon': Icons.school_rounded,
      'title': 'Choisir une formation',
      'subtitle': 'Trouver la bonne école/filière',
    },
    {
      'id': 'skills',
      'icon': Icons.trending_up_rounded,
      'title': 'Développer mes compétences',
      'subtitle': 'Apprendre de nouvelles choses',
    },
    {
      'id': 'career',
      'icon': Icons.work_rounded,
      'title': 'Préparer ma carrière',
      'subtitle': 'Me préparer au monde du travail',
    },
    {
      'id': 'entrepreneur',
      'icon': Icons.rocket_launch_rounded,
      'title': 'Créer mon entreprise',
      'subtitle': 'Devenir entrepreneur',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Qu\'est-ce qui t\'intéresse le plus ?',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGoalList(),
                  ],
                ),
              ),
            ),
            _buildCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Tes objectifs',
            style: AppTypography.heroDisplay.copyWith(
              color: AppColors.textPrimary,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildProgressDot(0, true),
            _buildProgressDot(1, true),
            _buildProgressDot(2, true),
            _buildProgressDot(3, false),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Étape 3 sur 4',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDot(int index, bool active) {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.secondary : AppColors.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildGoalList() {
    return Column(
      children: _goals.map((goal) {
        final isSelected = _selectedGoal == goal['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = goal['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySurface
                  : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    goal['icon'] as IconData,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['title'] as String,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal['subtitle'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedGoal != null
              ? () => context.push('/onboarding/complete')
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.surfaceDim,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
          ),
          child: Text(
            'Terminer',
            style: AppTypography.buttonText,
          ),
        ),
      ),
    );
  }
}
