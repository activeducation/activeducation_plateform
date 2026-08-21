import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../domain/entities/career.dart';
import '../../domain/entities/test_result.dart';

class ResultsPage extends StatelessWidget {
  final TestResult result;

  const ResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Vos Résultats'),
                centerTitle: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/home'),
                ),
                actions: [],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingHorizontal,
                  AppSpacing.md,
                  AppSpacing.pagePaddingHorizontal,
                  AppSpacing.pagePaddingBottom,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Hero profil
                    _buildProfileHero(context),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. Points clés (forces + conseil)
                    if (result.interpretation != null) ...[
                      _buildInsightsCard(context),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 3. Métiers recommandés, classés par correspondance
                    _buildCareersSection(context),
                    const SizedBox(height: AppSpacing.xl),

                    // 4. Domaines de formation correspondants
                    _buildFilieresSection(context),
                    const SizedBox(height: AppSpacing.xl),

                    // 4. Actions
                    _buildActions(context),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. HERO PROFIL
  // =========================================================================

  Widget _buildProfileHero(BuildContext context) {
    final interp = result.interpretation;
    final profileCode = interp?.profileCode ?? '';
    final traits = result.dominantTraits.take(3).join(' · ');

    // Résumé court : retire les marqueurs markdown et le préfixe "Profil XX —"
    String summary = interp?.profileSummary ?? '';
    summary = summary
        .replaceAll('**', '')
        .replaceAllMapped(RegExp(r'^Profil \w+ — '), (_) => '');
    // Garder seulement la 1ère phrase
    final dot = summary.indexOf('.');
    if (dot > 0 && dot < summary.length - 1) {
      summary = summary.substring(0, dot + 1);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        boxShadow: AppColors.glowShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.accent, size: 44),
          const SizedBox(height: AppSpacing.sm),
          if (profileCode.isNotEmpty)
            Text(
              'Type $profileCode',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (traits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              traits,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              summary,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 2. INSIGHTS (forces + conseil)
  // =========================================================================

  Widget _buildInsightsCard(BuildContext context) {
    final interp = result.interpretation!;
    final strengths = interp.strengths.take(4).toList();
    final advice = interp.advice;

    if (strengths.isEmpty && advice.isEmpty) return const SizedBox.shrink();

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
              const Icon(Icons.psychology, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Ce qui vous caractérise', style: AppTypography.titleMedium),
            ],
          ),

          // Forces
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...strengths.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(s, style: AppTypography.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],

          // Conseil
          if (advice.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(advice, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 3. MÉTIERS RECOMMANDÉS
  // =========================================================================

  Widget _buildCareersSection(BuildContext context) {
    // Les métiers arrivent déjà classés par score de correspondance depuis
    // l'API (career_matcher). On les affiche tels quels.
    //
    // Ils étaient auparavant regroupés par filière, ce qui produisait des
    // rapprochements faux : l'API renvoie une liste globale de 6 métiers, pas
    // 6 métiers PAR filière. Découper ces 6 métiers entre 6 cartes obligeait à
    // inventer des correspondances, d'où « Médecin » sous « Commerce & Gestion
    // d'Entreprise ». Un classement unique par score est à la fois plus exact
    // et plus lisible pour l'élève.
    final careers = [...result.recommendations]
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    if (careers.isEmpty) return const SizedBox.shrink();

    // Un score à 0 partout signale une suggestion de découverte (repli côté
    // API) et non une vraie correspondance : on ne montre pas de pourcentage
    // trompeur dans ce cas.
    final hasScores = careers.any((c) => c.matchScore > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.work_outline, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Métiers recommandés', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasScores
              ? 'Classés par correspondance avec ton profil'
              : 'Des métiers porteurs à découvrir',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...careers.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildCareerListItem(context, c, showScore: hasScores),
          ),
        ),
      ],
    );
  }

  Widget _buildCareerListItem(
    BuildContext context,
    Career career, {
    bool showScore = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/orientation/career', extra: career),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              career.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showScore) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _buildScoreBadge(career.matchScore),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        career.description.length > 90
                            ? '${career.description.substring(0, 90)}...'
                            : career.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (career.sector.isNotEmpty)
                            _buildMiniTag(
                              career.sector,
                              Icons.category_outlined,
                              AppColors.primary,
                            ),
                          if (career.salaryInfo.averageMonthlyFCFA > 0)
                            _buildMiniTag(
                              career.salaryInfo.formattedAverage,
                              Icons.payments_outlined,
                              AppColors.success,
                            ),
                          _buildMiniTag(
                            career.educationPath.minimumLevel,
                            Icons.school_outlined,
                            AppColors.info,
                          ),
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
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pastille du score de correspondance (0-100).
  Widget _buildScoreBadge(double score) {
    final value = score.clamp(0, 100).round();
    final color = value >= 70
        ? AppColors.success
        : value >= 40
            ? AppColors.info
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$value%',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================================================================
  // 4. DOMAINES DE FORMATION
  // =========================================================================

  Widget _buildFilieresSection(BuildContext context) {
    final sectors = result.interpretation?.recommendedSectors ?? [];

    // Repli : si l'API ne renvoie pas de domaines, les deduire des secteurs
    // des metiers recommandes.
    List<String> filieres;
    if (sectors.isNotEmpty) {
      filieres = sectors.take(6).toList();
    } else {
      final seen = <String>{};
      filieres = result.recommendations
          .map((c) => c.sector)
          .where((s) => s.isNotEmpty && seen.add(s))
          .take(6)
          .toList();
    }

    if (filieres.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Text('Domaines de formation', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Les filières d\'études qui correspondent à ton profil',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...filieres.asMap().entries.map(
              (e) => _buildFiliereCard(context, e.value, e.key),
            ),
      ],
    );
  }

  Widget _buildFiliereCard(BuildContext context, String sector, int index) {
    // Carte purement informative : les metiers ne sont plus rattaches a une
    // filiere (voir _buildCareersSection), il n'y a donc rien a ouvrir.
    final isFirst = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isFirst
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border: Border.all(
          color: isFirst
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForSector(sector),
              color: isFirst ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              sector,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
                color: isFirst ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. ACTIONS
  // =========================================================================

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Affiner avec les autres critères (notes, budget, projet…)
        _buildRefineCard(context),
        const SizedBox(height: AppSpacing.md),
        // Bouton principal : discuter avec AÏDA
        GradientButton(
          text: 'Discuter avec AÏDA',
          icon: Icons.smart_toy_rounded,
          onPressed: () => context.push(
            '/chat',
            extra: ChatPageArgs(orientationResult: result),
          ),
          showArrow: false,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/orientation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                child: const Text('Autre test'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GradientButton(
                text: 'Voir les écoles',
                onPressed: () => context.go('/schools'),
                showArrow: false,
                useSecondaryColor: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Invite à compléter le profil pour croiser ce test avec les notes, le
  /// budget et le projet professionnel (moteur d'orientation multi-critères).
  Widget _buildRefineCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/orientation/profile'),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.secondaryDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Affine tes résultats',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ajoute tes notes, ton budget et ton projet pour des '
                      'recommandations sur mesure.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.secondaryDark,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  Widget _buildMiniTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            style: AppTypography.labelSmall.copyWith(color: color, fontSize: 9),
          ),
        ],
      ),
    );
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

  IconData _getIconForSector(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('informati') ||
        s.contains('cyber') ||
        s.contains('système') ||
        s.contains('data') ||
        s.contains('numérique') ||
        s.contains('digital')) {
      return Icons.computer;
    }
    if (s.contains('santé') ||
        s.contains('infirmi') ||
        s.contains('médecine') ||
        s.contains('biologie') ||
        s.contains('pharmacie') ||
        s.contains('clinique')) {
      return Icons.local_hospital;
    }
    if (s.contains('enseigne') ||
        s.contains('éducation') ||
        s.contains('formation') ||
        s.contains('pédago') ||
        s.contains('communautaire')) {
      return Icons.school;
    }
    if (s.contains('finance') ||
        s.contains('banque') ||
        s.contains('comptabi') ||
        s.contains('audit') ||
        s.contains('statistiques') ||
        s.contains('actuariat') ||
        s.contains('assurance')) {
      return Icons.account_balance;
    }
    if (s.contains('commerce') ||
        s.contains('entrepre') ||
        s.contains('marketing') ||
        s.contains('vente') ||
        s.contains('management') ||
        s.contains('secrétariat') ||
        s.contains('logistique')) {
      return Icons.store;
    }
    if (s.contains('génie') ||
        s.contains('btp') ||
        s.contains('mécanique') ||
        s.contains('électrotechnique') ||
        s.contains('topographie') ||
        s.contains('maintenance') ||
        s.contains('physique') ||
        s.contains('architecture')) {
      return Icons.engineering;
    }
    if (s.contains('agriculture') ||
        s.contains('agroalimentaire') ||
        s.contains('environnement') ||
        s.contains('vétérinaire') ||
        s.contains('écologie')) {
      return Icons.agriculture;
    }
    if (s.contains('design') ||
        s.contains('graphique') ||
        s.contains('journalisme') ||
        s.contains('médias') ||
        s.contains('cinéma') ||
        s.contains('arts') ||
        s.contains('ux') ||
        s.contains('créa')) {
      return Icons.palette;
    }
    if (s.contains('droit') ||
        s.contains('administration') ||
        s.contains('juridique') ||
        s.contains('ressources humaines') ||
        s.contains('psychologie') ||
        s.contains('coaching') ||
        s.contains('fiscalité')) {
      return Icons.gavel;
    }
    return Icons.work_outline;
  }
}
