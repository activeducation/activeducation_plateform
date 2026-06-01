import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';

class PartnerSection extends StatefulWidget {
  const PartnerSection({super.key});

  @override
  State<PartnerSection> createState() => _PartnerSectionState();
}

class _PartnerSectionState extends State<PartnerSection> {
  bool _isPartner = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final storage = getIt<TokenStorage>();
    final role = await storage.getUserRole();
    final isPartner = role != null && ['partner_admin', 'admin', 'super_admin'].contains(role);
    if (mounted) setState(() { _isPartner = isPartner; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_isPartner) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingHorizontal,
        32,
        AppSpacing.pagePaddingHorizontal,
        0,
      ),
      child: InkWell(
        onTap: () => context.go('/partner/organization/create'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.secondary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Espace Partenaire', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez votre organisation, suivez vos bénéficiaires et développez votre réseau.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
