// Partie de test_execution_page.dart (refacto : page de 1050 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Question de type slider (curseur).
part of '../test_execution_page.dart';

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

  IconData _getDynamicEmoji() {
    if (_value < 20) return Icons.sentiment_very_satisfied_rounded;
    if (_value < 40) return Icons.sentiment_neutral_rounded;
    if (_value < 60) return Icons.sentiment_dissatisfied_rounded;
    if (_value < 80) return Icons.psychology_rounded;
    return Icons.local_fire_department_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final leftLabel = widget.question.sliderLeftLabel ?? 'Min';
    final rightLabel = widget.question.sliderRightLabel ?? 'Max';

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          _getDynamicEmoji(),
          size: 48,
          color: AppColors.primary,
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
