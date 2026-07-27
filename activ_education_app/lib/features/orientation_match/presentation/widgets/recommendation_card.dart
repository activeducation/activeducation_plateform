import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/recommendation_model.dart';

/// Carte d'un métier recommandé : score global, raisons, détail par critère.
class RecommendationCard extends StatelessWidget {
  final CareerRecommendation reco;
  final int rank;

  const RecommendationCard({super.key, required this.reco, required this.rank});

  Color get _scoreColor {
    if (reco.score >= 70) return AppColors.success;
    if (reco.score >= 45) return AppColors.secondary;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    final available = reco.breakdown.where((c) => c.isAvailable).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$rank',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reco.careerName,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _scoreBadge(),
            ],
          ),
          if (reco.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reco.reasons.map(_buildReason),
          ],
          if (available.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Détail du calcul',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...available.map(_buildCriterion),
          ],
        ],
      ),
    );
  }

  Widget _scoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _scoreColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${reco.score.round()}%',
        style: AppTypography.titleSmall.copyWith(
          color: _scoreColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterion(CriterionScore c) {
    final v = (c.value ?? 0).clamp(0, 100) / 100.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.label,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 11)),
              ),
              Text('${(c.value ?? 0).round()}',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v.toDouble(),
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                v >= 0.6 ? AppColors.secondary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
