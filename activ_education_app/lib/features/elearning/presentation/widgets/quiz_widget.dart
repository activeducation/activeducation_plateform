import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

class QuizQuestion {
  final String id;
  final String text;
  final List<QuizOption> options;
  final int? passsScorePct;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.passsScorePct,
  });
}

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}

class QuizWidget extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int passScorePct;
  final void Function(int score, Map<String, String> answers) onCompleted;

  const QuizWidget({
    super.key,
    required this.questions,
    this.passScorePct = 60,
    required this.onCompleted,
  });

  static List<QuizQuestion> fromContentData(Map<String, dynamic> data) {
    final questionsList = data['questions'] as List<dynamic>? ?? [];
    return questionsList.map((q) {
      final qMap = q as Map<String, dynamic>;
      final optionsList = qMap['options'] as List<dynamic>? ?? [];
      return QuizQuestion(
        id: qMap['id']?.toString() ?? UniqueKey().toString(),
        text: qMap['text']?.toString() ?? qMap['question']?.toString() ?? '',
        passsScorePct: (qMap['pass_score_pct'] as num?)?.toInt(),
        options: optionsList.map((o) {
          final oMap = o as Map<String, dynamic>;
          return QuizOption(
            id: oMap['id']?.toString() ?? UniqueKey().toString(),
            text: oMap['text']?.toString() ?? '',
            isCorrect: oMap['is_correct'] as bool? ?? false,
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  bool _showResult = false;
  int _score = 0;

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];
  bool get _isAnswered => _selectedAnswers.containsKey(_currentQuestion.id);
  bool get _isLast => _currentIndex == widget.questions.length - 1;
  bool get _allAnswered =>
      _selectedAnswers.length == widget.questions.length;

  void _selectOption(QuizOption option) {
    if (_selectedAnswers.containsKey(_currentQuestion.id)) return;
    setState(() {
      _selectedAnswers[_currentQuestion.id] = option.id;
    });
  }

  void _goNext() {
    if (_isLast) {
      _finishQuiz();
    } else {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _finishQuiz() {
    int correct = 0;
    for (final question in widget.questions) {
      final selectedId = _selectedAnswers[question.id];
      if (selectedId != null) {
        final selectedOption = question.options.firstWhere(
          (o) => o.id == selectedId,
          orElse: () => const QuizOption(id: '', text: '', isCorrect: false),
        );
        if (selectedOption.isCorrect) correct++;
      }
    }

    _score = widget.questions.isEmpty
        ? 0
        : ((correct / widget.questions.length) * 100).round();

    setState(() {
      _showResult = true;
    });
  }

  void _onValidate() {
    widget.onCompleted(_score, _selectedAnswers);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: Text('Aucune question disponible.'),
      );
    }

    if (_showResult) {
      return _ResultView(
        score: _score,
        passScorePct: widget.passScorePct,
        totalQuestions: widget.questions.length,
        correctCount: widget.questions.where((q) {
          final selectedId = _selectedAnswers[q.id];
          if (selectedId == null) return false;
          return q.options
              .firstWhere((o) => o.id == selectedId,
                  orElse: () =>
                      const QuizOption(id: '', text: '', isCorrect: false))
              .isCorrect;
        }).length,
        onValidate: _onValidate,
      );
    }

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Question ${_currentIndex + 1}/${widget.questions.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedAnswers.length}/${widget.questions.length} répondues',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: AppSpacing.progressBarHeight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _currentQuestion.text,
                    style: AppTypography.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Options
                ...widget.questions[_currentIndex].options
                    .map((option) => _OptionTile(
                          option: option,
                          selectedId:
                              _selectedAnswers[_currentQuestion.id],
                          isAnswered: _isAnswered,
                          onSelect: () => _selectOption(option),
                        )),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goPrevious,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Précédent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAnswered ? _goNext : null,
                  icon: Icon(
                    _isLast
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(_isLast ? 'Voir le résultat' : 'Suivant'),
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
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final String? selectedId;
  final bool isAnswered;
  final VoidCallback onSelect;

  const _OptionTile({
    required this.option,
    required this.selectedId,
    required this.isAnswered,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == option.id;
    final showCorrect = isAnswered && option.isCorrect;
    final showWrong = isAnswered && isSelected && !option.isCorrect;

    Color borderColor = AppColors.border;
    Color bgColor = AppColors.card;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;
    Color? iconColor;

    if (showCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.successLight;
      textColor = AppColors.successDark;
      trailingIcon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
    } else if (showWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.errorLight;
      textColor = AppColors.errorDark;
      trailingIcon = Icons.cancel_rounded;
      iconColor = AppColors.error;
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primarySurface;
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(trailingIcon, color: iconColor, size: AppSpacing.iconSm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int passScorePct;
  final int totalQuestions;
  final int correctCount;
  final VoidCallback onValidate;

  const _ResultView({
    required this.score,
    required this.passScorePct,
    required this.totalQuestions,
    required this.correctCount,
    required this.onValidate,
  });

  bool get _passed => score >= passScorePct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _passed
                  ? AppColors.successLight
                  : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _passed
                    ? Icons.emoji_events_rounded
                    : Icons.replay_rounded,
                size: 48,
                color:
                    _passed ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _passed ? 'Bravo !' : 'Dommage !',
            style: AppTypography.headlineSmall.copyWith(
              color:
                  _passed ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Score : $score%',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$correctCount/$totalQuestions bonnes réponses',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _passed
                ? 'Vous avez réussi le quiz !'
                : 'Score minimum requis : $passScorePct%',
            style: AppTypography.bodySmall.copyWith(
              color:
                  _passed ? AppColors.textSecondary : AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onValidate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm),
              ),
              child: const Text('Valider et continuer'),
            ),
          ),
        ],
      ),
    );
  }
}
