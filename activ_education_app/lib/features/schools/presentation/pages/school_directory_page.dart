import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/inputs/custom_search_bar.dart';
import '../../../../shared/widgets/inputs/filter_chip_bar.dart';
import '../../data/models/school_model.dart';
import '../../data/repositories/school_repository.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../widgets/school_card.dart';
import '../widgets/school_badge.dart';
import '../widgets/description_tab.dart';
import '../widgets/filieres_tab.dart';
import '../widgets/admission_tab.dart';
import '../widgets/contact_tab.dart';

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
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
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
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: AppTypography.labelSmall.copyWith(letterSpacing: 1),
                children: [
                  TextSpan(
                    text: 'ACTIV ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'EDUCATION',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.wifi_square,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                text: 'Reessayer',
                onPressed: _loadSchools,
                isSmall: true,
              ),
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
            Text(
              'Aucune ecole trouvee',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSchools,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingHorizontal,
        ),
        itemCount: _schools.length,
        itemBuilder: (context, index) {
          return SchoolCard(
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

class _SchoolDetailPageState extends State<SchoolDetailPage>
    with SingleTickerProviderStateMixin {
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GradientButton(
                    text: 'Reessayer',
                    onPressed: _loadDetail,
                    isSmall: true,
                  ),
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
              child: const Icon(
                Iconsax.arrow_left,
                color: Colors.white,
                size: 20,
              ),
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
                child: const Icon(
                  Iconsax.export_2,
                  color: Colors.white,
                  size: 20,
                ),
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
            background:
                school.coverImageUrl != null && school.coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: school.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.primary,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Iconsax.building_4,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
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
                      child: Icon(
                        Iconsax.building_4,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePaddingHorizontal,
                  ),
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
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child:
                            school.logoUrl != null && school.logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: school.logoUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Iconsax.building,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              )
                            : const Icon(
                                Iconsax.building,
                                color: AppColors.primary,
                                size: 32,
                              ),
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
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          SchoolBadge(
                            label: school.isPublic
                                ? 'Etablissement Public'
                                : 'Etablissement Prive',
                            color: school.isPublic
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          ...school.accreditations.map(
                            (acc) => SchoolBadge(
                              label: acc,
                              color: AppColors.success,
                            ),
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
                    DescriptionTab(school: school),
                    FilieresTab(school: school),
                    AdmissionTab(school: school),
                    ContactTab(school: school),
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
