import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/quiz_model.dart';
import 'mastery_ring.dart';

/// Carte de quiz interactive et autonome : une question à la fois, feedback
/// immédiat (bonne/mauvaise réponse + explication), puis écran de score.
class QuizCard extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback? onRestart;

  const QuizCard({super.key, required this.quiz, this.onRestart});

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _finished = false;

  QuizQuestion get _question => widget.quiz.questions[_index];
  bool get _answered => _selected != null;
  bool get _isLast => _index == widget.quiz.length - 1;

  void _select(int optionIndex) {
    if (_answered) return;
    setState(() {
      _selected = optionIndex;
      if (_question.options[optionIndex].isCorrect) _score++;
    });
  }

  void _next() {
    if (_isLast) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _score = 0;
      _finished = false;
    });
    widget.onRestart?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  // ---- Question en cours ----

  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Question ${_index + 1} / ${widget.quiz.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            _scoreChip(),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _question.question,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_question.options.length, (i) => _buildOption(i)),
        if (_answered && _question.explanation.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildExplanation(),
        ],
        if (_answered) ...[
          const SizedBox(height: 16),
          _primaryButton(
            label: _isLast ? 'Voir mon score' : 'Question suivante',
            icon: _isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
            onTap: _next,
          ),
        ],
      ],
    );
  }

  Widget _buildOption(int i) {
    final option = _question.options[i];
    Color bg = AppColors.surface;
    Color borderColor = AppColors.border;
    Widget? trailing;

    if (_answered) {
      if (option.isCorrect) {
        bg = AppColors.successSurface;
        borderColor = AppColors.success;
        trailing = const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 20);
      } else if (i == _selected) {
        bg = AppColors.errorSurface;
        borderColor = AppColors.error;
        trailing = const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 20);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _answered ? null : () => _select(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _question.explanation,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Écran de score ----

  Widget _buildResult() {
    final total = widget.quiz.length;
    final ratio = total == 0 ? 0.0 : _score / total;
    final praise = ratio >= 0.8
        ? 'Excellent !'
        : ratio >= 0.5
            ? 'Bien joué, continue !'
            : 'Ne lâche rien, on progresse !';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MasteryRing(value: ratio, size: 96),
        const SizedBox(height: 14),
        Text(
          '$_score / $total',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          praise,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Nouveau quiz',
          icon: Icons.refresh_rounded,
          onTap: _restart,
        ),
      ],
    );
  }

  // ---- Sous-composants ----

  Widget _scoreChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.secondary, size: 15),
          const SizedBox(width: 3),
          Text(
            '$_score',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.primaryShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
