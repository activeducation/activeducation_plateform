import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/inputs/custom_search_bar.dart';
import '../../../../shared/widgets/inputs/filter_chip_bar.dart';
import '../../data/models/school_model.dart';
import '../../data/repositories/school_repository.dart';
import '../../../../core/constants/api_endpoints.dart';

// =============================================================================
// Page principale : Annuaire des ecoles
// =============================================================================

class SchoolDirectoryPage extends StatefulWidget {
  const SchoolDirectoryPage({super.key});

  @override
  State<SchoolDirectoryPage> createState() => _SchoolDirectoryPageState();
}

class _SchoolDirectoryPageState extends State<SchoolDirectoryPage> {
  late final SchoolRepository _repository;

  List<SchoolSummary> _schools = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedType;
  int _selectedFilterIndex = 0;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(label: 'Toutes'),
    FilterChipItem(label: 'Universite'),
    FilterChipItem(label: 'Grande Ecole'),
    FilterChipItem(label: 'Institut'),
    FilterChipItem(label: 'Centre de Formation'),
  ];

  static const _filterTypeMap = {
    0: null,
    1: 'university',
    2: 'grande_ecole',
    3: 'institut',
    4: 'centre_formation',
  };

  @override
  void initState() {
    super.initState();
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _repository = SchoolRepository(dio);
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _repository.getSchools(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        city: _selectedCity,
        type: _selectedType,
      );
      setState(() {
        _schools = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les ecoles. Verifiez votre connexion.';
        _isLoading = false;
      });
    }
  }

  void _onFilterSelected(int index) {
    setState(() {
      _selectedFilterIndex = index;
      _selectedType = _filterTypeMap[index];
    });
    _loadSchools();
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadSchools();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Text(
              'Annuaire des Ecoles',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: AppTypography.labelSmall.copyWith(letterSpacing: 1),
                children: [
                  TextSpan(
                    text: 'ACTIV ',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: 'EDUCATION',
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_4, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
            child: Column(
              children: [
                CustomSearchBar(
                  hintText: 'Rechercher une ecole, un BTS...',
                  onChanged: _onSearch,
                ),
                const SizedBox(height: AppSpacing.md),
                FilterChipBar(
                  filters: _filters,
                  selectedIndex: _selectedFilterIndex,
                  onSelected: _onFilterSelected,
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.wifi_square, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(text: 'Reessayer', onPressed: _loadSchools, isSmall: true),
            ],
          ),
        ),
      );
    }
    if (_schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.building_4, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucune ecole trouvee', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSchools,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePaddingHorizontal),
        itemCount: _schools.length,
        itemBuilder: (context, index) {
          return _SchoolCard(
            school: _schools[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchoolDetailPage(
                    schoolId: _schools[index].id,
                    schoolName: _schools[index].name,
                    repository: _repository,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// Card ecole enrichie
// =============================================================================

class _SchoolCard extends StatelessWidget {
  final SchoolSummary school;
  final VoidCallback? onTap;

  const _SchoolCard({required this.school, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF0F5FF),
                      AppColors.primarySurface,
                      const Color(0xFFFEF3E2).withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: school.logoUrl != null && school.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            school.logoUrl!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Iconsax.building_4,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : Icon(
                          Iconsax.building_4,
                          size: 40,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                ),
              ),
              // Badge type
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: school.isPublic ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    school.statusLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              // Badge type etablissement
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    school.typeLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Iconsax.building, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Iconsax.location, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                school.city,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (school.description != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    school.description!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                // Info row : frais + etudiants
                Row(
                  children: [
                    if (school.tuitionRange != null) ...[
                      Icon(Iconsax.money_2, size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          school.tuitionRange!,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (school.tuitionRange != null && school.studentCount != null)
                      const SizedBox(width: AppSpacing.md),
                    if (school.studentCount != null) ...[
                      Icon(Iconsax.people, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(school.studentCount!)} etudiants',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Accreditations
                if (school.accreditations.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: school.accreditations.map((acc) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          acc,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.md),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.info_circle, size: 16),
                            const SizedBox(width: 6),
                            Text('Details', style: AppTypography.labelMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GradientButton(
                        text: 'Voir filieres',
                        isSmall: true,
                        showArrow: true,
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

// =============================================================================
// Page detail ecole — chargee depuis l'API
// =============================================================================

class SchoolDetailPage extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final SchoolRepository repository;

  const SchoolDetailPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.repository,
  });

  @override
  State<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends State<SchoolDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SchoolDetail? _school;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.repository.getSchoolDetail(widget.schoolId);
      setState(() {
        _school = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les details.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      GradientButton(text: 'Reessayer', onPressed: _loadDetail, isSmall: true),
                    ],
                  ),
                )
              : _buildContent(),
      floatingActionButton: _school != null
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_school!.phone != null) {
                  launchUrl(Uri.parse('tel:${_school!.phone}'));
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Iconsax.call, color: Colors.white),
              label: Text(
                'Contacter',
                style: AppTypography.labelMedium.copyWith(color: Colors.white),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContent() {
    final school = _school!;
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.export_2, color: Colors.white, size: 20),
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.heart, color: Colors.white, size: 20),
              ),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: school.coverImageUrl != null && school.coverImageUrl!.isNotEmpty
                ? Image.network(
                    school.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Center(
                        child: Icon(Iconsax.building_4, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    child: Center(
                      child: Icon(Iconsax.building_4, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              // School Info Card
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePaddingHorizontal),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: school.logoUrl != null && school.logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  school.logoUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Iconsax.building, color: AppColors.primary, size: 32),
                                ),
                              )
                            : const Icon(Iconsax.building, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        school.name,
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${school.city}${school.address != null ? ' - ${school.address}' : ''}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _Badge(
                            label: school.isPublic ? 'Etablissement Public' : 'Etablissement Prive',
                            color: school.isPublic ? AppColors.primary : AppColors.secondary,
                          ),
                          ...school.accreditations.map(
                            (acc) => _Badge(label: acc, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Description'),
                  Tab(text: 'Filieres'),
                  Tab(text: 'Admission'),
                  Tab(text: 'Contact'),
                ],
              ),
              // Tab Content
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DescriptionTab(school: school),
                    _FilieresTab(school: school),
                    _AdmissionTab(school: school),
                    _ContactTab(school: school),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Badge widget
// =============================================================================

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Onglet Description — avec chiffres cles
// =============================================================================

class _DescriptionTab extends StatelessWidget {
  final SchoolDetail school;

  const _DescriptionTab({required this.school});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'A propos',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              school.description ?? 'Aucune description disponible.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chiffres cles
          Text(
            'Chiffres cles',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (school.foundingYear != null)
                Expanded(child: _StatCard(icon: Iconsax.calendar, label: 'Fondation', value: '${school.foundingYear}')),
              if (school.studentCount != null)
                Expanded(child: _StatCard(icon: Iconsax.people, label: 'Etudiants', value: _formatNumber(school.studentCount!))),
              Expanded(child: _StatCard(icon: Iconsax.book_1, label: 'Filieres', value: '${school.programs.length}')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Domaines
          if (school.programsOffered.isNotEmpty) ...[
            Text(
              'Domaines de formation',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: school.programsOffered.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Onglet Filieres — groupees par niveau
// =============================================================================

class _FilieresTab extends StatelessWidget {
  final SchoolDetail school;

  const _FilieresTab({required this.school});

  @override
  Widget build(BuildContext context) {
    if (school.programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.book, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucune filiere enregistree', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Grouper par niveau
    final grouped = <String, List<SchoolProgram>>{};
    for (final p in school.programs) {
      final key = p.levelLabel.isNotEmpty ? p.levelLabel : 'Autre';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    // Ordre de tri des niveaux
    const levelOrder = ['BTS', 'Licence', 'Master', 'Doctorat', 'Autre'];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = levelOrder.indexOf(a);
        final ib = levelOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final level in sortedKeys) ...[
            // Titre du groupe
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                level,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Programmes de ce niveau
            ...grouped[level]!.map((p) => _ProgramItem(program: p)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProgramItem extends StatelessWidget {
  final SchoolProgram program;

  const _ProgramItem({required this.program});

  IconData get _icon {
    final name = program.name.toLowerCase();
    if (name.contains('info') || name.contains('logiciel') || name.contains('dev') || name.contains('cyber') || name.contains('cloud') || name.contains('reseau')) return Iconsax.code;
    if (name.contains('droit') || name.contains('juridique')) return Iconsax.book;
    if (name.contains('sante') || name.contains('medecine')) return Iconsax.health;
    if (name.contains('genie civil') || name.contains('btp') || name.contains('electricite') || name.contains('mecanique') || name.contains('froid') || name.contains('maintenance')) return Iconsax.cpu;
    if (name.contains('marketing') || name.contains('commerce') || name.contains('communication')) return Iconsax.chart;
    if (name.contains('finance') || name.contains('comptabilite') || name.contains('banque')) return Iconsax.money_2;
    if (name.contains('management') || name.contains('gestion') || name.contains('rh') || name.contains('logistique')) return Iconsax.briefcase;
    if (name.contains('agro') || name.contains('environnement')) return Iconsax.tree;
    if (name.contains('lettres') || name.contains('economie')) return Iconsax.document;
    return Iconsax.book_1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (program.description != null)
                  Text(
                    program.description!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (program.durationYears != null)
                  Text(
                    '${program.levelLabel} - ${program.durationLabel}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Onglet Admission — conditions + frais
// =============================================================================

class _AdmissionTab extends StatelessWidget {
  final SchoolDetail school;

  const _AdmissionTab({required this.school});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conditions d'admission
          Text(
            'Conditions d\'admission',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              school.admissionRequirements ?? 'Informations non disponibles.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Frais de scolarite
          Text(
            'Frais de scolarite',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.money_2, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fourchette',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                      Text(
                        school.tuitionRange ?? 'Non communique',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// =============================================================================
// Onglet Contact — adresse, tel, email, web cliquables
// =============================================================================

class _ContactTab extends StatelessWidget {
  final SchoolDetail school;

  const _ContactTab({required this.school});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coordonnees',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (school.address != null)
            _ContactItem(
              icon: Iconsax.location,
              label: 'Adresse',
              value: school.address!,
              onTap: null,
            ),
          if (school.phone != null)
            _ContactItem(
              icon: Iconsax.call,
              label: 'Telephone',
              value: school.phone!,
              onTap: () => launchUrl(Uri.parse('tel:${school.phone}')),
            ),
          if (school.email != null)
            _ContactItem(
              icon: Iconsax.sms,
              label: 'Email',
              value: school.email!,
              onTap: () => launchUrl(Uri.parse('mailto:${school.email}')),
            ),
          if (school.website != null)
            _ContactItem(
              icon: Iconsax.global,
              label: 'Site web',
              value: school.website!,
              onTap: () => launchUrl(Uri.parse(school.website!), mode: LaunchMode.externalApplication),
            ),
          if (school.address == null && school.phone == null && school.email == null && school.website == null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Icon(Iconsax.info_circle, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Aucune information de contact disponible', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                  Text(
                    value,
                    style: AppTypography.labelLarge.copyWith(
                      color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Iconsax.arrow_right_3, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
