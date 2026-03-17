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
      create: (context) =>
          getIt<CourseBloc>()..add(LoadCourse(courseId)),
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
          if (state is CourseLoading) {
            return const _DetailShimmer();
          }

          if (state is CourseError && state is! CourseLoaded) {
            return _DetailError(
              message: state.message,
              onRetry: () => context
                  .read<CourseBloc>()
                  .add(LoadCourse(state.message)),
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

          if (course == null) {
            return const _DetailShimmer();
          }

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
            // ── Hero App Bar ──
            _HeroAppBar(course: course, color: color),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      course.title,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meta chips
                    _MetaRow(course: course, color: color),
                    const SizedBox(height: 20),

                    // Description
                    _DescriptionCard(description: course.description),

                    // Progression si inscrit
                    if (course.isEnrolled &&
                        course.progressPct != null) ...[
                      const SizedBox(height: 16),
                      _ProgressSection(
                        progressPct: course.progressPct!,
                        color: color,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Header modules
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Programme',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${course.modules.length} modules',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

            // Espace pour le bouton fixe
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // ── Bouton d'action fixe en bas ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomAction(
            course: course,
            isEnrolling: isEnrolling,
            onEnroll: () => context
                .read<CourseBloc>()
                .add(EnrollCourse(course.id)),
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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
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
        background: course.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: course.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _HeroGradient(color: color, course: course),
                errorWidget: (_, __, ___) =>
                    _HeroGradient(color: color, course: course),
              )
            : _HeroGradient(color: color, course: course),
      ),
    );
  }
}

class _HeroGradient extends StatelessWidget {
  final Color color;
  final CourseDetail course;

  const _HeroGradient({required this.color, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                iconForCategory(course.category),
                size: 32,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                course.category,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _MetaRow({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    final (diffLabel, diffColor) = switch (course.difficulty) {
      CourseDifficulty.debutant => ('Débutant', AppColors.success),
      CourseDifficulty.intermediaire => ('Intermédiaire', AppColors.warning),
      CourseDifficulty.avance => ('Avancé', AppColors.error),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Chip(
          icon: Iconsax.chart_2,
          label: diffLabel,
          color: diffColor,
        ),
        _Chip(
          icon: Iconsax.clock,
          label: '${course.durationMinutes} min',
          color: AppColors.info,
        ),
        _Chip(
          icon: Iconsax.medal_star5,
          label: '${course.pointsReward} pts',
          color: AppColors.secondary,
        ),
        _Chip(
          icon: Iconsax.folder_2,
          label: course.category,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Description Card ─────────────────────────────────────────────────────────

class _DescriptionCard extends StatefulWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.description.length > 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
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
                height: 1.55,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.description,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Voir moins' : 'Voir plus',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int progressPct;
  final Color color;

  const _ProgressSection({
    required this.progressPct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (progressPct / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Iconsax.chart_success,
                      size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Votre progression',
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$progressPct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
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
  final Color color;
  final void Function(LessonSummary lesson) onLessonTap;

  const _ModuleCard({
    required this.module,
    required this.moduleIndex,
    required this.color,
    required this.onLessonTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.module.isLocked;
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.module.isLocked;
    final completedCount = widget.module.lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;
    final totalLessons = widget.module.lessons.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.surface : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? AppColors.border
              : completedCount == totalLessons && totalLessons > 0
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Module header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Numéro du module
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppColors.textTertiary.withValues(alpha: 0.1)
                          : widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLocked
                          ? Icon(Iconsax.lock,
                              size: 16, color: AppColors.textTertiary)
                          : Text(
                              '${widget.moduleIndex + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: widget.color,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLocked
                              ? '$totalLessons leçons'
                              : '$completedCount/$totalLessons complétées',
                          style: AppTypography.labelSmall.copyWith(
                            color: isLocked
                                ? AppColors.textTertiary
                                : completedCount == totalLessons &&
                                        totalLessons > 0
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                            fontWeight: completedCount == totalLessons &&
                                    totalLessons > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5)
                        .animate(_iconController),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
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
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
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

    return InkWell(
      onTap: isAccessible ? onTap : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          lessonIndex == 0 ? 10 : 6,
          14,
          isLast ? 14 : 6,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isInProgress
                        ? color.withValues(alpha: 0.1)
                        : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.3)
                      : isInProgress
                          ? color.withValues(alpha: 0.3)
                          : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isInProgress
                          ? Icons.play_arrow_rounded
                          : Icons.circle,
                  size: isCompleted || isInProgress ? 14 : 6,
                  color: isCompleted
                      ? AppColors.success
                      : isInProgress
                          ? color
                          : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 12),

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
                          isInProgress ? FontWeight.w600 : FontWeight.w500,
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
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        '${lesson.durationMinutes} min',
                        style: AppTypography.labelSmall,
                      ),
                      if (lesson.isFree && isModuleLocked) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Gratuit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
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

            const SizedBox(width: 8),
            Icon(
              isAccessible
                  ? Icons.chevron_right_rounded
                  : Iconsax.lock,
              size: 18,
              color: AppColors.textTertiary,
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
  final VoidCallback onEnroll;

  const _BottomAction({
    required this.course,
    required this.isEnrolling,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (isEnrolling) {
      return Container(
        height: 52,
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

      return GradientButton(
        text: nextLessonId != null ? 'Continuer le cours' : 'Cours terminé',
        icon: nextLessonId != null
            ? Iconsax.play
            : Iconsax.tick_circle,
        showArrow: nextLessonId != null,
        onPressed: nextLessonId != null
            ? () => context.push('/elearning/lesson/$nextLessonId')
            : null,
      );
    }

    return GradientButton(
      text: 'S\'inscrire au cours',
      icon: Iconsax.book_1,
      onPressed: onEnroll,
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 200, color: Colors.white),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  3,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
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
