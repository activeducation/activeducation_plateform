import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Page de profil utilisateur
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mon Profil',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String fullName = 'Utilisateur';
            String email = '';
            String initials = 'U';

            if (state is AuthAuthenticated) {
              fullName = state.user.fullName;
              email = state.user.email;
              initials = state.user.initials;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Banner gradient + avatar
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 130,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryIndigo],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        // Motif décoratif en filigrane
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              bottom: -10,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: -48,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: AppColors.crossBrandShadow,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // Nom + email
                  Text(
                    fullName,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePaddingHorizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Accès rapide
                        Text(
                          'Accès rapide',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildQuickAccessCard(context),

                        const SizedBox(height: AppSpacing.xl),

                        // Section Mon compte
                        Text(
                          'Mon compte',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildAccountCard(context, email, fullName),

                        const SizedBox(height: AppSpacing.xl),

                        // Bouton déconnexion
                        _buildLogoutButton(context),

                        const SizedBox(height: AppSpacing.pagePaddingBottom),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context) {
    final items = [
      _QuickItem(
        icon: Iconsax.chart,
        label: 'Tests d\'orientation',
        subtitle: 'Explore tes aptitudes',
        color: AppColors.primary,
        route: '/orientation',
      ),
      _QuickItem(
        icon: Iconsax.book,
        label: 'E-Learning',
        subtitle: 'Cours et vidéos',
        color: AppColors.categoryTechnology,
        route: '/elearning',
      ),
      _QuickItem(
        icon: Iconsax.building,
        label: 'Établissements',
        subtitle: 'Écoles et universités',
        color: AppColors.secondary,
        route: '/schools',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () => context.go(item.route),
                borderRadius: BorderRadius.circular(
                  i == 0
                      ? AppSpacing.cardRadius
                      : i == items.length - 1
                          ? AppSpacing.cardRadius
                          : 0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, String email, String fullName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.person_outline_rounded,
            label: 'Nom complet',
            value: fullName,
            isFirst: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _AccountRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.errorLight),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Se déconnecter',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Se déconnecter'),
          ],
        ),
        content:
            const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Déconnexion',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;

  const _QuickItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
