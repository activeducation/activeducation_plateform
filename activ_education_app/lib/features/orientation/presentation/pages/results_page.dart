import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/career.dart';
import '../../domain/entities/test_result.dart';

class ResultsPage extends StatelessWidget {
  final TestResult result;

  const ResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Vos Resultats'),
                centerTitle: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.go('/home');
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      _shareResults(context);
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.md),
                    _buildProfileSummary(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildRadarChart(context),
                    const SizedBox(height: AppSpacing.xl),
                    if (result.interpretation != null) ...[
                      _buildInterpretation(context),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _buildDominantTraits(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildCareerRecommendations(context),
                    if (result.matchingPrograms.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildMatchingPrograms(context),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _buildScoreBreakdown(context),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.go('/orientation');
                            },
                            child: const Text('AUTRE TEST'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/schools');
                            },
                            child: const Text('VOIR LES ECOLES'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.pagePaddingBottom),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResults(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalite de partage a venir!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  // ===========================================================================
  // PROFIL SUMMARY (hero card)
  // ===========================================================================

  Widget _buildProfileSummary(BuildContext context) {
    final interp = result.interpretation;
    final profileCode = interp?.profileCode ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
        boxShadow: AppColors.glowShadow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: AppColors.accent,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Profil Dominant',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (profileCode.isNotEmpty)
            Text(
              'Type $profileCode',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            result.dominantTraits.take(3).join(' - '),
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _getProfileDescription(result.dominantTraits.first),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getProfileDescription(String trait) {
    final descriptions = {
      // RIASEC (avec accents, correspondant au backend)
      'Réaliste': 'Vous êtes pragmatique et aimez travailler avec vos mains. Les métiers techniques et concrets vous conviennent.',
      'Investigateur': 'Vous êtes curieux et analytique. La recherche et la résolution de problèmes vous passionnent.',
      'Artistique': 'Vous êtes créatif et expressif. Les métiers artistiques et innovants vous attirent.',
      'Social': 'Vous aimez aider les autres. Les métiers du service et de l\'accompagnement vous correspondent.',
      'Entrepreneur': 'Vous êtes ambitieux et leader. Les métiers du business et du management vous motivent.',
      'Conventionnel': 'Vous êtes organisé et méthodique. Les métiers structurés et administratifs vous plaisent.',
    };
    return descriptions[trait] ?? 'Votre profil est unique et offre de nombreuses possibilites.';
  }

  // ===========================================================================
  // INTERPRETATION (nouveau)
  // ===========================================================================

  Widget _buildInterpretation(BuildContext context) {
    final interp = result.interpretation!;

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
              const Icon(Icons.psychology, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Interpretation de votre Profil', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Forces
          if (interp.strengths.isNotEmpty) ...[
            Text(
              'Vos Points Forts',
              style: AppTypography.labelLarge.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...interp.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(s, style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.md),
          ],

          // Style de travail
          if (interp.workStyle.isNotEmpty) ...[
            Text(
              'Votre Style de Travail',
              style: AppTypography.labelLarge.copyWith(color: AppColors.info),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.work, color: AppColors.info, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      interp.workStyle,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Conseils personnalises
          if (interp.advice.isNotEmpty) ...[
            Text(
              'Nos Conseils',
              style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: AppColors.accent, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      interp.advice,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Secteurs recommandes
          if (interp.recommendedSectors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Secteurs Recommandes',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: interp.recommendedSectors.map((s) => Chip(
                    avatar: Icon(_getIconForSector(s), size: 16, color: AppColors.primary),
                    label: Text(s, style: AppTypography.labelSmall),
                    backgroundColor: AppColors.surfaceLight,
                    side: const BorderSide(color: AppColors.border),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // RADAR CHART
  // ===========================================================================

  Widget _buildRadarChart(BuildContext context) {
    final categories = result.scores.keys.toList();
    final values = result.scores.values.toList();

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
              const Icon(Icons.radar, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Profil Graphique', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 280,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    entryRadius: 3,
                    dataEntries: values.map((e) => RadarEntry(value: e)).toList(),
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: AppColors.glassBorder),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: AppTypography.labelSmall.copyWith(fontSize: 10),
                getTitle: (index, angle) {
                  if (index < categories.length) {
                    String name = categories[index];
                    if (name.length > 10) {
                      name = '${name.substring(0, 8)}..';
                    }
                    return RadarChartTitle(
                      text: name,
                      angle: angle,
                    );
                  }
                  return const RadarChartTitle(text: '');
                },
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                tickBorderData: const BorderSide(color: AppColors.glassBorder),
                gridBorderData: const BorderSide(color: AppColors.glassBorder, width: 1),
              ),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DOMINANT TRAITS
  // ===========================================================================

  Widget _buildDominantTraits(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text('Vos Traits Dominants', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...result.dominantTraits.asMap().entries.map((entry) {
          final index = entry.key;
          final trait = entry.value;
          final isFirst = index == 0;
          final score = result.scores[trait];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isFirst ? AppColors.cardGradient : null,
                color: isFirst ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: isFirst
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppColors.accent
                          : AppColors.textTertiary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.labelLarge.copyWith(
                          color: isFirst ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trait,
                          style: isFirst
                              ? AppTypography.titleMedium.copyWith(color: AppColors.primary)
                              : AppTypography.bodyLarge,
                        ),
                        if (isFirst) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Trait principal',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: AppTypography.labelMedium.copyWith(
                          color: _getScoreColor(score),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isFirst) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // CAREER RECOMMENDATIONS (avec match score)
  // ===========================================================================

  Widget _buildCareerRecommendations(BuildContext context) {
    final recommendations = result.recommendations;

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.work, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text('Metiers Recommandes', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bases sur votre profil, tries par correspondance:',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        ...recommendations.map((career) => _buildCareerCard(context, career)),
      ],
    );
  }

  Widget _buildCareerCard(BuildContext context, Career career) {
    final hasMatchScore = career.matchScore > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/orientation/career', extra: career);
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                      ),
                      child: Icon(
                        _getIconForSector(career.sector),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            career.name,
                            style: AppTypography.titleMedium,
                          ),
                          Text(
                            career.sector,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasMatchScore)
                      _buildMatchScoreBadge(career.matchScore),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),

                // Matching traits chips
                if (career.matchingTraits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: career.matchingTraits.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 9,
                            ),
                          ),
                        )).toList(),
                  ),
                ],

                if (career.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    career.description.length > 120
                        ? '${career.description.substring(0, 120)}...'
                        : career.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (career.salaryInfo.averageMonthlyFCFA > 0)
                      _buildMiniTag(
                        career.salaryInfo.formattedAverage,
                        Icons.payments,
                        AppColors.success,
                      ),
                    if (career.salaryInfo.averageMonthlyFCFA > 0)
                      const SizedBox(width: AppSpacing.sm),
                    _buildMiniTag(
                      career.educationPath.minimumLevel,
                      Icons.school,
                      AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildMiniTag(
                      career.outlook.demandLabel,
                      Icons.trending_up,
                      _getDemandColor(career.outlook.demand),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchScoreBadge(double score) {
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.warning
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MATCHING SCHOOL PROGRAMS (nouveau)
  // ===========================================================================

  Widget _buildMatchingPrograms(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Text('Formations Recommandees', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Programmes disponibles dans les ecoles au Togo:',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        ...result.matchingPrograms.map((prog) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  // School logo or icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: prog.schoolLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              prog.schoolLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.school, color: AppColors.info, size: 20),
                            ),
                          )
                        : const Icon(Icons.school, color: AppColors.info, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prog.programName,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          prog.schoolName,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            if (prog.programLevel != null && prog.programLevel!.isNotEmpty) ...[
                              _buildMiniTag(
                                prog.programLevel!.toUpperCase(),
                                Icons.school,
                                AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (prog.schoolCity != null)
                              _buildMiniTag(
                                prog.schoolCity!,
                                Icons.location_on,
                                AppColors.textTertiary,
                              ),
                            if (prog.programDuration != null) ...[
                              const SizedBox(width: 4),
                              _buildMiniTag(
                                '${prog.programDuration} ans',
                                Icons.timer,
                                AppColors.textTertiary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
                    onPressed: () {
                      context.push('/schools/${prog.schoolId}');
                    },
                  ),
                ],
              ),
            )),

        // Bouton voir toutes les ecoles
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/schools'),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Voir toutes les ecoles'),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MINI TAG + SCORE BREAKDOWN
  // ===========================================================================

  Widget _buildMiniTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context) {
    final sortedScores = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
              const Icon(Icons.bar_chart, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text('Detail des Scores', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...sortedScores.map((entry) {
            final percentage = entry.value / 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          entry.key,
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)}%',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceLight,
                      color: _getScoreColor(entry.value),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Color _getScoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.primary;
    if (score >= 30) return AppColors.warning;
    return AppColors.textTertiary;
  }

  IconData _getIconForSector(String sector) {
    switch (sector) {
      case 'Technologie & Informatique':
      case 'Technologie & IT':
        return Icons.computer;
      case 'Sante':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Finance & Banque':
        return Icons.account_balance;
      case 'Commerce & Entrepreneuriat':
        return Icons.store;
      case 'Ingenierie & BTP':
        return Icons.engineering;
      case 'Agriculture & Environnement':
        return Icons.agriculture;
      case 'Creation & Medias':
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
}
