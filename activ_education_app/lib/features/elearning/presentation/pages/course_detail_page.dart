import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
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
                content: const Text('Inscription réussie ! Bonne chance.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                ),
              ),
            );
          }
          if (state is CourseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CourseLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is CourseError && state is! CourseLoaded) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: AppSpacing.iconXl, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text('Erreur: ${state.message}',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    GradientButton(
                      text: 'Réessayer',
                      onPressed: () => context
                          .read<CourseBloc>()
                          .add(LoadCourse(state.message)),
                      showArrow: false,
                      isSmall: true,
                      width: 140,
                    ),
                  ],
                ),
              ),
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return CustomScrollView(
            slivers: [
              _CourseAppBar(course: course),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & badges
                      Text(course.title, style: AppTypography.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      _CourseMetaRow(course: course),
                      const SizedBox(height: AppSpacing.md),

                      // Description in GlassCard
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.xs),
                                Text('Description',
                                    style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              course.description,
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      // Progress bar if enrolled
                      if (course.isEnrolled &&
                          course.progressPct != null) ...[
                        _EnrolledProgressBar(progressPct: course.progressPct!),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // Enroll / Continue button
                      _ActionButton(
                        course: course,
                        isEnrolling: isEnrolling,
                        onEnroll: () => context
                            .read<CourseBloc>()
                            .add(EnrollCourse(course!.id)),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Modules header
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Contenu du cours',
                              style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),

              // Modules list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final module = course!.modules[index];
                    return _ModuleSection(
                      module: module,
                      isLocked: module.isLocked,
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

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.pagePaddingBottom),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseAppBar extends StatelessWidget {
  final CourseDetail course;

  const _CourseAppBar({required this.course});

  LinearGradient _gradientForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('info') || lower.contains('tech')) {
      return AppColors.heroGradient;
    } else if (lower.contains('math')) {
      return const LinearGradient(
          colors: [AppColors.categoryTechnology, AppColors.primaryIndigo]);
    } else if (lower.contains('scien')) {
      return const LinearGradient(
          colors: [AppColors.categoryScience, AppColors.primary]);
    } else if (lower.contains('orient')) {
      return const LinearGradient(
          colors: [AppColors.categoryEconomics, AppColors.successDark]);
    } else if (lower.contains('hack')) {
      return AppColors.secondaryGradient;
    }
    return AppColors.primaryGradient;
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: course.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: course.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: _gradientForCategory(course.category),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: _gradientForCategory(course.category),
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded,
                        size: AppSpacing.iconXxl, color: Colors.white54),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: _gradientForCategory(course.category),
                ),
                child: const Center(
                  child: Icon(Icons.school_rounded,
                      size: AppSpacing.iconXxl, color: Colors.white54),
                ),
              ),
      ),
    );
  }
}

class _CourseMetaRow extends StatelessWidget {
  final CourseDetail course;

  const _CourseMetaRow({required this.course});

  @override
  Widget build(BuildContext context) {
    final (diffLabel, diffColor) = switch (course.difficulty) {
      CourseDifficulty.debutant => ('Débutant', AppColors.success),
      CourseDifficulty.intermediaire => ('Intermédiaire', AppColors.warning),
      CourseDifficulty.avance => ('Avancé', AppColors.error),
    };

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        _MetaChip(
          label: diffLabel,
          color: diffColor,
          icon: Icons.signal_cellular_alt_rounded,
        ),
        _MetaChip(
          label: '${course.durationMinutes} min',
          color: AppColors.info,
          icon: Icons.timer_outlined,
        ),
        _MetaChip(
          label: '${course.pointsReward} pts',
          color: AppColors.secondary,
          icon: Icons.star_rounded,
        ),
        _MetaChip(
          label: course.category,
          color: AppColors.textSecondary,
          icon: Icons.folder_outlined,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MetaChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconXs, color: color),
          const SizedBox(width: AppSpacing.xxxs),
          Text(
            label,
            style:
                AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EnrolledProgressBar extends StatelessWidget {
  final int progressPct;

  const _EnrolledProgressBar({required this.progressPct});

  @override
  Widget build(BuildContext context) {
    final progress = (progressPct / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Votre progression',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              Text('$progressPct%',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: AppSpacing.progressBarHeightLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final CourseDetail course;
  final bool isEnrolling;
  final VoidCallback onEnroll;

  const _ActionButton({
    required this.course,
    required this.isEnrolling,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
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
        text: nextLessonId != null ? 'Continuer' : 'Cours terminé',
        icon: Icons.play_arrow_rounded,
        showArrow: nextLessonId != null,
        onPressed: nextLessonId != null
            ? () => context.push('/elearning/lesson/$nextLessonId')
            : null,
      );
    }

    if (isEnrolling) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GradientButton(
      text: 'S\'inscrire',
      icon: Icons.school_rounded,
      onPressed: onEnroll,
    );
  }
}

class _ModuleSection extends StatefulWidget {
  final CourseModule module;
  final bool isLocked;
  final void Function(LessonSummary lesson) onLessonTap;

  const _ModuleSection({
    required this.module,
    required this.isLocked,
    required this.onLessonTap,
  });

  @override
  State<_ModuleSection> createState() => _ModuleSectionState();
}

class _ModuleSectionState extends State<_ModuleSection> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    // Collapse locked modules by default
    _expanded = !widget.isLocked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.isLocked
            ? AppColors.surface
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: widget.isLocked ? null : AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Module header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: widget.isLocked
                          ? AppColors.textTertiary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadiusSmall),
                    ),
                    child: Icon(
                      widget.isLocked
                          ? Icons.lock_rounded
                          : Icons.folder_open_rounded,
                      size: AppSpacing.iconSm,
                      color: widget.isLocked
                          ? AppColors.textTertiary
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          style: AppTypography.titleSmall.copyWith(
                            color: widget.isLocked
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.module.lessons.length} leçons',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Lessons
          if (_expanded)
            ...widget.module.lessons.map((lesson) => _LessonTile(
                  lesson: lesson,
                  isModuleLocked: widget.isLocked,
                  onTap: () => widget.onLessonTap(lesson),
                )),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonSummary lesson;
  final bool isModuleLocked;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.isModuleLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAccessible = !isModuleLocked || lesson.isFree;
    final isCompleted = lesson.status == LessonStatus.completed;
    final isInProgress = lesson.status == LessonStatus.in_progress;

    return InkWell(
      onTap: isAccessible ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.successLight
                    : isInProgress
                        ? AppColors.primarySurface
                        : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isInProgress
                          ? Icons.play_arrow_rounded
                          : Icons.radio_button_unchecked_rounded,
                  size: AppSpacing.iconSm,
                  color: isCompleted
                      ? AppColors.success
                      : isInProgress
                          ? AppColors.primary
                          : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Lesson info
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Row(
                    children: [
                      LessonTypeBadge(
                        lessonType: lesson.lessonType,
                        compact: false,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.timer_outlined,
                          size: AppSpacing.iconXs,
                          color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.xxxs),
                      Text('${lesson.durationMinutes} min',
                          style: AppTypography.labelSmall),
                      const Spacer(),
                      if (lesson.isFree && isModuleLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Text(
                            'Gratuit',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.xs),
            Icon(
              isAccessible
                  ? Icons.chevron_right_rounded
                  : Icons.lock_rounded,
              size: AppSpacing.iconSm,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
