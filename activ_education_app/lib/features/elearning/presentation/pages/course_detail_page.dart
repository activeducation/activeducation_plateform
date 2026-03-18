import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
import '../widgets/course_card.dart' show colorForCategory, iconForCategory;
import '../widgets/lesson_type_badge.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseId;
  final Course? initialCourse;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    this.initialCourse,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CourseBloc>()..add(LoadCourse(courseId)),
      child: _CourseDetailView(initialCourse: initialCourse),
    );
  }
}

class _CourseDetailView extends StatelessWidget {
  final Course? initialCourse;

  const _CourseDetailView({this.initialCourse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseEnrolled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text('Inscription réussie !'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          if (state is CourseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CourseLoading) return const _DetailShimmer();

          if (state is CourseError && state is! CourseLoaded) {
            return _DetailError(
              message: state.message,
              onRetry: () =>
                  context.read<CourseBloc>().add(LoadCourse(state.message)),
              onBack: () => context.pop(),
            );
          }

          CourseDetail? course;
          bool isEnrolling = false;

          if (state is CourseLoaded) course = state.course;
          if (state is CourseEnrolling) {
            course = state.course;
            isEnrolling = true;
          }
          if (state is CourseEnrolled) course = state.course;

          if (course == null) return const _DetailShimmer();

          return _CourseBody(course: course, isEnrolling: isEnrolling);
        },
      ),
    );
  }
}

// ─── Main Body ────────────────────────────────────────────────────────────────

class _CourseBody extends StatelessWidget {
  final CourseDetail course;
  final bool isEnrolling;

  const _CourseBody({required this.course, required this.isEnrolling});

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(course.category);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Immersive Hero App Bar ──
            _HeroAppBar(course: course, color: color),

            // ── Content ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats strip
                    _StatsStrip(course: course, color: color),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      course.title,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    _DescriptionSection(description: course.description),

                    // Progression si inscrit
                    if (course.isEnrolled && course.progressPct != null) ...[
                      const SizedBox(height: 16),
                      _ProgressBanner(
                        progressPct: course.progressPct!,
                        color: color,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Programme header
                    Row(
                      children: [
                        Text(
                          'Programme',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${course.modules.length} modules',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Modules ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = course.modules[index];
                  return _ModuleCard(
                    module: module,
                    moduleIndex: index,
                    totalModules: course.modules.length,
                    color: color,
                    onLessonTap: (lesson) {
                      if (!module.isLocked || lesson.isFree) {
                        context.push('/elearning/lesson/${lesson.id}');
                      }
                    },
                  );
                },
                childCount: course.modules.length,
              ),
            ),

            // Space for fixed bottom button
            const SliverToBoxAdapter(child: SizedBox(height: 108)),
          ],
        ),

        // ── Fixed bottom action ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomAction(
            course: course,
            isEnrolling: isEnrolling,
            color: color,
            onEnroll: () =>
                context.read<CourseBloc>().add(EnrollCourse(course.id)),
          ),
        ),
      ],
    );
  }
}

// ─── Hero App Bar ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _HeroAppBar({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 248,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: course.thumbnailUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        _HeroBackground(color: color, course: course),
                    errorWidget: (_, _, _) =>
                        _HeroBackground(color: color, course: course),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          AppColors.darkBg.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  _HeroBottomContent(course: course, color: color),
                ],
              )
            : _HeroBackground(color: color, course: course),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final Color color;
  final CourseDetail course;

  const _HeroBackground({required this.color, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBg,
            color.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          _HeroBottomContent(course: course, color: color),
        ],
      ),
    );
  }
}

class _HeroBottomContent extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _HeroBottomContent({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForCategory(course.category),
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      course.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (course.isEnrolled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Inscrit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _StatsStrip({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    final (diffLabel, diffColor) = switch (course.difficulty) {
      CourseDifficulty.debutant => ('Débutant', AppColors.success),
      CourseDifficulty.intermediaire => ('Intermédiaire', AppColors.secondary),
      CourseDifficulty.avance => ('Avancé', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          _StatItem(
            icon: Iconsax.chart_2,
            label: diffLabel,
            color: diffColor,
          ),
          _StatDivider(),
          _StatItem(
            icon: Iconsax.clock,
            label: '${course.durationMinutes} min',
            color: AppColors.textSecondary,
          ),
          _StatDivider(),
          _StatItem(
            icon: Iconsax.medal_star5,
            label: '+${course.pointsReward} XP',
            color: AppColors.xpGoldDark,
            bgColor: AppColors.xpGoldSurface,
          ),
          _StatDivider(),
          _StatItem(
            icon: Iconsax.book_saved,
            label: '${course.modules.length} modules',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Description Section ─────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.description.length > 160;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'À propos',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: Text(
            widget.description,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.description,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Voir moins' : 'Voir plus',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Progress Banner ──────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  final int progressPct;
  final Color color;

  const _ProgressBanner({
    required this.progressPct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (progressPct / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Iconsax.chart_success, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre progression',
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      progressPct == 100
                          ? 'Cours terminé 🎉'
                          : 'Continuez votre apprentissage',
                      style: AppTypography.labelSmall.copyWith(
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$progressPct%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Module Card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatefulWidget {
  final CourseModule module;
  final int moduleIndex;
  final int totalModules;
  final Color color;
  final void Function(LessonSummary lesson) onLessonTap;

  const _ModuleCard({
    required this.module,
    required this.moduleIndex,
    required this.totalModules,
    required this.color,
    required this.onLessonTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.module.isLocked;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.module.isLocked;
    final completedCount = widget.module.lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;
    final totalLessons = widget.module.lessons.length;
    final isComplete = completedCount == totalLessons && totalLessons > 0;
    final moduleColor = isLocked ? AppColors.textTertiary : widget.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.surface : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.3)
              : isLocked
                  ? AppColors.borderLight
                  : AppColors.border,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          // Module header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  // Module number indicator
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withValues(alpha: 0.12)
                          : isLocked
                              ? AppColors.textTertiary.withValues(alpha: 0.08)
                              : moduleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isComplete
                            ? AppColors.success.withValues(alpha: 0.3)
                            : isLocked
                                ? AppColors.border
                                : moduleColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isLocked
                          ? Icon(Iconsax.lock,
                              size: 16, color: AppColors.textTertiary)
                          : isComplete
                              ? Icon(Icons.check_rounded,
                                  size: 18, color: AppColors.success)
                              : Text(
                                  '${widget.moduleIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: moduleColor,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          style: AppTypography.titleSmall.copyWith(
                            color: isLocked
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              isLocked
                                  ? '$totalLessons leçons'
                                  : '$completedCount/$totalLessons complétées',
                              style: AppTypography.labelSmall.copyWith(
                                color: isComplete
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                                fontWeight: isComplete
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            if (!isLocked && !isComplete && totalLessons > 0) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: completedCount / totalLessons,
                                    minHeight: 3,
                                    backgroundColor:
                                        moduleColor.withValues(alpha: 0.1),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(moduleColor),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lessons
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(
                  height: 1,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                ...widget.module.lessons.asMap().entries.map(
                      (entry) => _LessonRow(
                        lesson: entry.value,
                        lessonIndex: entry.key,
                        isModuleLocked: isLocked,
                        color: widget.color,
                        isLast:
                            entry.key == widget.module.lessons.length - 1,
                        onTap: () => widget.onLessonTap(entry.value),
                      ),
                    ),
              ],
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// ─── Lesson Row ───────────────────────────────────────────────────────────────

class _LessonRow extends StatelessWidget {
  final LessonSummary lesson;
  final int lessonIndex;
  final bool isModuleLocked;
  final Color color;
  final bool isLast;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.lessonIndex,
    required this.isModuleLocked,
    required this.color,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAccessible = !isModuleLocked || lesson.isFree;
    final isCompleted = lesson.status == LessonStatus.completed;
    final isInProgress = lesson.status == LessonStatus.in_progress;

    final statusColor = isCompleted
        ? AppColors.success
        : isInProgress
            ? color
            : AppColors.border;

    return InkWell(
      onTap: isAccessible ? onTap : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          lessonIndex == 0 ? 6 : 2,
          14,
          isLast ? 10 : 2,
        ),
        child: Row(
          children: [
            // Left status bar
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.only(left: 14, right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Status icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isInProgress
                        ? color.withValues(alpha: 0.1)
                        : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isInProgress
                          ? Icons.play_arrow_rounded
                          : Icons.circle,
                  size: isCompleted || isInProgress ? 15 : 6,
                  color: isCompleted
                      ? AppColors.success
                      : isInProgress
                          ? color
                          : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isAccessible
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight:
                          isInProgress ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      LessonTypeBadge(
                        lessonType: lesson.lessonType,
                        compact: false,
                      ),
                      const SizedBox(width: 8),
                      Icon(Iconsax.clock,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        '${lesson.durationMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (lesson.isFree && isModuleLocked) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Gratuit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
            Icon(
              isAccessible ? Icons.chevron_right_rounded : Iconsax.lock,
              size: 18,
              color: isAccessible ? AppColors.textTertiary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Action ────────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final CourseDetail course;
  final bool isEnrolling;
  final Color color;
  final VoidCallback onEnroll;

  const _BottomAction({
    required this.course,
    required this.isEnrolling,
    required this.color,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: _buildButton(context)),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (isEnrolling) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (course.isEnrolled) {
      String? nextLessonId;
      outer:
      for (final module in course.modules) {
        if (module.isLocked) continue;
        for (final lesson in module.lessons) {
          if (lesson.status != LessonStatus.completed) {
            nextLessonId = lesson.id;
            break outer;
          }
        }
      }

      return Row(
        children: [
          if (nextLessonId != null && course.progressPct != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${course.progressPct}% complété',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ((course.progressPct ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GradientButton(
              text: nextLessonId != null ? 'Continuer' : 'Cours terminé ✓',
              icon: nextLessonId != null ? Iconsax.play : Iconsax.tick_circle,
              showArrow: nextLessonId != null,
              onPressed: nextLessonId != null
                  ? () => context.push('/elearning/lesson/$nextLessonId')
                  : null,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'S\'inscrire gratuitement',
                icon: Iconsax.book_1,
                onPressed: onEnroll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.medal_star5,
                size: 13, color: AppColors.xpGoldDark),
            const SizedBox(width: 4),
            Text(
              'Gagnez +${course.pointsReward} XP en terminant ce cours',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.xpGoldDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark hero shimmer
        Container(height: 248, color: AppColors.darkBg2),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats strip
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    3,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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

// ─── Detail Error ─────────────────────────────────────────────────────────────

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _DetailError({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
      ),
      body: Center(
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
                'Impossible de charger le cours',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
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
      ),
    );
  }
}
