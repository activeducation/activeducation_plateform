// Partie de lesson_page.dart (refacto : page de 1231 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Corps de la lecon (etat, header, navigation contenu).
part of '../lesson_page.dart';


class _LessonContent extends StatefulWidget {
  final LessonDetail lesson;
  final bool isCompleting;

  const _LessonContent({
    required this.lesson,
    required this.isCompleting,
  });

  @override
  State<_LessonContent> createState() => _LessonContentState();
}

class _LessonContentState extends State<_LessonContent> {
  bool _quizCompleted = false;
  int _quizScore = 0;
  Map<String, String> _quizAnswers = {};

  bool get _canComplete {
    if (widget.lesson.status == LessonStatus.completed) return false;
    if (widget.lesson.lessonType == LessonType.quiz) return _quizCompleted;
    return true;
  }

  void _complete(BuildContext context) {
    if (widget.lesson.lessonType == LessonType.quiz) {
      context.read<LessonBloc>().add(CompleteLesson(
            widget.lesson.id,
            score: _quizScore,
            answers: _quizAnswers,
          ));
    } else {
      context.read<LessonBloc>().add(CompleteLesson(widget.lesson.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.lesson.status == LessonStatus.completed;

    return BlocListener<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonCompleted) {
          try {
            getIt<GamificationCubit>().refresh();
          } catch (_) {}
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          _LessonHeader(
            lesson: widget.lesson,
            isCompleted: isCompleted,
          ),

          // ── Content ──
          Expanded(
            child: _buildContentWidget(context),
          ),

          // ── Bottom action ──
          if (!isCompleted)
            _BottomCompleteButton(
              lessonType: widget.lesson.lessonType,
              canComplete: _canComplete,
              isCompleting: widget.isCompleting,
              onComplete: () => _complete(context),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildContentWidget(BuildContext context) {
    final content = widget.lesson.content;
    final data = content?.data ?? {};

    switch (widget.lesson.lessonType) {
      case LessonType.video:
        return _VideoContent(data: data);
      case LessonType.article:
        return _ArticleContent(data: data);
      case LessonType.quiz:
        if (_quizCompleted) {
          return _QuizCompletedMessage(score: _quizScore);
        }
        final questions = QuizWidget.fromContentData(data);
        if (questions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.message_question,
                      size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'Le quiz sera disponible prochainement.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return QuizWidget(
          questions: questions,
          passScorePct:
              (data['pass_score_pct'] as num?)?.toInt() ?? 60,
          onCompleted: (score, answers) {
            setState(() {
              _quizCompleted = true;
              _quizScore = score;
              _quizAnswers = answers;
            });
          },
        );
      case LessonType.pdf:
        return _PdfContent(data: data);
      case LessonType.challenge:
        return _ChallengeContent(data: data);
    }
  }
}

// ─── Lesson Header ────────────────────────────────────────────────────────────

class _LessonHeader extends StatelessWidget {
  final LessonDetail lesson;
  final bool isCompleted;

  const _LessonHeader({
    required this.lesson,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  LessonTypeBadge(
                    lessonType: lesson.lessonType,
                    compact: false,
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Complété',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Title + meta
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Iconsax.clock,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.durationMinutes} min',
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: 14),
                      Icon(Iconsax.medal_star5,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.pointsReward} pts',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

