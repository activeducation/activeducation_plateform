import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../domain/entities/course.dart';
import '../bloc/lesson_bloc.dart';
import '../widgets/lesson_type_badge.dart';
import '../widgets/quiz_widget.dart';

class LessonPage extends StatelessWidget {
  final String lessonId;

  const LessonPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<LessonBloc>()..add(LoadLesson(lessonId)),
      child: const _LessonView(),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonError) {
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
        if (state is LessonLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (state is LessonError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
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
                      child: const Icon(Iconsax.warning_2,
                          size: 32, color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is LessonCompleted) {
          return _LessonCompletedView(
            pointsEarned: state.pointsEarned,
            courseProgressPct: state.courseProgressPct,
            onBack: () => context.pop(),
          );
        }

        LessonDetail? lesson;
        bool isCompleting = false;

        if (state is LessonLoaded) lesson = state.lesson;
        if (state is LessonCompleting) {
          lesson = state.lesson;
          isCompleting = true;
        }

        if (lesson == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _LessonContent(
          lesson: lesson,
          isCompleting: isCompleting,
        );
      },
    );
  }
}

// ─── Lesson Content ───────────────────────────────────────────────────────────

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

    return Scaffold(
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

// ─── Content Types ────────────────────────────────────────────────────────────

class _VideoContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VideoContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final videoUrl = data['url'] as String? ?? data['video_url'] as String?;
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoUrl != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.heroGradient,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DotPatternPainter(),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GradientButton(
                          text: 'Lire la vidéo',
                          icon: Iconsax.export_1,
                          isSmall: true,
                          width: 170,
                          showArrow: false,
                          useSecondaryColor: true,
                          onPressed: () async {
                            final uri = Uri.tryParse(videoUrl);
                            if (uri != null &&
                                await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (description.isNotEmpty) ...[
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
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],
        ],
      ),
    );
  }
}

class _ArticleContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ArticleContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final content = data['content'] as String? ??
        data['body'] as String? ??
        data['text'] as String? ??
        'Contenu non disponible.';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: _SimpleMarkdown(content: content),
      ),
    );
  }
}

class _PdfContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PdfContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final pdfUrl =
        data['url'] as String? ?? data['pdf_url'] as String? ?? '';
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.document,
                      size: 28, color: AppColors.error),
                ),
                const SizedBox(height: 14),
                Text(
                  'Document PDF',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.errorDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                if (pdfUrl.isNotEmpty)
                  GradientButton(
                    text: 'Ouvrir le PDF',
                    icon: Iconsax.export_1,
                    showArrow: false,
                    isSmall: true,
                    width: 170,
                    onPressed: () async {
                      final uri = Uri.tryParse(pdfUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                else
                  Text(
                    'PDF non disponible.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],
        ],
      ),
    );
  }
}

class _ChallengeContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChallengeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';
    final objectives = (data['objectives'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final submissionUrl =
        data['submission_url'] as String? ?? data['url'] as String?;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.categoryTechnology,
                  AppColors.primaryIndigo,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.cup,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Challenge',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.categoryTechnology,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],

          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.categoryTechnology,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Objectifs',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...objectives.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.categoryTechnology
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.categoryTechnology,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            entry.value,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (submissionUrl != null) ...[
            const SizedBox(height: 24),
            GradientButton(
              text: 'Soumettre ma solution',
              icon: Iconsax.export_1,
              onPressed: () async {
                final uri = Uri.tryParse(submissionUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Simple Markdown ──────────────────────────────────────────────────────────

class _SimpleMarkdown extends StatelessWidget {
  final String content;

  const _SimpleMarkdown({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            line.substring(2),
            style: AppTypography.headlineSmall.copyWith(
              letterSpacing: -0.3,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: Text(
            line.substring(3),
            style: AppTypography.titleLarge.copyWith(
              letterSpacing: -0.2,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 2),
          child: Text(
            line.substring(4),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _InlineText(text: line.substring(2)),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _InlineText(text: line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _InlineText extends StatelessWidget {
  final String text;

  const _InlineText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: AppTypography.bodyMedium.copyWith(height: 1.6),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: AppTypography.bodyMedium.copyWith(height: 1.6),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ─── Bottom Complete Button ───────────────────────────────────────────────────

class _BottomCompleteButton extends StatelessWidget {
  final LessonType lessonType;
  final bool canComplete;
  final bool isCompleting;
  final VoidCallback onComplete;

  const _BottomCompleteButton({
    required this.lessonType,
    required this.canComplete,
    required this.isCompleting,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isQuiz = lessonType == LessonType.quiz;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: isCompleting
              ? Container(
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
                )
              : GradientButton(
                  text: isQuiz && !canComplete
                      ? 'Terminez le quiz d\'abord'
                      : 'Valider cette leçon',
                  icon: isQuiz
                      ? Iconsax.tick_circle
                      : Iconsax.verify,
                  onPressed: canComplete ? onComplete : null,
                  showArrow: false,
                ),
        ),
      ),
    );
  }
}

// ─── Lesson Completed ─────────────────────────────────────────────────────────

class _LessonCompletedView extends StatelessWidget {
  final int pointsEarned;
  final int? courseProgressPct;
  final VoidCallback onBack;

  const _LessonCompletedView({
    required this.pointsEarned,
    this.courseProgressPct,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.cup,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Leçon validée !',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Points card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.medal_star5,
                            color: AppColors.secondary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '+$pointsEarned points',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (courseProgressPct != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression du cours',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$courseProgressPct%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (courseProgressPct! / 100).clamp(0.0, 1.0),
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              GradientButton(
                text: 'Retour au cours',
                icon: Iconsax.arrow_left_2,
                showArrow: false,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quiz Completed Message ───────────────────────────────────────────────────

class _QuizCompletedMessage extends StatelessWidget {
  final int score;

  const _QuizCompletedMessage({required this.score});

  @override
  Widget build(BuildContext context) {
    final passed = score >= 60;
    final resultColor = passed ? AppColors.success : AppColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Iconsax.cup : Iconsax.refresh,
                size: 36,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz terminé',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score : $score%',
              style: AppTypography.titleMedium.copyWith(
                color: resultColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Validez la leçon pour enregistrer votre résultat.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot Pattern Painter (for video bg) ───────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
