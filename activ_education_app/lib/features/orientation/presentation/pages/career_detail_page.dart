import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/career.dart';

/// Page de détail d'un métier avec toutes les informations
/// formations, salaires et perspectives au Togo.
class CareerDetailPage extends StatelessWidget {
  final Career career;

  const CareerDetailPage({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar avec image
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  career.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 10,
                        color: Colors.black54,
                      )
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.7),
                        AppColors.accent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForSector(career.sector),
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Secteur Badge
                  _buildSectorBadge(),
                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  _buildSection(
                    title: 'Description',
                    icon: Icons.info_outline,
                    child: Text(
                      career.description,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Compétences requises
                  _buildSection(
                    title: 'Compétences Requises',
                    icon: Icons.psychology,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: career.requiredSkills.map((skill) {
                        return Chip(
                          label: Text(
                            skill,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          backgroundColor: AppColors.surfaceLight,
                          side: const BorderSide(color: AppColors.border),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Formation
                  _buildEducationSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Salaires
                  _buildSalarySection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Perspectives
                  _buildOutlookSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // Bouton retour
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('RETOUR AUX RÉSULTATS'),
                  ),
                  const SizedBox(height: AppSpacing.pagePaddingBottom),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForSector(career.sector),
            size: AppSpacing.iconSm,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            career.sector,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    final edu = career.educationPath;
    return _buildSection(
      title: 'Formation Requise',
      icon: Icons.school,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Niveau minimum
          _buildInfoRow(
            label: 'Niveau minimum',
            value: edu.minimumLevel,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            label: 'Durée d\'études',
            value: '${edu.durationYears} ans',
            icon: Icons.timer,
          ),
          const SizedBox(height: AppSpacing.md),

          // Formations recommandées
          Text(
            'Formations recommandées:',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...edu.recommendedFormations.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(f, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.md),

          // Écoles au Togo
          Text(
            'Écoles/Universités au Togo:',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...edu.schoolsInTogo.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(s, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              )),

          if (edu.certifications != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: AppColors.info, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Certifications: ${edu.certifications}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    final salary = career.salaryInfo;
    return _buildSection(
      title: 'Salaires au Togo',
      icon: Icons.payments,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphique simplifié des salaires
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSalaryCard('Débutant', salary.minMonthlyFCFA),
                    _buildSalaryCard('Moyen', salary.averageMonthlyFCFA, isHighlight: true),
                    _buildSalaryCard('Senior', salary.maxMonthlyFCFA),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Note sur l'expérience
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    salary.experienceNote,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(String label, int amount, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: isHighlight
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary),
            )
          : null,
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isHighlight ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            SalaryInfo.formatFCFA(amount),
            style: isHighlight
                ? AppTypography.titleLarge.copyWith(color: AppColors.primary)
                : AppTypography.titleMedium,
          ),
          Text(
            'FCFA/mois',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlookSection() {
    final outlook = career.outlook;
    return _buildSection(
      title: 'Perspectives d\'Emploi',
      icon: Icons.trending_up,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges demande et tendance
          Row(
            children: [
              _buildOutlookBadge(
                outlook.demandLabel,
                _getDemandColor(outlook.demand),
                Icons.people,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildOutlookBadge(
                outlook.trendLabel,
                _getTrendColor(outlook.trend),
                _getTrendIcon(outlook.trend),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            outlook.description,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          // Principaux employeurs
          Text(
            'Principaux Employeurs au Togo:',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: outlook.topEmployers.map((employer) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(employer, style: AppTypography.bodySmall),
                  ],
                ),
              );
            }).toList(),
          ),

          // Potentiel entrepreneuriat
          if (outlook.entrepreneurshipPotential) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ce métier offre un fort potentiel pour créer votre propre entreprise!',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutlookBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Text('$label: ', style: AppTypography.labelMedium),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  IconData _getIconForSector(String sector) {
    switch (sector) {
      case 'Technologie & Informatique':
        return Icons.computer;
      case 'Santé':
        return Icons.local_hospital;
      case 'Éducation':
        return Icons.school;
      case 'Finance & Banque':
        return Icons.account_balance;
      case 'Commerce & Entrepreneuriat':
        return Icons.store;
      case 'Ingénierie & BTP':
        return Icons.engineering;
      case 'Agriculture & Environnement':
        return Icons.agriculture;
      case 'Création & Médias':
        return Icons.palette;
      case 'Droit & Administration':
        return Icons.gavel;
      default:
        return Icons.work;
    }
  }

  Color _getDemandColor(JobDemand demand) {
    switch (demand) {
      case JobDemand.high:
        return AppColors.success;
      case JobDemand.medium:
        return AppColors.warning;
      case JobDemand.low:
        return AppColors.error;
    }
  }

  Color _getTrendColor(GrowthTrend trend) {
    switch (trend) {
      case GrowthTrend.growing:
        return AppColors.success;
      case GrowthTrend.stable:
        return AppColors.info;
      case GrowthTrend.declining:
        return AppColors.error;
    }
  }

  IconData _getTrendIcon(GrowthTrend trend) {
    switch (trend) {
      case GrowthTrend.growing:
        return Icons.trending_up;
      case GrowthTrend.stable:
        return Icons.trending_flat;
      case GrowthTrend.declining:
        return Icons.trending_down;
    }
  }
}
