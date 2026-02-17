import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/orientation_test.dart';
import '../bloc/orientation_bloc.dart';
import '../bloc/test_session_bloc.dart';

class TestExecutionPage extends StatelessWidget {
  final OrientationTest test;

  const TestExecutionPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TestSessionBloc()..add(StartTestSession(test)),
        ),
        BlocProvider(
          create: (context) => getIt<OrientationBloc>(),
        ),
      ],
      child: const _TestExecutionView(),
    );
  }
}

class _TestExecutionView extends StatelessWidget {
  const _TestExecutionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showQuitDialog(context),
        ),
        title: BlocBuilder<TestSessionBloc, TestSessionState>(
          builder: (context, state) {
            if (state is TestSessionInProgress) {
              return Column(
                children: [
                  Text(
                    'Question ${state.currentQuestionIndex + 1}/${state.test.questions.length}',
                    style: AppTypography.titleMedium,
                  ),
                  if (state.sections.length > 1)
                    Text(
                      state.currentSection.title,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: BlocBuilder<TestSessionBloc, TestSessionState>(
            builder: (context, state) {
              if (state is TestSessionInProgress) {
                return _SegmentedProgressBar(
                  sections: state.sections,
                  currentIndex: state.currentQuestionIndex,
                  totalQuestions: state.test.questions.length,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: BlocConsumer<TestSessionBloc, TestSessionState>(
          listener: (context, state) {
            if (state is TestSessionReadyToSubmit) {
              context.read<OrientationBloc>().add(
                    SubmitTestEvent(state.test.id, state.responses),
                  );
            }
          },
          builder: (context, state) {
            return BlocListener<OrientationBloc, OrientationState>(
              listener: (context, state) {
                if (state is TestCompleted) {
                  context.pushReplacement('/orientation/results', extra: state.result);
                } else if (state is OrientationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${state.message}')),
                  );
                }
              },
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TestSessionState state) {
    if (state is TestSessionInProgress) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppSpacing.animationNormal,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _QuestionCard(
                    key: ValueKey(state.currentQuestionIndex),
                    question: state.currentQuestion,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.canGoBack)
                    TextButton.icon(
                      onPressed: () {
                        context.read<TestSessionBloc>().add(PreviousQuestion());
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('RETOUR'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: state.canGoNext
                        ? () {
                            context.read<TestSessionBloc>().add(NextQuestion());
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isLastQuestion ? AppColors.success : AppColors.primary,
                      minimumSize: const Size(120, 50),
                    ),
                    child: Text(state.isLastQuestion ? 'TERMINER' : 'SUIVANT'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      );
    }

    if (state is TestSessionSectionComplete) {
      return _SectionTransition(
        sectionTitle: state.sectionTitle,
        feedbackMessage: state.feedbackMessage,
        sectionIndex: state.completedSectionIndex,
        totalSections: state.sections.length,
        onContinue: () {
          context.read<TestSessionBloc>().add(ContinueFromSection());
        },
      );
    }

    if (state is TestSessionReadyToSubmit || context.read<OrientationBloc>().state is TestSubmitting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Analyse de ton profil...',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'On prépare tes résultats !',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
      );
    }

    return const SizedBox.shrink();
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quitter le test ?'),
        content: const Text('Ta progression sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.pop();
            },
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SEGMENTED PROGRESS BAR
// ============================================
class _SegmentedProgressBar extends StatelessWidget {
  final List<SectionInfo> sections;
  final int currentIndex;
  final int totalQuestions;

  const _SegmentedProgressBar({
    required this.sections,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: sections.asMap().entries.map((entry) {
          final i = entry.key;
          final section = entry.value;
          final sectionLength = section.endIndex - section.startIndex + 1;
          final flex = sectionLength;

          double sectionProgress;
          if (currentIndex > section.endIndex) {
            sectionProgress = 1.0;
          } else if (currentIndex < section.startIndex) {
            sectionProgress = 0.0;
          } else {
            sectionProgress = (currentIndex - section.startIndex + 1) / sectionLength;
          }

          return Expanded(
            flex: flex,
            child: Padding(
              padding: EdgeInsets.only(right: i < sections.length - 1 ? 3 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: sectionProgress,
                  backgroundColor: AppColors.surfaceLight,
                  color: _getSectionColor(i),
                  minHeight: 6,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getSectionColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }
}

// ============================================
// SECTION TRANSITION SCREEN
// ============================================
class _SectionTransition extends StatelessWidget {
  final String sectionTitle;
  final String feedbackMessage;
  final int sectionIndex;
  final int totalSections;
  final VoidCallback onContinue;

  const _SectionTransition({
    required this.sectionTitle,
    required this.feedbackMessage,
    required this.sectionIndex,
    required this.totalSections,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                boxShadow: AppColors.glowShadow,
              ),
              child: Column(
                children: [
                  Text(
                    _getSectionEmoji(),
                    style: const TextStyle(fontSize: 48),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Super !',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    feedbackMessage,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Passons à : $sectionTitle',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Section ${sectionIndex + 2} / $totalSections',
                    style: AppTypography.labelSmall,
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('CONTINUER'),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  String _getSectionEmoji() {
    final emojis = ['🎯', '🧠', '💎', '🪞', '📚', '🚀', '⚡', '🎨'];
    return emojis[sectionIndex % emojis.length];
  }
}

// ============================================
// QUESTION CARD - Routes to correct widget
// ============================================
class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question.text,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.xl),
          _buildQuestionWidget(),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget() {
    switch (question.type) {
      case QuestionType.likert:
        return _LikertScale(question: question);
      case QuestionType.scenario:
        return _ScenarioQuestion(question: question);
      case QuestionType.thisOrThat:
        return _ThisOrThatQuestion(question: question);
      case QuestionType.ranking:
        return _RankingQuestion(question: question);
      case QuestionType.slider:
        return _SliderQuestion(question: question);
      case QuestionType.multipleChoice:
      case QuestionType.boolean:
        return _LikertScale(question: question);
    }
  }
}

// ============================================
// LIKERT SCALE (existing, improved)
// ============================================
class _LikertScale extends StatelessWidget {
  final Question question;

  const _LikertScale({required this.question});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TestSessionBloc, TestSessionState>(
      builder: (context, state) {
        final currentResponse = (state as TestSessionInProgress).responses[question.id];

        return Column(
          children: question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = currentResponse == option.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  context.read<TestSessionBloc>().add(
                        AnswerQuestion(
                          questionId: question.id,
                          value: option.value,
                        ),
                      );
                },
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: AnimatedContainer(
                  duration: AppSpacing.animationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? AppColors.glowShadow : [],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.text,
                          style: isSelected
                              ? AppTypography.titleMedium.copyWith(color: Colors.white)
                              : AppTypography.bodyLarge,
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 50 * index),
              duration: 300.ms,
            ).slideX(begin: 0.1);
          }).toList(),
        );
      },
    );
  }
}

// ============================================
// SCENARIO QUESTION
// ============================================
class _ScenarioQuestion extends StatelessWidget {
  final Question question;

  const _ScenarioQuestion({required this.question});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TestSessionBloc, TestSessionState>(
      builder: (context, state) {
        final currentResponse = (state as TestSessionInProgress).responses[question.id];

        return Column(
          children: question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = currentResponse == option.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  context.read<TestSessionBloc>().add(
                        AnswerQuestion(
                          questionId: question.id,
                          value: option.id,
                        ),
                      );
                },
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: AnimatedContainer(
                  duration: AppSpacing.animationFast,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      if (option.emoji != null) ...[
                        Text(option.emoji!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: Text(
                          option.text,
                          style: isSelected
                              ? AppTypography.titleMedium.copyWith(color: AppColors.primary)
                              : AppTypography.bodyLarge,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 80 * index),
              duration: 300.ms,
            ).slideX(begin: 0.15);
          }).toList(),
        );
      },
    );
  }
}

// ============================================
// THIS OR THAT QUESTION
// ============================================
class _ThisOrThatQuestion extends StatelessWidget {
  final Question question;

  const _ThisOrThatQuestion({required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.options.length < 2) return const SizedBox.shrink();

    return BlocBuilder<TestSessionBloc, TestSessionState>(
      builder: (context, state) {
        final currentResponse = (state as TestSessionInProgress).responses[question.id];

        return Row(
          children: [
            Expanded(
              child: _ThisOrThatCard(
                option: question.options[0],
                isSelected: currentResponse == question.options[0].id,
                onTap: () {
                  context.read<TestSessionBloc>().add(
                        AnswerQuestion(
                          questionId: question.id,
                          value: question.options[0].id,
                        ),
                      );
                },
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'OU',
                style: AppTypography.labelSmall.copyWith(fontSize: 10),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ThisOrThatCard(
                option: question.options[1],
                isSelected: currentResponse == question.options[1].id,
                onTap: () {
                  context.read<TestSessionBloc>().add(
                        AnswerQuestion(
                          questionId: question.id,
                          value: question.options[1].id,
                        ),
                      );
                },
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
            ),
          ],
        );
      },
    );
  }
}

class _ThisOrThatCard extends StatelessWidget {
  final Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThisOrThatCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
      child: AnimatedContainer(
        duration: AppSpacing.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppColors.glowShadow : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.emoji != null)
              Text(
                option.emoji!,
                style: const TextStyle(fontSize: 40),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              option.text,
              style: isSelected
                  ? AppTypography.titleMedium.copyWith(color: Colors.white)
                  : AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.sm),
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// RANKING QUESTION (drag to reorder)
// ============================================
class _RankingQuestion extends StatefulWidget {
  final Question question;

  const _RankingQuestion({required this.question});

  @override
  State<_RankingQuestion> createState() => _RankingQuestionState();
}

class _RankingQuestionState extends State<_RankingQuestion> {
  late List<Option> _orderedOptions;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _orderedOptions = List.from(widget.question.options);
  }

  @override
  void didUpdateWidget(covariant _RankingQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _orderedOptions = List.from(widget.question.options);
      _hasInteracted = false;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _hasInteracted = true;
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _orderedOptions.removeAt(oldIndex);
      _orderedOptions.insert(newIndex, item);
    });
    // Save as list of option ids
    final ranking = _orderedOptions.map((o) => o.id).toList();
    context.read<TestSessionBloc>().add(
          AnswerQuestion(
            questionId: widget.question.id,
            value: ranking,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drag_indicator, color: AppColors.textTertiary, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Glisse pour réorganiser',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: AppSpacing.md),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderedOptions.length,
          onReorder: _onReorder,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final scale = Tween<double>(begin: 1.0, end: 1.05).animate(animation);
                return Transform.scale(
                  scale: scale.value,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final option = _orderedOptions[index];
            return Container(
              key: ValueKey(option.id),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: _hasInteracted ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (option.emoji != null) ...[
                    Text(option.emoji!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      option.text,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.drag_handle, color: AppColors.textTertiary),
                ],
              ),
            );
          },
        ),
        if (!_hasInteracted)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextButton(
              onPressed: () {
                setState(() => _hasInteracted = true);
                final ranking = _orderedOptions.map((o) => o.id).toList();
                context.read<TestSessionBloc>().add(
                      AnswerQuestion(
                        questionId: widget.question.id,
                        value: ranking,
                      ),
                    );
              },
              child: Text(
                'Garder cet ordre',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.xpGold;
      case 1:
        return AppColors.rankSilver;
      case 2:
        return AppColors.rankBronze;
      default:
        return AppColors.textTertiary;
    }
  }
}

// ============================================
// SLIDER QUESTION
// ============================================
class _SliderQuestion extends StatefulWidget {
  final Question question;

  const _SliderQuestion({required this.question});

  @override
  State<_SliderQuestion> createState() => _SliderQuestionState();
}

class _SliderQuestionState extends State<_SliderQuestion> {
  double _value = 50;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _loadExistingValue();
  }

  @override
  void didUpdateWidget(covariant _SliderQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _value = 50;
      _hasInteracted = false;
      _loadExistingValue();
    }
  }

  void _loadExistingValue() {
    final state = context.read<TestSessionBloc>().state;
    if (state is TestSessionInProgress) {
      final existing = state.responses[widget.question.id];
      if (existing != null) {
        _value = (existing as num).toDouble();
        _hasInteracted = true;
      }
    }
  }

  String _getDynamicEmoji() {
    if (_value < 20) return '😎';
    if (_value < 40) return '🤔';
    if (_value < 60) return '😐';
    if (_value < 80) return '🧐';
    return '🔥';
  }

  @override
  Widget build(BuildContext context) {
    final leftLabel = widget.question.sliderLeftLabel ?? 'Min';
    final rightLabel = widget.question.sliderRightLabel ?? 'Max';

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          _getDynamicEmoji(),
          style: const TextStyle(fontSize: 48),
        ).animate(
          key: ValueKey(_getDynamicEmoji()),
        ).scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  leftLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: _value < 50 ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: _value < 50 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  rightLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: _value > 50 ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: _value > 50 ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: _value,
            min: 0,
            max: 100,
            onChanged: (val) {
              setState(() {
                _value = val;
                _hasInteracted = true;
              });
            },
            onChangeEnd: (val) {
              context.read<TestSessionBloc>().add(
                    AnswerQuestion(
                      questionId: widget.question.id,
                      value: val,
                    ),
                  );
            },
          ),
        ),
        if (!_hasInteracted)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Glisse le curseur pour te positionner',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ).animate().fadeIn(duration: 600.ms),
      ],
    );
  }
}
