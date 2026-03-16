import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
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
  String _selectedCategory = 'Tous';

  static const _categories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Orientation',
    'Hackathons',
  ];

  List<Course> _filterCourses(List<Course> courses) {
    if (_selectedCategory == 'Tous') return courses;
    return courses
        .where((c) =>
            c.category.toLowerCase().contains(_selectedCategory.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'E-Learning',
          style: AppTypography.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _CategoryFilterBar(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) =>
                setState(() => _selectedCategory = cat),
          ),
        ),
      ),
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          if (state is CatalogLoading) {
            return _ShimmerLoading();
          }

          if (state is CatalogError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<CatalogBloc>().add(LoadCatalog()),
            );
          }

          if (state is CatalogLoaded) {
            final filteredCourses = _filterCourses(state.courses);
            return CustomScrollView(
              slivers: [
                // My Courses section
                if (state.myCourses.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePaddingHorizontal,
                        AppSpacing.md,
                        AppSpacing.pagePaddingHorizontal,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        'Mes cours',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePaddingHorizontal,
                        ),
                        itemCount: state.myCourses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                ],

                // All courses section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingHorizontal,
                      AppSpacing.xs,
                      AppSpacing.pagePaddingHorizontal,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tous les cours',
                          style: AppTypography.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${filteredCourses.length} cours',
                          style: AppTypography.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid of courses
                if (filteredCourses.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: AppSpacing.iconXl,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Aucun cours dans cette catégorie',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingHorizontal,
                      0,
                      AppSpacing.pagePaddingHorizontal,
                      AppSpacing.pagePaddingBottom,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
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

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingHorizontal,
          vertical: AppSpacing.xs,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(cat),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: AppTypography.chipText.copyWith(
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 0,
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Section title placeholder
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Grid placeholders
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppSpacing.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Une erreur est survenue',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
