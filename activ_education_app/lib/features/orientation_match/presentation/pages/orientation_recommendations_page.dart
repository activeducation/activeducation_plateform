import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/orientation_match_datasource.dart';
import '../../data/models/recommendation_model.dart';
import '../cubit/recommendations_cubit.dart';
import '../widgets/recommendation_card.dart';

/// Page des recommandations d'orientation multi-critères.
class OrientationRecommendationsPage extends StatelessWidget {
  const OrientationRecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecommendationsCubit(
        OrientationMatchDataSourceImpl(getIt<Dio>(instanceName: 'apiClient')),
      )..load(),
      child: const _RecommendationsView(),
    );
  }
}

class _RecommendationsView extends StatelessWidget {
  const _RecommendationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Mes recommandations',
            style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocBuilder<RecommendationsCubit, RecommendationsState>(
        builder: (context, state) {
          if (state is RecommendationsLoading || state is RecommendationsInitial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is RecommendationsError) {
            return _buildError(context, state.message);
          }
          if (state is RecommendationsLoaded) {
            return _buildLoaded(context, state.result);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, RecommendationsResult result) {
    final recos = result.recommendations;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<RecommendationsCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CompletenessBanner(completeness: result.completeness),
          const SizedBox(height: 16),
          if (recos.isEmpty)
            _buildEmpty()
          else
            ...List.generate(
              recos.length,
              (i) => RecommendationCard(reco: recos[i], rank: i + 1),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.explore_off_rounded,
              size: 52, color: AppColors.primary.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text('Aucune recommandation pour l\'instant',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<RecommendationsCubit>().load(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau incitant à compléter le profil pour affiner les recommandations.
class _CompletenessBanner extends StatelessWidget {
  final ProfileCompleteness completeness;
  const _CompletenessBanner({required this.completeness});

  @override
  Widget build(BuildContext context) {
    final complete = completeness.percent >= 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.crossBrandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.crossBrandShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Profil complété à ${completeness.percent}%',
                  style: AppTypography.titleSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completeness.percent / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            complete
                ? 'Ton profil est complet : les recommandations sont au plus précis.'
                : 'Ajoute ${completeness.missing.join(', ')} pour affiner tes recommandations.',
            style: AppTypography.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.95), height: 1.4),
          ),
          if (!complete) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/orientation/profile'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 16),
                label: Text('Compléter mon profil',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
