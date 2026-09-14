// Partie de course_detail_page.dart (refacto : page de 1454 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Cartes de modules et lignes de lecons.
part of '../course_detail_page.dart';

// ─── Gamified Roadmap Nodes ───────────────────────────────────────────────────

class _RoadmapModuleNode extends StatelessWidget {
  final CourseModule module;
  final int index;
  final Color color;

  const _RoadmapModuleNode({
    required this.module,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = module.isLocked;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.surface : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked ? AppColors.border : color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLocked ? AppColors.borderLight : color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Iconsax.lock : Iconsax.star1,
              color: isLocked ? AppColors.textTertiary : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape ${index + 1}',
                  style: TextStyle(
                    color: isLocked ? AppColors.textTertiary : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
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

class _RoadmapLessonNode extends StatelessWidget {
  final LessonSummary lesson;
  final int index;
  final bool isModuleLocked;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _RoadmapLessonNode({
    required this.lesson,
    required this.index,
    required this.isModuleLocked,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAccessible = !isModuleLocked || lesson.isFree;
    final isCompleted = lesson.status == LessonStatus.completed;
    final isInProgress = lesson.status == LessonStatus.in_progress;
    
    final nodeColor = isCompleted ? AppColors.success : (isInProgress ? color : AppColors.border);
    
    // Zig-zag pattern
    final isLeft = index % 2 == 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Connecting Path (CustomPainter could draw a real bezier, here we use simple vertical lines for now)
        if (!isLast)
          Positioned(
            top: 50,
            bottom: -50,
            left: isLeft ? MediaQuery.of(context).size.width * 0.35 : null,
            right: isLeft ? null : MediaQuery.of(context).size.width * 0.35,
            child: Container(
              width: 4,
              color: nodeColor.withValues(alpha: 0.3),
            ),
          ),
          
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!isLeft) const Spacer(flex: 3),
              
              // Node content
              Expanded(
                flex: 7,
                child: GestureDetector(
                  onTap: isAccessible ? onTap : null,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: isLeft ? 40 : 0,
                      right: isLeft ? 0 : 40,
                    ),
                    child: Row(
                      mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (!isLeft) _buildInfo(isLeft),
                        if (!isLeft) const SizedBox(width: 16),
                        
                        // Node Circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAccessible ? nodeColor : AppColors.surface,
                            boxShadow: isAccessible ? [
                              BoxShadow(
                                color: nodeColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ] : null,
                            border: Border.all(
                              color: isAccessible ? Colors.white : AppColors.border,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            _getIcon(),
                            color: isAccessible ? Colors.white : AppColors.textTertiary,
                            size: 28,
                          ),
                        ),
                        
                        if (isLeft) const SizedBox(width: 16),
                        if (isLeft) _buildInfo(isLeft),
                      ],
                    ),
                  ),
                ),
              ),
              
              if (isLeft) const Spacer(flex: 3),
            ],
          ),
        ),
      ],
    );
  }
  
  IconData _getIcon() {
    if (!isModuleLocked && lesson.status == LessonStatus.completed) return Icons.check_rounded;
    if (!isModuleLocked && lesson.status == LessonStatus.in_progress) return Icons.play_arrow_rounded;
    
    switch (lesson.lessonType) {
      case LessonType.video: return Iconsax.video;
      case LessonType.article: return Iconsax.document_text;
      case LessonType.quiz: return Iconsax.task_square;
      default: return Iconsax.document;
    }
  }

  Widget _buildInfo(bool isLeft) {
    final isAccessible = !isModuleLocked || lesson.isFree;
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            lesson.title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isAccessible ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${lesson.durationMinutes} min',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
