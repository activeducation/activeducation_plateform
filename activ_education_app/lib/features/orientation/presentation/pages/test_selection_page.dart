import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/orientation_test.dart';
import '../bloc/orientation_bloc.dart';

class TestSelectionPage extends StatelessWidget {
  const TestSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OrientationBloc>()..add(LoadOrientationTests()),
      child: const _TestSelectionView(),
    );
  }
}

class _TestSelectionView extends StatelessWidget {
  const _TestSelectionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests d\'Orientation'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: BlocBuilder<OrientationBloc, OrientationState>(
          builder: (context, state) {
            if (state is OrientationLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrientationError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else if (state is OrientationTestsLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingHorizontal,
                  AppSpacing.appBarHeight + AppSpacing.md,
                  AppSpacing.pagePaddingHorizontal,
                  AppSpacing.pagePaddingBottom,
                ),
                itemCount: state.tests.length,
                itemBuilder: (context, index) {
                  return _TestCard(test: state.tests[index]);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final OrientationTest test;

  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardMargin),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigation vers la page de test
            context.push('/orientation/test', extra: test);
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: AppColors.primary,
                        size: AppSpacing.iconLg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.name,
                            style: AppTypography.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: AppSpacing.iconXs,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                '${test.durationMinutes} min',
                                style: AppTypography.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  test.description,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
             // Navigation vers la page de test
            context.push('/orientation/test', extra: test);
                    },
                    child: const Text('COMMENCER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
