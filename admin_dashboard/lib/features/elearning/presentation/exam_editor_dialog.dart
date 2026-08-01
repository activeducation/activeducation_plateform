import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

const _questionTypes = [
  {'value': 'single_choice', 'label': 'Choix unique'},
  {'value': 'multiple_choice', 'label': 'Choix multiples'},
  {'value': 'text_input', 'label': 'Réponse libre'},
  {'value': 'ordering', 'label': 'Ordonnancement'},
];

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
          final qtype = q['question_type'] ?? 'single_choice';
          final opts = (q['options'] as List? ?? []);
          List<_ODraft> parsedOptions;
          if (qtype == 'text_input') {
            final accepted = opts.where((o) => o['is_correct'] == true).toList();
            parsedOptions = accepted.isEmpty
                ? [_ODraft(TextEditingController(), true)]
                : accepted.map((o) => _ODraft(TextEditingController(text: o['text'] ?? ''), true)).toList();
          } else if (qtype == 'ordering') {
            parsedOptions = opts.map((o) => _ODraft(TextEditingController(text: o['text'] ?? ''), false)).toList();
          } else {
            parsedOptions = opts
                .map((o) => _ODraft(
                      TextEditingController(text: o['text'] ?? ''),
                      o['is_correct'] == true,
                    ))
                .toList();
          }
          _questions.add(_QDraft(
            qtype,
            TextEditingController(text: q['question'] ?? ''),
            parsedOptions.isEmpty ? _defaultOptions() : parsedOptions,
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

  List<_ODraft> _optionsForType(String qtype) {
    switch (qtype) {
      case 'text_input':
        return [_ODraft(TextEditingController(), true)];
      case 'ordering':
        return [
          _ODraft(TextEditingController(), false),
          _ODraft(TextEditingController(), false),
          _ODraft(TextEditingController(), false),
        ];
      default:
        return _defaultOptions();
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QDraft(
        'single_choice',
        TextEditingController(),
        _optionsForType('single_choice'),
      ));
    });
  }

  Future<void> _save() async {
    if (_questions.isEmpty) {
      AdminSnackbar.error(context, 'Ajoutez au moins une question');
      return;
    }
    for (final q in _questions) {
      if (q.question.text.trim().isEmpty) {
        AdminSnackbar.error(context, 'Une question est vide');
        return;
      }
      if (q.type == 'ordering' && q.options.length < 2) {
        AdminSnackbar.error(context, 'Chaque question d\'ordonnancement doit avoir au moins 2 éléments');
        return;
      }
      if (q.type == 'text_input' && q.options.isNotEmpty && q.options.first.text.text.trim().isEmpty) {
        AdminSnackbar.error(context, 'Une question de réponse libre doit avoir une réponse attendue');
        return;
      }
      if (q.type == 'single_choice') {
        final filled = q.options.where((o) => o.text.text.trim().isNotEmpty).toList();
        if (filled.length < 2) {
          AdminSnackbar.error(context, 'Chaque question choix unique doit avoir au moins 2 options');
          return;
        }
        if (filled.where((o) => o.isCorrect).length != 1) {
          AdminSnackbar.error(context, 'Chaque question doit avoir exactement une bonne réponse');
          return;
        }
      }
      if (q.type == 'multiple_choice') {
        final filled = q.options.where((o) => o.text.text.trim().isNotEmpty).toList();
        if (filled.length < 2) {
          AdminSnackbar.error(context, 'Chaque question choix multiples doit avoir au moins 2 options');
          return;
        }
        if (filled.where((o) => o.isCorrect).length < 1) {
          AdminSnackbar.error(context, 'Chaque question doit avoir au moins une bonne réponse');
          return;
        }
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
        'questions': _questions.map((q) {
          final base = {'question': q.question.text.trim(), 'question_type': q.type, 'options': <Map<String, dynamic>>[]};
          if (q.type == 'text_input') {
            base['options'] = q.options.map((o) => {'text': o.text.text.trim(), 'is_correct': true}).toList();
          } else if (q.type == 'ordering') {
            base['options'] = q.options.map((o) => {'text': o.text.text.trim(), 'is_correct': false}).toList();
          } else {
            base['options'] = q.options
                .where((o) => o.text.text.trim().isNotEmpty)
                .map((o) => {'text': o.text.text.trim(), 'is_correct': o.isCorrect})
                .toList();
          }
          return base;
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
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: q.type,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Type', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: _questionTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  q.type = v;
                  q.options = _optionsForType(v);
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => setState(() => _questions.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 6),
        if (q.type == 'text_input')
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: TextField(
              controller: q.options.isNotEmpty ? q.options.first.text : TextEditingController(),
              decoration: const InputDecoration(labelText: 'Réponse attendue', isDense: true),
            ),
          ),
        if (q.type == 'single_choice' || q.type == 'multiple_choice')
          ...List.generate(q.options.length, (j) {
            final o = q.options[j];
            return Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 4),
              child: Row(children: [
                IconButton(
                  tooltip: o.isCorrect ? 'Bonne réponse' : 'Marquer comme correcte',
                  icon: Icon(
                    q.type == 'single_choice'
                        ? (o.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked)
                        : (o.isCorrect ? Icons.check_box : Icons.check_box_outline_blank),
                    color: o.isCorrect ? AppColors.success : AppColors.textMuted,
                  ),
                  onPressed: () => setState(() {
                    if (q.type == 'single_choice') {
                      for (final e in q.options) {
                        e.isCorrect = false;
                      }
                      q.options[j].isCorrect = true;
                    } else {
                      q.options[j].isCorrect = !o.isCorrect;
                    }
                  }),
                ),
                Expanded(child: TextField(controller: o.text,
                    decoration: InputDecoration(labelText: 'Option ${j + 1}', isDense: true))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: q.options.length > (q.type == 'single_choice' ? 2 : 2)
                      ? () => setState(() => q.options.removeAt(j))
                      : null,
                ),
              ]),
            );
          }),
        if (q.type == 'ordering')
          ...List.generate(q.options.length, (j) {
            final o = q.options[j];
            return Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 4),
              child: Row(children: [
                Container(
                  width: 24, height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${j + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: o.text,
                    decoration: InputDecoration(labelText: 'Élément ${j + 1}', isDense: true))),
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
            label: Text(q.type == 'ordering' ? 'Élément' : 'Option'),
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
  String type;
  final TextEditingController question;
  List<_ODraft> options;
  _QDraft(this.type, this.question, this.options);
}

class _ODraft {
  final TextEditingController text;
  bool isCorrect;
  _ODraft(this.text, this.isCorrect);
}
