import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class TestEditorPage extends StatefulWidget {
  final String? testId;
  const TestEditorPage({super.key, this.testId});

  @override
  State<TestEditorPage> createState() => _TestEditorPageState();
}

class _TestEditorPageState extends State<TestEditorPage> {
  bool get _isEditing => widget.testId != null;
  bool _isLoading = false;
  bool _isSaving = false;
  List<dynamic> _questions = [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '15');
  String _type = 'riasec';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTest();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTest() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminTestById(widget.testId!));
      final data = response.data as Map<String, dynamic>;
      _nameCtrl.text = data['name'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _durationCtrl.text = '${data['duration_minutes'] ?? 15}';
      _type = data['type'] ?? 'riasec';
      _isActive = data['is_active'] ?? true;
      _questions = List.from(data['questions'] ?? []);
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTest() async {
    if (_nameCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      AdminSnackbar.error(context, 'Nom et description requis');
      return;
    }
    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'type': _type,
      'duration_minutes': int.tryParse(_durationCtrl.text) ?? 15,
      'is_active': _isActive,
    };

    try {
      final api = getIt<ApiClient>();
      if (_isEditing) {
        await api.put(ApiEndpoints.adminTestById(widget.testId!), data: data);
        if (mounted) AdminSnackbar.success(context, 'Test sauvegarde');
      } else {
        final response = await api.post(ApiEndpoints.adminTests, data: data);
        final newTest = response.data as Map<String, dynamic>;
        if (mounted) {
          AdminSnackbar.success(context, 'Test cree');
          context.go('/tests/${newTest['id']}/edit');
        }
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
    setState(() => _isSaving = false);
  }

  Future<void> _addQuestion() async {
    if (!_isEditing) return;
    final textCtrl = TextEditingController();
    String qType = 'likert';
    String? category;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle question'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Texte *'), maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: qType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AdminConstants.questionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => qType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categorie RIASEC'),
                  items: [null, ...AdminConstants.riasecCategories].map((c) =>
                      DropdownMenuItem(value: c, child: Text(c ?? 'Aucune'))).toList(),
                  onChanged: (v) => setDialogState(() => category = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
          ],
        ),
      ),
    );

    if (result != true || textCtrl.text.isEmpty) return;

    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminTestQuestions(widget.testId!), data: {
        'question_text': textCtrl.text,
        'question_type': qType,
        'category': category,
        'display_order': _questions.length,
      });
      _loadTest();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _deleteQuestion(String qId) async {
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminTestQuestionById(widget.testId!, qId));
      _loadTest();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/tests')),
              const SizedBox(width: 8),
              Text(_isEditing ? 'Editeur de test' : 'Nouveau test', style: AppTypography.heading1),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTest,
                child: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Sauvegarder' : 'Creer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel - test metadata
                SizedBox(
                  width: 360,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informations', style: AppTypography.heading3),
                          const SizedBox(height: 16),
                          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom *')),
                          const SizedBox(height: 12),
                          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 3),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: AdminConstants.testTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Duree (min)'),
                              keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Actif'),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right panel - questions
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Questions (${_questions.length})', style: AppTypography.heading3),
                              const Spacer(),
                              if (_isEditing)
                                ElevatedButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Ajouter'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isEditing)
                            Text('Creez d\'abord le test pour ajouter des questions.', style: AppTypography.subtitle)
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: _questions.length,
                                itemBuilder: (ctx, i) {
                                  final q = _questions[i] as Map<String, dynamic>;
                                  final options = q['options'] as List? ?? [];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Text('${i + 1}', style: TextStyle(color: AppColors.primary)),
                                      ),
                                      title: Text(q['question_text'] ?? '', style: AppTypography.body),
                                      subtitle: Text(
                                        '${q['question_type']} | ${q['category'] ?? '-'} | ${options.length} options',
                                        style: AppTypography.bodySmall,
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                        onPressed: () => _deleteQuestion(q['id']),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
