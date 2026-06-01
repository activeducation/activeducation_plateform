import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
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

  Widget _buildShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder2),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Column(
                children: [
                  Container(
                    height: 14, width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10, width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )),
          ),
          const SizedBox(height: 14),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatChip(
            icon: '⭐',
            value: 'Niv. --',
            label: 'NIVEAU',
            valueColor: AppColors.xpGold,
          ),
          StatDivider(),
          StatChip(
            icon: '🔥',
            value: '--',
            label: 'STREAK',
            valueColor: AppColors.streakFire,
          ),
          StatDivider(),
          StatChip(
            icon: '⚡',
            value: '--',
            label: 'XP',
            valueColor: AppColors.xpBar,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar({
    required int level,
    required int streak,
    required int xp,
    required int nextLevelXp,
    required double progress,
  }) {
    return Container(
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
                value: 'Niv. $level',
                label: 'NIVEAU',
                valueColor: AppColors.xpGold,
              ),
              StatDivider(),
              StatChip(
                icon: '🔥',
                value: '$streak',
                label: 'STREAK',
                valueColor: AppColors.streakFire,
              ),
              StatDivider(),
              StatChip(
                icon: '⚡',
                value: '$xp',
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
                    'Progression vers Niveau ${level + 1}',
                    style: AppTypography.statLabel.copyWith(
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '$xp / $nextLevelXp XP',
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
                      widthFactor: progress.clamp(0.0, 1.0),
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
    );
  }

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
                  BlocBuilder<GamificationCubit, GamificationState>(
                    builder: (context, gState) {
                      if (gState is GamificationLoading) {
                        return _buildShimmer();
                      }

                      if (gState is GamificationError) {
                        return _buildEmptyStats();
                      }

                      if (gState is GamificationLoaded) {
                        final profile = gState.profile;
                        final stats = profile.stats;
                        return _buildStatsBar(
                          level: stats.currentLevel,
                          streak: stats.currentStreak,
                          xp: stats.totalXp,
                          nextLevelXp: profile.nextLevelXp,
                          progress: profile.levelProgress,
                        );
                      }

                      return _buildEmptyStats();
                    },
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
