import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../domain/entities/course.dart';
import '../bloc/catalog_bloc.dart';
import '../widgets/course_card.dart';

class ElearningCatalogPage extends StatelessWidget {
  const ElearningCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CatalogBloc>()..add(LoadCatalog()),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView();

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  int _selectedCategoryIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchFocused = false;

  static const _categories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Orientation',
    'Hackathons',
  ];

  static const _categoryIcons = <IconData>[
    Iconsax.element_4,
    Iconsax.monitor,
    Iconsax.math,
    Iconsax.discover_1,
    Iconsax.routing_2,
    Iconsax.code,
  ];

  static const _categoryColors = <Color>[
    AppColors.secondary,           // Tous → orange logo
    AppColors.primary,             // Informatique → bleu logo
    AppColors.categoryTechnology,  // Mathématiques
    AppColors.categoryScience,     // Sciences
    AppColors.categoryEconomics,   // Orientation
    Color(0xFF1060CF),             // Hackathons → bleu accent logo
  ];

  List<Course> _filterCourses(List<Course> courses) {
    var filtered = courses;
    if (_selectedCategoryIndex > 0) {
      final category = _categories[_selectedCategoryIndex];
      filtered = filtered
          .where((c) => c.category.toLowerCase().contains(category.toLowerCase()))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          if (state is CatalogLoading) return const _ShimmerLoading();

          if (state is CatalogError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<CatalogBloc>().add(LoadCatalog()),
            );
          }

          if (state is CatalogLoaded) {
            final filteredCourses = _filterCourses(state.courses);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Hero App Bar ──
                SliverAppBar(
                  expandedHeight: 156,
                  pinned: true,
                  floating: false,
                  snap: false,
                  backgroundColor: AppColors.primary,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: GoRouter.of(context).canPop()
                      ? IconButton(
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => context.pop(),
                        )
                      : null,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.book_1, size: 13, color: AppColors.secondary),
                          const SizedBox(width: 5),
                          Text(
                            '${state.courses.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                    title: Text(
                      'E-Learning',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFF1060CF)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative orbs
                          Positioned(
                            top: -24,
                            right: -20,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -16,
                            left: -16,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary.withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                          // Content
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Iconsax.book_1,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Bibliothèque',
                                        style: AppTypography.heroTitle.copyWith(
                                          fontSize: 20,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.myCourses.isNotEmpty
                                            ? '${state.myCourses.length} en cours · ${state.courses.length} disponibles'
                                            : '${state.courses.length} cours disponibles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.myCourses.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.xpGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.xpGold.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 13)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${state.myCourses.length}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.xpGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Search Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _searchFocused
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                          width: _searchFocused ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _searchFocused
                                ? AppColors.primary.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Focus(
                        onFocusChange: (v) => setState(() => _searchFocused = v),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un cours...',
                            hintStyle: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textTertiary),
                            prefixIcon: Icon(
                              Iconsax.search_normal_1,
                              size: 18,
                              color: _searchFocused
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.textTertiary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Category chips ──
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedCategoryIndex;
                        final catColor = _categoryColors[index];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategoryIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? catColor : AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected ? catColor : AppColors.border,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: catColor.withValues(alpha: 0.30),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcons[index],
                                  size: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _categories[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 26)),

                // ── Mes cours (section horizontale) ──
                if (state.myCourses.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _SectionTitle(
                        title: 'Continuer',
                        badge: '${state.myCourses.length}',
                        icon: Iconsax.play_cricle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.myCourses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final course = state.myCourses[index];
                          return CourseCard(
                            course: course,
                            mode: CourseCardMode.compact,
                            onTap: () => context.push(
                              '/elearning/course/${course.id}',
                              extra: course,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],

                // ── Catalogue section header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        _SectionTitle(
                          title: _selectedCategoryIndex == 0
                              ? 'Tous les cours'
                              : _categories[_selectedCategoryIndex],
                          icon: Iconsax.book_1,
                          color: AppColors.secondary,
                        ),
                        const Spacer(),
                        Text(
                          '${filteredCourses.length} cours',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Grille de cours ──
                if (filteredCourses.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      query: _searchQuery,
                      onReset: () => setState(() {
                        _selectedCategoryIndex = 0;
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = filteredCourses[index];
                          return CourseCard(
                            course: course,
                            mode: CourseCardMode.full,
                            onTap: () => context.push(
                              '/elearning/course/${course.id}',
                              extra: course,
                            ),
                          );
                        },
                        childCount: filteredCourses.length,
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? badge;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    this.badge,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onReset;

  const _EmptyState({required this.query, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                query.isNotEmpty ? Iconsax.search_status : Iconsax.book,
                size: 32,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty ? 'Aucun résultat' : 'Aucun cours disponible',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.isNotEmpty
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Revenez plus tard pour découvrir de nouveaux cours',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Réinitialiser',
              isSmall: true,
              width: 160,
              showArrow: false,
              icon: Iconsax.refresh,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer Loading ──────────────────────────────────────────────────────────

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero shimmer
        Container(
          height: 156,
          color: AppColors.primary,
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 130,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Réessayer',
              icon: Iconsax.refresh,
              showArrow: false,
              isSmall: true,
              width: 160,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
