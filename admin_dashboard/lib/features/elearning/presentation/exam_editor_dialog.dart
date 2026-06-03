import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

/// Editeur d'examen QCM d'un cours (questions, score de passage, badge).
class ExamEditorDialog extends StatefulWidget {
  final String courseId;
  const ExamEditorDialog({super.key, required this.courseId});

  @override
  State<ExamEditorDialog> createState() => _ExamEditorDialogState();
}

class _ExamEditorDialogState extends State<ExamEditorDialog> {
  final _title = TextEditingController(text: 'Examen final');
  final _passing = TextEditingController(text: '80');
  final _xp = TextEditingController(text: '100');
  final _badgeTitle = TextEditingController();
  final _badgeIcon = TextEditingController(text: '🏅');

  final List<_QDraft> _questions = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _passing, _xp, _badgeTitle, _badgeIcon]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.get(ApiEndpoints.adminElearningCourseExam(widget.courseId));
      final data = res.data;
      if (data is Map && data.isNotEmpty) {
        _title.text = data['title'] ?? 'Examen final';
        _passing.text = '${data['passing_score'] ?? 80}';
        _xp.text = '${data['xp_reward'] ?? 100}';
        _badgeTitle.text = data['badge_title'] ?? '';
        _badgeIcon.text = data['badge_icon'] ?? '🏅';
        for (final q in (data['questions'] as List? ?? [])) {
          final opts = (q['options'] as List? ?? [])
              .map((o) => _ODraft(
                    TextEditingController(text: o['text'] ?? ''),
                    o['is_correct'] == true,
                  ))
              .toList();
          _questions.add(_QDraft(
            TextEditingController(text: q['question'] ?? ''),
            opts.isEmpty ? _defaultOptions() : opts,
          ));
        }
      }
    } catch (_) {
      // pas d'examen encore : on part d'un formulaire vierge
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_ODraft> _defaultOptions() =>
      [_ODraft(TextEditingController(), true), _ODraft(TextEditingController(), false)];

  void _addQuestion() {
    setState(() => _questions.add(_QDraft(TextEditingController(), _defaultOptions())));
  }

  Future<void> _save() async {
    // Validation basique
    if (_questions.isEmpty) {
      AdminSnackbar.error(context, 'Ajoutez au moins une question');
      return;
    }
    for (final q in _questions) {
      if (q.question.text.trim().isEmpty) {
        AdminSnackbar.error(context, 'Une question est vide');
        return;
      }
      final filled = q.options.where((o) => o.text.text.trim().isNotEmpty).toList();
      if (filled.length < 2) {
        AdminSnackbar.error(context, 'Chaque question doit avoir au moins 2 options');
        return;
      }
      if (!filled.any((o) => o.isCorrect)) {
        AdminSnackbar.error(context, 'Chaque question doit avoir une bonne réponse');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final api = getIt<ApiClient>();
      await api.put(ApiEndpoints.adminElearningCourseExam(widget.courseId), data: {
        'title': _title.text.trim(),
        'passing_score': int.tryParse(_passing.text) ?? 80,
        'xp_reward': int.tryParse(_xp.text) ?? 100,
        'badge_title': _badgeTitle.text.trim().isNotEmpty ? _badgeTitle.text.trim() : null,
        'badge_icon': _badgeIcon.text.trim().isNotEmpty ? _badgeIcon.text.trim() : null,
        'is_active': true,
        'questions': _questions.map((q) => {
          'question': q.question.text.trim(),
          'options': q.options
              .where((o) => o.text.text.trim().isNotEmpty)
              .map((o) => {'text': o.text.text.trim(), 'is_correct': o.isCorrect})
              .toList(),
        }).toList(),
      });
      if (mounted) {
        AdminSnackbar.success(context, 'Examen enregistré');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, "Échec de l'enregistrement");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.quiz_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('Examen du cours', style: AppTypography.heading2),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ]),
                    const SizedBox(height: 12),
                    // Reglages
                    Row(children: [
                      Expanded(child: TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre'))),
                      const SizedBox(width: 12),
                      SizedBox(width: 110, child: TextField(
                        controller: _passing, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Réussite %', helperText: 'def. 80'))),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: TextField(
                        controller: _xp, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'XP'))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _badgeTitle,
                          decoration: const InputDecoration(labelText: 'Titre du badge (ex: Expert Python)'))),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: TextField(controller: _badgeIcon,
                          decoration: const InputDecoration(labelText: 'Icône'))),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('Questions (${_questions.length})', style: AppTypography.heading3),
                      const Spacer(),
                      TextButton.icon(icon: const Icon(Icons.add), label: const Text('Question'), onPressed: _addQuestion),
                    ]),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _questions.isEmpty
                          ? Center(child: Text('Aucune question. Cliquez « Question » pour commencer.',
                              style: AppTypography.subtitle))
                          : ListView.separated(
                              itemCount: _questions.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (_, i) => _buildQuestion(i),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Enregistrer l\'examen'),
                      ),
                    ]),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuestion(int i) {
    final q = _questions[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: q.question,
              decoration: const InputDecoration(labelText: 'Énoncé de la question', isDense: true))),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => setState(() => _questions.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 6),
        ...List.generate(q.options.length, (j) {
          final o = q.options[j];
          return Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Row(children: [
              IconButton(
                tooltip: o.isCorrect ? 'Bonne réponse' : 'Marquer comme correcte',
                icon: Icon(
                  o.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: o.isCorrect ? AppColors.success : AppColors.textMuted,
                ),
                onPressed: () => setState(() {
                  for (final e in q.options) {
                    e.isCorrect = false;
                  }
                  q.options[j].isCorrect = true;
                }),
              ),
              Expanded(child: TextField(controller: o.text,
                  decoration: InputDecoration(
                    labelText: 'Option ${j + 1}${o.isCorrect ? ' (correcte)' : ''}',
                    isDense: true,
                  ))),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: q.options.length > 2
                    ? () => setState(() => q.options.removeAt(j))
                    : null,
              ),
            ]),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Option'),
            onPressed: q.options.length < 8
                ? () => setState(() => q.options.add(_ODraft(TextEditingController(), false)))
                : null,
          ),
        ),
      ],
    );
  }
}

class _QDraft {
  final TextEditingController question;
  final List<_ODraft> options;
  _QDraft(this.question, this.options);
}

class _ODraft {
  final TextEditingController text;
  bool isCorrect;
  _ODraft(this.text, this.isCorrect);
}
