import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class OnboardingInterestsPage extends StatefulWidget {
  const OnboardingInterestsPage({super.key});

  @override
  State<OnboardingInterestsPage> createState() => _OnboardingInterestsPageState();
}

class _OnboardingInterestsPageState extends State<OnboardingInterestsPage> {
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _interests = [
    {
      'id': 'tech',
      'icon': Icons.computer_rounded,
      'title': 'Technologie',
      'subtitle': 'Informatique, code, robotique',
    },
    {
      'id': 'science',
      'icon': Icons.science_rounded,
      'title': 'Sciences',
      'subtitle': 'Physique, chimie, biologie',
    },
    {
      'id': 'business',
      'icon': Icons.business_center_rounded,
      'title': 'Business',
      'subtitle': 'Commerce, entrepreneuriat',
    },
    {
      'id': 'health',
      'icon': Icons.favorite_rounded,
      'title': 'Santé',
      'subtitle': 'Médecine, soins, bien-être',
    },
    {
      'id': 'arts',
      'icon': Icons.palette_rounded,
      'title': 'Arts & Design',
      'subtitle': 'Créativité, design, médias',
    },
    {
      'id': 'education',
      'icon': Icons.school_rounded,
      'title': 'Éducation',
      'subtitle': 'Enseignement, formation',
    },
    {
      'id': 'sports',
      'icon': Icons.sports_soccer_rounded,
      'title': 'Sports',
      'subtitle': 'Activité physique, compétition',
    },
    {
      'id': 'languages',
      'icon': Icons.translate_rounded,
      'title': 'Langues',
      'subtitle': 'Communication multilingue',
    },
    {
      'id': 'engineering',
      'icon': Icons.precision_manufacturing_rounded,
      'title': 'Ingénierie',
      'subtitle': 'Construction, mécanique',
    },
    {
      'id': 'agriculture',
      'icon': Icons.grass_rounded,
      'title': 'Agriculture',
      'subtitle': 'Agro, environnement',
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
                      'Choisis ce qui t\'intéresse\n(plusieurs choix possibles)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInterestGrid(),
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
            'Tes intérêts',
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
            _buildProgressDot(2, false),
            _buildProgressDot(3, false),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Étape 2 sur 4',
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

  Widget _buildInterestGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _interests.map((interest) {
        final isSelected = _selectedInterests.contains(interest['id']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest['id']);
              } else {
                _selectedInterests.add(interest['id']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: cardWidth,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    interest['icon'] as IconData,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  interest['title'] as String,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  interest['subtitle'] as String,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCTA(BuildContext context) {
    final canContinue = _selectedInterests.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_selectedInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_selectedInterests.length} intérêt${_selectedInterests.length > 1 ? 's' : ''} sélectionné${_selectedInterests.length > 1 ? 's' : ''}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue
                  ? () => context.push('/onboarding/goals')
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
                'Continuer',
                style: AppTypography.buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
