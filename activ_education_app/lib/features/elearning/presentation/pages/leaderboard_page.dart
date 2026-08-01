import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../gamification/data/models/gamification_profile.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../gamification/data/repositories/gamification_repository.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => _LeaderboardCubit(
            getIt<GamificationRepository>(),
          )..load(),
        ),
        BlocProvider.value(value: getIt<GamificationCubit>()),
      ],
      child: const _LeaderboardView(),
    );
  }
}

// ─── Simple Cubit for leaderboard data ─────────────────────────────────────────

class _LeaderboardCubit extends Cubit<_LeaderboardState> {
  final GamificationRepository _repository;

  _LeaderboardCubit(this._repository) : super(const _LeaderboardState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final entries = await _repository.getLeaderboard(limit: 50);
      emit(state.copyWith(isLoading: false, entries: entries));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

class _LeaderboardState extends Equatable {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;

  const _LeaderboardState({
    this.entries = const [],
    this.isLoading = true,
    this.error,
  });

  _LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return _LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading, error];
}

// ─── View ──────────────────────────────────────────────────────────────────────

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<_LeaderboardCubit, _LeaderboardState>(
        builder: (context, lbState) {
          if (lbState.isLoading && lbState.entries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (lbState.error != null && lbState.entries.isEmpty) {
            return _ErrorView(
              message: lbState.error!,
              onRetry: () => context.read<_LeaderboardCubit>().load(),
            );
          }

          final entries = lbState.entries;
          final podium = entries.length >= 3 ? entries.sublist(0, 3) : entries;
          final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero App Bar ──
              SliverAppBar(
                expandedHeight: 130,
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
                    'Classement',
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Iconsax.ranking_1,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${entries.length} participants',
                                    style: AppTypography.heroTitle.copyWith(
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Les meilleurs apprenants',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkTextSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Podium ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _Podium(entries: podium),
                ),
              ),

              // ── User rank card (from gamification cubit) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: BlocBuilder<GamificationCubit, GamificationState>(
                    builder: (context, gState) {
                      if (gState is! GamificationLoaded) {
                        return const SizedBox.shrink();
                      }
                      final rank = gState.profile.stats.leaderboardRank;
                      final xp = gState.profile.stats.totalXp;
                      final level = gState.profile.stats.currentLevel;
                      if (rank == null) {
                        return const SizedBox.shrink();
                      }
                      return _UserRankCard(
                        rank: rank,
                        xp: xp,
                        level: level,
                      );
                    },
                  ),
                ),
              ),

              // ── Leaderboard List Header ──
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Classement général',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${rest.length + podium.length} participants',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── List header row ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Participant',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'NIV.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'XP',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Leaderboard list items ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = rest[index];
                      final rank = index + 4;
                      return _LeaderboardRow(
                        rank: rank,
                        entry: entry,
                      );
                    },
                    childCount: rest.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Order: 2nd (left), 1st (center), 3rd (right) for proper podium layout
    final second = entries.length > 1 ? entries[1] : null;
    final first = entries.isNotEmpty ? entries[0] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          if (second != null)
            _PodiumTile(
              entry: second,
              rank: 2,
              color: AppColors.rankSilver,
              height: 100,
            ),
          const SizedBox(width: 12),
          // 1st place
          if (first != null)
            _PodiumTile(
              entry: first,
              rank: 1,
              color: AppColors.rankGold,
              height: 130,
              isFirst: true,
            ),
          const SizedBox(width: 12),
          // 3rd place
          if (third != null)
            _PodiumTile(
              entry: third,
              rank: 3,
              color: AppColors.rankBronze,
              height: 80,
            ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Color color;
  final double height;
  final bool isFirst;

  const _PodiumTile({
    required this.entry,
    required this.rank,
    required this.color,
    required this.height,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isFirst ? 52 : 42,
            height: isFirst ? 52 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                _initials(entry.displayName),
                style: TextStyle(
                  fontSize: isFirst ? 18 : 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.displayName.split(' ').first,
            style: AppTypography.labelSmall.copyWith(
              fontSize: isFirst ? 11 : 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Niv. ${entry.currentLevel}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: isFirst ? 44 : 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.4),
                  color.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isFirst ? 10 : 8),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isFirst ? 16 : 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── User Rank Card ────────────────────────────────────────────────────────────

class _UserRankCard extends StatelessWidget {
  final int rank;
  final int xp;
  final int level;

  const _UserRankCard({
    required this.rank,
    required this.xp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primarySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon classement',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Niveau $level · $xp XP',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.xpGoldSurface
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rank <= 3
                      ? Icons.emoji_events_rounded
                      : rank <= 10
                          ? Icons.local_fire_department_rounded
                          : Icons.fitness_center_rounded,
                  size: 12,
                  color: rank <= 3
                      ? AppColors.xpGoldDark
                      : AppColors.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  rank <= 3
                      ? 'Top 3'
                      : rank <= 10
                          ? 'Top 10'
                          : '$rank/${rank + 50}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3
                        ? AppColors.xpGoldDark
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final medalColor = rank == 1
        ? AppColors.rankGold
        : rank == 2
            ? AppColors.rankSilver
            : rank == 3
                ? AppColors.rankBronze
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medalColor?.withValues(alpha: 0.3) ?? AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: medalColor != null
                ? Icon(
                    Icons.emoji_events_rounded,
                    size: rank == 1 ? 18 : 14,
                    color: medalColor,
                  )
                : Text(
                    '$rank',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _avatarColor(entry.displayName),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _initials(entry.displayName),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              entry.displayName,
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.levelPurpleSurface,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${entry.currentLevel}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.levelPurple,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '${entry.totalXp}',
              textAlign: TextAlign.right,
              style: AppTypography.statValueSmall.copyWith(
                fontSize: 13,
                color: AppColors.xpGoldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.levelPurple,
      AppColors.categoryScience,
      AppColors.categoryTechnology,
      AppColors.categoryEconomics,
    ];
    return colors[name.hashCode.abs() % colors.length];
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
