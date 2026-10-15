import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_typography.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';

class BentoHeroTile extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;

  const BentoHeroTile({
    super.key,
    required this.onProfileTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);
    final capitalizedDate = "${dateStr[0].toUpperCase()}${dateStr.substring(1)}";

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String firstName = 'Explorateur';
        String initials = 'E';
        if (state is AuthAuthenticated) {
          firstName = state.user.firstName ?? state.user.displayName ?? 'Explorateur';
          initials = state.user.initials;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    capitalizedDate,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      _IconButton(icon: Iconsax.search_normal, onTap: onSearchTap),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bonjour,',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                firstName,
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Prêt à construire ton avenir éducatif aujourd\'hui ?',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _hover ? AppColors.primarySurface : AppColors.surfaceLow,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: _hover ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
