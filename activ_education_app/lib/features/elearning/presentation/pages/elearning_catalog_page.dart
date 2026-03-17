import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/inputs/filter_chip_bar.dart';
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
  int _selectedIndex = 0;

  static const _categories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Orientation',
    'Hackathons',
  ];

  List<Course> _filterCourses(List<Course> courses) {
    if (_selectedIndex == 0) return courses;
    final category = _categories[_selectedIndex];
    return courses
        .where((c) =>
            c.category.toLowerCase().contains(category.toLowerCase()))
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
                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingHorizontal,
                      AppSpacing.md,
                      AppSpacing.pagePaddingHorizontal,
                      AppSpacing.sm,
                    ),
                    child: FilterChipBar(
                      filters: _categories
                          .map((c) => FilterChipItem(label: c))
                          .toList(),
                      selectedIndex: _selectedIndex,
                      onSelected: (index) =>
                          setState(() => _selectedIndex = index),
                    ),
                  ),
                ),

                // My Courses section
                if (state.myCourses.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePaddingHorizontal,
                        AppSpacing.md,
                        AppSpacing.pagePaddingHorizontal,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'Mes cours',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePaddingHorizontal,
                        ),
                        itemCount: state.myCourses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
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
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tous les cours',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filteredCourses.length} cours',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid of courses
                if (filteredCourses.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
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
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            GradientButton(
                              text: 'Voir tous les cours',
                              isSmall: true,
                              width: 200,
                              showArrow: false,
                              onPressed: () =>
                                  setState(() => _selectedIndex = 0),
                            ),
                          ],
                        ),
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
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
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
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              text: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
