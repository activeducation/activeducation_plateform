import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
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
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LessonLoading) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is LessonError) {
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
                  Text(state.message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center),
                ],
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
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            LessonTypeBadge(
              lessonType: widget.lesson.lessonType,
              compact: false,
            ),
          ],
        ),
        actions: [
          if (isCompleted)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: AppSpacing.xxxs),
                  Text(
                    'Complété',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Lesson title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            color: AppColors.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.lesson.title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xxxs),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: AppSpacing.iconXs,
                        color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.xxxs),
                    Text('${widget.lesson.durationMinutes} min',
                        style: AppTypography.labelSmall),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.star_rounded,
                        size: AppSpacing.iconXs,
                        color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.xxxs),
                    Text(
                      '${widget.lesson.pointsReward} pts',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content area
          Expanded(
            child: _buildContentWidget(context),
          ),

          // Bottom action
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Le quiz sera disponible prochainement.',
                textAlign: TextAlign.center,
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

// ─── Content Type Widgets ──────────────────────────────────────────────────────

class _VideoContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VideoContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final videoUrl = data['url'] as String? ?? data['video_url'] as String?;
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoUrl != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(videoUrl);
                            if (uri != null &&
                                await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Ouvrir la vidéo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (description.isNotEmpty) ...[
            Text('Description', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    size: AppSpacing.iconXxl, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text('Document PDF',
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.errorDark)),
                const SizedBox(height: AppSpacing.md),
                if (pdfUrl.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(pdfUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ouvrir le PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Text('PDF non disponible.',
                      style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Description', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: AppSpacing.iconXxl, color: Colors.white),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Challenge',
                  style: AppTypography.titleMedium
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Description', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            _SimpleMarkdown(content: description),
          ],

          if (objectives.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Objectifs', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...objectives.map((obj) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: AppSpacing.iconSm,
                          color: Color(0xFF7C3AED)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(obj,
                            style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                )),
          ],

          if (submissionUrl != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(submissionUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Soumettre ma solution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Simple Markdown-like text renderer ───────────────────────────────────────

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
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(line.substring(2), style: AppTypography.headlineSmall),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(line.substring(3), style: AppTypography.titleLarge),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
          child: Text(line.substring(4), style: AppTypography.titleMedium),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.primary)),
              Expanded(
                child: _InlineText(text: line.substring(2)),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.xs));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
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
    // Parse **bold** inline
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: AppTypography.bodyMedium,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: AppTypography.bodyMedium,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ─── Bottom Complete Button ────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (canComplete && !isCompleting) ? onComplete : null,
            icon: isCompleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    isQuiz
                        ? Icons.check_circle_rounded
                        : Icons.done_all_rounded,
                  ),
            label: Text(
              isCompleting
                  ? 'Validation...'
                  : isQuiz && !canComplete
                      ? 'Terminez le quiz d\'abord'
                      : 'Valider cette leçon',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.border,
              disabledForegroundColor:
                  AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lesson Completed Screen ───────────────────────────────────────────────────

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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation placeholder
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Leçon validée !',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Points earned
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadiusLarge),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondary,
                        size: AppSpacing.iconLg),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+$pointsEarned points gagnés !',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Course progress
              if (courseProgressPct != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Progression du cours : $courseProgressPct%',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: LinearProgressIndicator(
                    value: (courseProgressPct! / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success),
                    minHeight: AppSpacing.progressBarHeightLarge,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour au cours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCompletedMessage extends StatelessWidget {
  final int score;

  const _QuizCompletedMessage({required this.score});

  @override
  Widget build(BuildContext context) {
    final passed = score >= 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed
                  ? Icons.emoji_events_rounded
                  : Icons.sentiment_neutral_rounded,
              size: AppSpacing.iconXxl,
              color: passed ? AppColors.secondary : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Quiz complété !',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Score : $score%',
              style: AppTypography.bodyLarge.copyWith(
                color: passed ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cliquez sur "Valider cette leçon" pour confirmer.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
