import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'icon_button.dart';
import 'stat_chip.dart';
import 'stat_divider.dart';

class HeroHeader extends StatelessWidget {
  final VoidCallback onNotification;
  final VoidCallback onProfile;

  const HeroHeader({
    super.key,
    required this.onNotification,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String firstName = 'Explorer';
        String initials = 'E';
        if (state is AuthAuthenticated) {
          firstName =
              state.user.firstName ?? state.user.displayName ?? 'Explorer';
          initials = state.user.initials;
        }

        return Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $firstName 👋',
                              style: AppTypography.heroTitle.copyWith(
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Prêt à jouer ton avenir ?',
                              style: AppTypography.heroSubtitle,
                            ),
                          ],
                        ),
                      ),
                      // Notification
                      HomeIconButton(
                        icon: Iconsax.notification,
                        badgeActive: true,
                        onTap: onNotification,
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      GestureDetector(
                        onTap: onProfile,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.darkBorder2,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Gamification stats bar ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.darkBorder2),
                    ),
                    child: Column(
                      children: [
                        // Stats row
                        Row(
                          children: [
                            StatChip(
                              icon: '⭐',
                              value: 'Niv. 3',
                              label: 'NIVEAU',
                              valueColor: AppColors.xpGold,
                            ),
                            StatDivider(),
                            StatChip(
                              icon: '🔥',
                              value: '7',
                              label: 'STREAK',
                              valueColor: AppColors.streakFire,
                            ),
                            StatDivider(),
                            StatChip(
                              icon: '⚡',
                              value: '850',
                              label: 'XP',
                              valueColor: AppColors.xpBar,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // XP progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progression vers Niveau 4',
                                  style: AppTypography.statLabel.copyWith(
                                    fontSize: 10.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '850 / 1 000 XP',
                                  style: AppTypography.statLabel.copyWith(
                                    color: AppColors.xpBar,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 7,
                                    color: AppColors.darkBorder,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: 0.85,
                                    child: Container(
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.xpBarGradient,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
