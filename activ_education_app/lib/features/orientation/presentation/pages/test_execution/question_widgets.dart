// Partie de test_execution_page.dart (refacto : page de 1050 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Widgets de questions : carte routeuse, Likert, scenario, this-or-that, ranking.
part of '../test_execution_page.dart';

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
          // onReorder deprecated en faveur de onReorderItem (auto-ajuste
          // newIndex). Migration prévue dans PR refacto reorder UX.
          // ignore: deprecated_member_use
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
