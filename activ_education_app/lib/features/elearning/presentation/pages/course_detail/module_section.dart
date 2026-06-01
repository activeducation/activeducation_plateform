// Partie de course_detail_page.dart (refacto : page de 1454 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Cartes de modules et lignes de lecons.
part of '../course_detail_page.dart';

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
