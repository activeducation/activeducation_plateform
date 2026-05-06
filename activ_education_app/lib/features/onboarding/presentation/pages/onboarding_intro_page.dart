import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildIllustration(),
                const Spacer(),
                _buildCTA(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenue sur',
          style: AppTypography.heroSubtitle.copyWith(
            color: AppColors.darkAccentAmber,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ActivEducation',
          style: AppTypography.heroDisplay.copyWith(
            fontSize: 36,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ton assistant d''orientation personnalisé.\nDécouvre les métiers qui te ressemblent.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.darkTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 56,
              color: AppColors.darkAccentAmber,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Icons.quiz_rounded,
            'Tests d\'orientation',
            'Découvrez votre profil RIASEC',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.school_rounded,
            'Écoles & Formations',
            'Explorez les opportunités locales',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.smart_toy_rounded,
            'AÏDA',
            'Conseillère IA disponible 24h/24',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.darkTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.push('/onboarding/profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
            child: Text(
              'Commencer',
              style: AppTypography.buttonText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'J\'ai déjà un compte',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}