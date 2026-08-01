import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../gamification/data/models/gamification_profile.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../domain/entities/course.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';
import '../bloc/saga_bloc.dart';
import '../widgets/course_card.dart' show colorForCategory, iconForCategory;

class SagaPage extends StatelessWidget {
  const SagaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SagaBloc(getIt<GetMyCoursesUsecase>())..add(LoadSaga()),
        ),
        BlocProvider.value(value: getIt<GamificationCubit>()),
      ],
      child: const _SagaView(),
    );
  }
}

class _SagaView extends StatefulWidget {
  const _SagaView();

  @override
  State<_SagaView> createState() => _SagaViewState();
}

class _SagaViewState extends State<_SagaView> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<SagaBloc, SagaState>(
        builder: (context, sagaState) {
          return BlocBuilder<GamificationCubit, GamificationState>(
            builder: (context, gamificationState) {
              final isLoading = sagaState.isLoading ||
                  gamificationState is GamificationLoading;
              final error = sagaState.error;
              final profile = gamificationState is GamificationLoaded
                  ? gamificationState.profile
                  : null;
              final myCourses = sagaState.myCourses;

              if (isLoading && myCourses.isEmpty) {
                return _buildShimmer();
              }

              if (error != null && myCourses.isEmpty) {
                return _ErrorView(
                  message: error,
                  onRetry: () {
                    context.read<SagaBloc>().add(LoadSaga());
                    context.read<GamificationCubit>().load();
                  },
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _HeroSection(profile: profile),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _StatsRow(profile: profile, courseCount: myCourses.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.map_1,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ma progression',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${myCourses.length} cours',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (myCourses.isEmpty)
                    const SliverFillRemaining(
                      child: _EmptySagaState(),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: _MissionMap(courses: myCourses),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ─── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final GamificationProfile? profile;

  const _HeroSection({this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;
    final level = stats?.currentLevel ?? 1;
    final totalXp = stats?.totalXp ?? 0;
    final nextLevelXp = profile?.nextLevelXp ?? 1000;
    final progress = profile?.levelProgress ?? 0;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      floating: false,
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
                  color: Colors.white.withValues(alpha: 0.15),
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Text(
          'Ma Saga',
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
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.xpGoldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.xpGold.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Niveau $level',
                            style: AppTypography.heroTitle.copyWith(
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.xpGold,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalXp / $nextLevelXp XP',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.darkTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final GamificationProfile? profile;
  final int courseCount;

  const _StatsRow({this.profile, required this.courseCount});

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;

    return Row(
      children: [
        _StatTile(
          icon: Iconsax.clock,
          label: 'Streak',
          value: '${stats?.currentStreak ?? 0}j',
          color: AppColors.streakFire,
          bgColor: AppColors.streakFireSurface,
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Iconsax.cup,
          label: 'Succès',
          value: '${stats?.totalAchievements ?? 0}',
          color: AppColors.xpGold,
          bgColor: AppColors.xpGoldSurface,
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Iconsax.book_1,
          label: 'Cours',
          value: '$courseCount',
          color: AppColors.primary,
          bgColor: AppColors.primarySurface,
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Iconsax.ranking_1,
          label: 'Rang',
          value: stats?.leaderboardRank != null
              ? '#${stats!.leaderboardRank}'
              : '—',
          color: AppColors.levelPurple,
          bgColor: AppColors.levelPurpleSurface,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.statValueSmall.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mission Map ───────────────────────────────────────────────────────────────

class _MissionMap extends StatelessWidget {
  final List<Course> courses;

  const _MissionMap({required this.courses});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Course>.from(courses)
      ..sort((a, b) {
        final aPct = a.progressPct ?? 0;
        final bPct = b.progressPct ?? 0;
        return bPct.compareTo(aPct);
      });

    return Column(
      children: [
        for (int i = 0; i < sorted.length; i++) ...[
          _MissionNode(
            course: sorted[i],
            index: i,
            total: sorted.length,
            isFirst: i == 0,
            isLast: i == sorted.length - 1,
          ),
          if (i < sorted.length - 1) _ConnectorLine(isCompleted: (sorted[i].progressPct ?? 0) >= 100),
        ],
      ],
    );
  }
}

class _MissionNode extends StatelessWidget {
  final Course course;
  final int index;
  final int total;
  final bool isFirst;
  final bool isLast;

  const _MissionNode({
    required this.course,
    required this.index,
    required this.total,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final progress = course.progressPct ?? 0;
    final isCompleted = progress >= 100;
    final isInProgress = progress > 0 && !isCompleted;
    final color = colorForCategory(course.category);
    final icon = iconForCategory(course.category);

    return GestureDetector(
      onTap: () => context.push('/elearning/course/${course.id}', extra: course),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                  Container(
                    width: isCompleted ? 28 : 24,
                    height: isCompleted ? 28 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isInProgress
                              ? color
                              : AppColors.border,
                      boxShadow: isInProgress
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isInProgress
                                    ? Colors.white
                                    : AppColors.textTertiary,
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isInProgress ? color.withValues(alpha: 0.3) : AppColors.border,
                    width: isInProgress ? 1.5 : 1,
                  ),
                  boxShadow: isInProgress
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.successLight
                                      : isInProgress
                                          ? color.withValues(alpha: 0.1)
                                          : AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCompleted
                                      ? 'Terminé'
                                      : isInProgress
                                          ? '$progress%'
                                          : 'À commencer',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? AppColors.successDark
                                        : isInProgress
                                            ? color
                                            : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Iconsax.clock,
                                size: 11,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${course.durationMinutes}min',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isInProgress)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    if (isCompleted)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  final bool isCompleted;

  const _ConnectorLine({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 2,
          height: 20,
          decoration: BoxDecoration(
            gradient: isCompleted
                ? const LinearGradient(
                    colors: [AppColors.success, AppColors.success],
                  )
                : LinearGradient(
                    colors: [
                      AppColors.border,
                      AppColors.border.withValues(alpha: 0.4),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptySagaState extends StatelessWidget {
  const _EmptySagaState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.map_1,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun cours en cours',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inscris-toi à un cours pour commencer\nton aventure d\'apprentissage !',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: GradientButton(
                text: 'Explorer les cours',
                showArrow: true,
                onPressed: () => context.go('/elearning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Réessayer',
              showArrow: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
