import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../data/datasources/careers_database.dart';
import '../../domain/entities/career.dart';
import '../../domain/entities/test_result.dart';

class ResultsPage extends StatelessWidget {
  final TestResult result;

  const ResultsPage({super.key, required this.result});

  // =========================================================================
  // Mapping : noms de secteurs backend → noms locaux CareersDatabase
  // =========================================================================
  static const Map<String, String> _sectorMapping = {
    // Réaliste
    'Génie Civil & BTP': 'Ingénierie & BTP',
    'Mécanique & Électrotechnique': 'Ingénierie & BTP',
    'Agriculture & Agroalimentaire': 'Agriculture & Environnement',
    'Topographie & Géomatique': 'Ingénierie & BTP',
    'Maintenance & Logistique Industrielle': 'Commerce & Entrepreneuriat',
    // Investigateur
    'Informatique & Cybersécurité': 'Technologie & Informatique',
    'Biologie & Pharmacie': 'Santé',
    'Mathématiques & Data Science': 'Technologie & Informatique',
    'Physique & Énergies Renouvelables': 'Ingénierie & BTP',
    'Médecine & Recherche Clinique': 'Santé',
    // Artistique
    'Design Graphique & Communication Visuelle': 'Création & Médias',
    "Architecture & Décoration d'Intérieur": 'Ingénierie & BTP',
    'Journalisme & Médias Numériques': 'Création & Médias',
    'Cinéma, Arts & Culture': 'Création & Médias',
    'Marketing Créatif & UX Design': 'Création & Médias',
    // Social
    'Sciences Infirmières & Santé Communautaire': 'Santé',
    "Enseignement & Sciences de l'Éducation": 'Éducation',
    'Psychologie & Travail Social': 'Droit & Administration',
    'Ressources Humaines & Coaching': 'Droit & Administration',
    'Développement Communautaire & ONG': 'Éducation',
    // Entrepreneur
    "Commerce & Gestion d'Entreprise": 'Commerce & Entrepreneuriat',
    'Finance & Banque': 'Finance & Banque',
    'Marketing & Vente': 'Commerce & Entrepreneuriat',
    "Droit des Affaires & Entrepreneuriat": 'Droit & Administration',
    'Management & Direction de Projets': 'Commerce & Entrepreneuriat',
    // Conventionnel
    'Comptabilité, Audit & Contrôle de Gestion': 'Finance & Banque',
    'Administration Publique & Fiscalité': 'Droit & Administration',
    "Gestion des Systèmes d'Information": 'Technologie & Informatique',
    'Statistiques & Actuariat': 'Finance & Banque',
    'Secrétariat & Office Management': 'Commerce & Entrepreneuriat',
  };

  List<Career> _getCareersForSector(String sectorName) {
    final localSector = _sectorMapping[sectorName] ?? sectorName;
    return CareersDatabase.getCareersBySector(localSector).take(5).toList();
  }

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
                title: const Text('Vos Résultats'),
                centerTitle: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/home'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareResults(context),
                  ),
                ],
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

                    // 3. Filières recommandées (section principale)
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
      summary = '${summary.substring(0, dot + 1)}';
    }

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
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              summary,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(s, style: AppTypography.bodyMedium)),
                    ],
                  ),
                )),
          ],

          // Conseil
          if (advice.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.accent, size: 18),
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
  // 3. FILIÈRES RECOMMANDÉES
  // =========================================================================

  Widget _buildFilieresSection(BuildContext context) {
    final sectors = result.interpretation?.recommendedSectors ?? [];

    // Fallback : si pas de secteurs depuis l'API, déduire depuis les recommendations
    List<String> filieres;
    if (sectors.isNotEmpty) {
      filieres = sectors.take(5).toList();
    } else {
      // Grouper les carrières recommandées par secteur
      final sectorsSeen = <String>{};
      filieres = result.recommendations
          .map((c) => c.sector)
          .where((s) => sectorsSeen.add(s))
          .take(5)
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
            Text('Filières recommandées', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Touchez une filière pour découvrir les métiers associés',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        ...filieres.asMap().entries.map(
              (e) => _buildFiliereCard(context, e.value, e.key),
            ),
      ],
    );
  }

  Widget _buildFiliereCard(BuildContext context, String sector, int index) {
    final careers = _getCareersForSector(sector);
    final count = careers.length;
    final isFirst = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: count > 0
              ? () => _showCareersBottomSheet(context, sector, careers)
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sector,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
                          color: isFirst ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$count métier${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (count > 0)
                  Icon(
                    Icons.chevron_right,
                    color: isFirst ? AppColors.primary : AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BOTTOM SHEET : MÉTIERS D'UNE FILIÈRE
  // =========================================================================

  void _showCareersBottomSheet(
      BuildContext context, String sector, List<Career> careers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getIconForSector(sector),
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sector,
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${careers.length} métier${careers.length > 1 ? 's' : ''} associé${careers.length > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Liste des métiers
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: careers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) =>
                      _buildCareerListItem(context, careers[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareerListItem(BuildContext context, Career career) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.push('/orientation/career', extra: career);
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career.name,
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        career.description.length > 90
                            ? '${career.description.substring(0, 90)}...'
                            : career.description,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (career.salaryInfo.averageMonthlyFCFA > 0) ...[
                            _buildMiniTag(
                              career.salaryInfo.formattedAverage,
                              Icons.payments_outlined,
                              AppColors.success,
                            ),
                            const SizedBox(width: 6),
                          ],
                          _buildMiniTag(
                            career.educationPath.minimumLevel,
                            Icons.school_outlined,
                            AppColors.info,
                          ),
                          const SizedBox(width: 6),
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
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. ACTIONS
  // =========================================================================

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Bouton principal : discuter avec AÏDA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(
              '/chat',
              extra: ChatPageArgs(orientationResult: result),
            ),
            icon: const Icon(Icons.smart_toy_rounded, size: 20),
            label: const Text('DISCUTER AVEC AÏDA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/orientation'),
                child: const Text('AUTRE TEST'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/schools'),
                child: const Text('VOIR LES ÉCOLES'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  void _shareResults(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir !'),
        backgroundColor: AppColors.info,
      ),
    );
  }

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
            style:
                AppTypography.labelSmall.copyWith(color: color, fontSize: 9),
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
        s.contains('digital')) return Icons.computer;
    if (s.contains('santé') ||
        s.contains('infirmi') ||
        s.contains('médecine') ||
        s.contains('biologie') ||
        s.contains('pharmacie') ||
        s.contains('clinique')) return Icons.local_hospital;
    if (s.contains('enseigne') ||
        s.contains('éducation') ||
        s.contains('formation') ||
        s.contains('pédago') ||
        s.contains('communautaire')) return Icons.school;
    if (s.contains('finance') ||
        s.contains('banque') ||
        s.contains('comptabi') ||
        s.contains('audit') ||
        s.contains('statistiques') ||
        s.contains('actuariat') ||
        s.contains('assurance')) return Icons.account_balance;
    if (s.contains('commerce') ||
        s.contains('entrepre') ||
        s.contains('marketing') ||
        s.contains('vente') ||
        s.contains('management') ||
        s.contains('secrétariat') ||
        s.contains('logistique')) return Icons.store;
    if (s.contains('génie') ||
        s.contains('btp') ||
        s.contains('mécanique') ||
        s.contains('électrotechnique') ||
        s.contains('topographie') ||
        s.contains('maintenance') ||
        s.contains('physique') ||
        s.contains('architecture')) return Icons.engineering;
    if (s.contains('agriculture') ||
        s.contains('agroalimentaire') ||
        s.contains('environnement') ||
        s.contains('vétérinaire') ||
        s.contains('écologie')) return Icons.agriculture;
    if (s.contains('design') ||
        s.contains('graphique') ||
        s.contains('journalisme') ||
        s.contains('médias') ||
        s.contains('cinéma') ||
        s.contains('arts') ||
        s.contains('ux') ||
        s.contains('créa')) return Icons.palette;
    if (s.contains('droit') ||
        s.contains('administration') ||
        s.contains('juridique') ||
        s.contains('ressources humaines') ||
        s.contains('psychologie') ||
        s.contains('coaching') ||
        s.contains('fiscalité')) return Icons.gavel;
    return Icons.work_outline;
  }
}
