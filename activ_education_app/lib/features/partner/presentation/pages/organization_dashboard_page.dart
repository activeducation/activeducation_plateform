import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/organization.dart';
import '../bloc/partner_bloc.dart';
import '../widgets/beneficiary_list_item.dart';
import '../widgets/stats_card.dart';

class OrganizationDashboardPage extends StatefulWidget {
  final String organizationId;

  const OrganizationDashboardPage({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationDashboardPage> createState() => _OrganizationDashboardPageState();
}

class _OrganizationDashboardPageState extends State<OrganizationDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<PartnerBloc>().add(PartnerLoadDashboard(widget.organizationId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<PartnerBloc, PartnerState>(
        builder: (context, state) {
          if (state is PartnerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PartnerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          if (state is PartnerDashboardLoaded) {
            return _buildDashboard(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, PartnerDashboardLoaded state) {
    final organization = state.organization;
    final stats = state.stats;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(organization, stats),
        ),
        SliverToBoxAdapter(
          child: _buildStatsSection(stats),
        ),
        SliverToBoxAdapter(
          child: _buildBeneficiariesHeader(context),
        ),
        _buildBeneficiariesList(context, state),
      ],
    );
  }

  Widget _buildHeader(Organization organization, OrganizationWithStats? stats) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              organization.typeLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (organization.partnerCode != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              organization.partnerCode!,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (organization.description != null) ...[
              const SizedBox(height: 12),
              Text(
                organization.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(OrganizationWithStats? stats) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: 'Total',
              value: '${stats?.totalBeneficiaries ?? 0}',
              icon: Icons.people_outline,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'Actifs',
              value: '${stats?.activeBeneficiaries ?? 0}',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'Complétés',
              value: '${stats?.completedBeneficiaries ?? 0}',
              icon: Icons.done_all,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bénéficiaires',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.push('/partner/beneficiary/create/${widget.organizationId}'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesList(BuildContext context, PartnerDashboardLoaded state) {
    if (state.beneficiaries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.child_care,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun bénéficiaire enregistré',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter un enfant ou jeune orienté',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == state.beneficiaries.length) {
              if (state.hasMore) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () {
                              context.read<PartnerBloc>().add(const PartnerLoadMoreBeneficiaries());
                            },
                            child: const Text('Charger plus'),
                          ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            final beneficiary = state.beneficiaries[index];
            return BeneficiaryListItem(
              beneficiary: beneficiary,
              onTap: () => context.push('/partner/beneficiary/${beneficiary.id}?orgId=${widget.organizationId}'),
              onDelete: () => _showDeleteDialog(context, beneficiary),
            );
          },
          childCount: state.beneficiaries.length + (state.hasMore ? 1 : 0),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Beneficiary beneficiary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver le bénéficiaire'),
        content: Text('Voulez-vous désactiver ${beneficiary.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PartnerBloc>().add(PartnerDeleteBeneficiary(beneficiary.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }
}