import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../bloc/exam_bloc.dart';

class CourseExamPage extends StatefulWidget {
  final String courseId;
  const CourseExamPage({super.key, required this.courseId});

  @override
  State<CourseExamPage> createState() => _CourseExamPageState();
}

class _CourseExamPageState extends State<CourseExamPage> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, List<int>> _shuffledIndices = {};

  @override
  void initState() {
    super.initState();
    context.read<ExamBloc>().add(LoadExam(widget.courseId));
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<int> _shuffleIndices(List options) {
    final indices = List.generate(options.length, (i) => i);
    indices.shuffle(Random());
    return indices;
  }

  bool _allAnswered(Map<String, dynamic>? exam) {
    final questions = (exam?['questions'] as List?) ?? [];
    for (final q in questions) {
      final qid = q['id'].toString();
      final type = q['question_type'] ?? 'single_choice';
      final ans = _answers[qid];
      if (type == 'text_input') {
        final ctrl = _textControllers[qid];
        if (ctrl == null || ctrl.text.trim().isEmpty) return false;
      } else if (ans == null) return false;
      if (type == 'multiple_choice' && ans is List && ans.isEmpty) return false;
      if (type == 'ordering' && ans is List && ans.isEmpty) return false;
    }
    return questions.isNotEmpty;
  }

  void _submit(Map<String, dynamic> exam) {
    for (final e in _textControllers.entries) {
      _answers[e.key] = e.value.text.trim();
    }

    // Audit #3 (2026-07-30) : pour les questions ordering, transformer les
    // indices melanges en liste de textes avant d'envoyer. Le backend
    // (elearning.py) compare a l'ordre canonique des options (tri par
    // display_order croissant), robuste au shuffle initial.
    final questions = (exam['questions'] as List?) ?? [];
    for (final q in questions) {
      final qid = q['id']?.toString();
      final type = q['question_type'];
      if (qid == null || type != 'ordering') continue;
      final ans = _answers[qid];
      final options = (q['options'] as List?) ?? [];
      if (ans is List && ans.isNotEmpty && ans.first is int) {
        // ans = liste d'indices dans l'ordre visuel choisi
        _answers[qid] = ans
            .map<int>((dynamic i) => i as int)
            .map<String>((int i) => (options[i] as Map)['text']?.toString() ?? '')
            .toList();
      }
    }

    context.read<ExamBloc>().add(SubmitExam(widget.courseId, Map.from(_answers)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<ExamBloc, ExamState>(
          builder: (ctx, state) => Text(state.exam?['title'] ?? 'Examen', style: AppTypography.titleMedium),
        ),
      ),
      body: BlocConsumer<ExamBloc, ExamState>(
        listener: (ctx, state) {
          if (state.error != null && state.exam != null) {
            AppSnackbar.error(context, state.error!);
          }
        },
        builder: (ctx, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          if (state.error != null && state.exam == null) return _buildError(state.error!);
          if (state.result != null) return _buildResult(state.result!);
          if (state.exam != null) return _buildQuiz(state.exam!);
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildError(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.info_circle, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GradientButton(text: 'Retour', showArrow: false, width: 160, onPressed: () => context.pop()),
            ],
          ),
        ),
      );

  Widget _buildQuiz(Map<String, dynamic> exam) {
    final questions = (exam['questions'] as List?) ?? [];
    final passing = exam['passing_score'] ?? 80;
    return BlocBuilder<ExamBloc, ExamState>(
      builder: (ctx, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Iconsax.medal_star, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Obtenez $passing% ou plus pour réussir et gagner votre badge.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              ...questions.asMap().entries.map((e) => _buildQuestion(e.key, e.value)),
              const SizedBox(height: 8),
              GradientButton(
                text: state.isSubmitting ? 'Soumission...' : 'Soumettre mes réponses',
                icon: Iconsax.tick_circle,
                showArrow: false,
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (!_allAnswered(exam)) {
                          AppSnackbar.info(context, 'Répondez à toutes les questions.');
                          return;
                        }
                        _submit(exam);
                      },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestion(int index, dynamic q) {
    final qid = q['id'].toString();
    final type = q['question_type'] ?? 'single_choice';
    final options = (q['options'] as List?) ?? [];
    final typeLabel = _questionTypeLabel(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${index + 1}. ${q['question']}',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(typeLabel, style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 10),
          if (type == 'single_choice') _buildSingleChoice(qid, options),
          if (type == 'multiple_choice') _buildMultipleChoice(qid, options),
          if (type == 'text_input') _buildTextInput(qid),
          if (type == 'ordering') _buildOrdering(qid, options),
        ],
      ),
    );
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'single_choice': return 'Choix unique';
      case 'multiple_choice': return 'Choix multiples';
      case 'text_input': return 'Réponse libre';
      case 'ordering': return 'Ordonnancement';
      default: return type;
    }
  }

  Widget _buildSingleChoice(String qid, List options) {
    final selected = _answers[qid] as int?;
    return Column(
      children: options.asMap().entries.map((e) {
        final idx = e.key;
        final isSelected = selected == idx;
        return InkWell(
          onTap: () => setState(() => _answers[qid] = idx),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value['text'] ?? '', style: AppTypography.bodyMedium)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoice(String qid, List options) {
    final selected = Set<int>.from((_answers[qid] as List?)?.cast<int>() ?? []);
    return Column(
      children: options.asMap().entries.map((e) {
        final idx = e.key;
        final isChecked = selected.contains(idx);
        return InkWell(
          onTap: () {
            setState(() {
              if (isChecked) {
                selected.remove(idx);
              } else {
                selected.add(idx);
              }
              _answers[qid] = selected.toList();
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isChecked ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChecked ? AppColors.primary : AppColors.border,
                width: isChecked ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(
                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: isChecked ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value['text'] ?? '', style: AppTypography.bodyMedium)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(String qid) {
    _textControllers.putIfAbsent(qid, () => TextEditingController());
    return TextField(
      controller: _textControllers[qid],
      decoration: InputDecoration(
        hintText: 'Écrivez votre réponse ici...',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      maxLines: 3,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildOrdering(String qid, List options) {
    final order = _shuffledIndices.putIfAbsent(qid, () => _shuffleIndices(options));
    final currentOrder = (_answers[qid] as List<int>?) ?? List.from(order);
    final isDirty = _answers.containsKey(qid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Faites glisser pour réordonner :',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex--;
              final item = currentOrder.removeAt(oldIndex);
              currentOrder.insert(newIndex, item);
              _answers[qid] = List.from(currentOrder);
            });
          },
          itemBuilder: (ctx, visualIndex) {
            final actualIndex = currentOrder[visualIndex];
            final item = options[actualIndex];
            return Container(
              key: ValueKey('$qid-$actualIndex'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Iconsax.menu, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Expanded(child: Text(item['text'] ?? '', style: AppTypography.bodyMedium)),
                if (isDirty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('#${visualIndex + 1}', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                  ),
              ]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResult(Map<String, dynamic> r) {
    final passed = r['passed'] == true;
    final score = r['score'] ?? 0;
    final badge = r['badge_earned'] == true;
    final xp = r['xp_awarded'] ?? 0;
    final color = passed ? AppColors.success : AppColors.error;
    final details = (r['details'] as List?) ?? [];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 56, color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(passed ? 'Félicitations !' : 'Pas encore réussi',
                style: AppTypography.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Votre score : $score%',
                style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.w800)),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...details.map((d) {
                final correct = d['correct'] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(correct ? Icons.check_circle : Icons.cancel_rounded,
                        size: 18, color: correct ? AppColors.success : AppColors.error),
                    const SizedBox(width: 6),
                    Text(correct ? 'Correct' : 'Incorrect',
                        style: AppTypography.bodySmall.copyWith(
                            color: correct ? AppColors.success : AppColors.error)),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 16),
            if (passed && badge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.xpGoldSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  r['badge_icon'] != null
                      ? Text(r['badge_icon']!, style: const TextStyle(fontSize: 24))
                      : const Icon(Icons.emoji_events_rounded, size: 24, color: AppColors.xpGoldDark),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Badge débloqué', style: AppTypography.labelSmall.copyWith(color: AppColors.xpGoldDark)),
                    Text(r['badge_title'] ?? 'Cours réussi',
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
              if (xp > 0) ...[
                const SizedBox(height: 10),
                Text('+$xp XP', style: AppTypography.titleSmall.copyWith(
                    color: AppColors.xpBar, fontWeight: FontWeight.w800)),
              ],
            ],
            if (!passed) ...[
              const SizedBox(height: 8),
              Text('Il faut ${r['passing_score'] ?? 80}% pour réussir. Révisez et réessayez !',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!passed)
                OutlinedButton(
                  onPressed: () {
                    context.read<ExamBloc>().add(ResetExam());
                    _answers.clear();
                    _textControllers.clear();
                    _shuffledIndices.clear();
                  },
                  child: const Text('Réessayer'),
                ),
              if (!passed) const SizedBox(width: 12),
              GradientButton(
                text: passed ? 'Terminer' : 'Retour au cours',
                showArrow: false,
                width: 180,
                onPressed: () => context.pop(),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
