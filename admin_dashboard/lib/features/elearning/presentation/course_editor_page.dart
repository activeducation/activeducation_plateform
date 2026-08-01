import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import 'exam_editor_dialog.dart';

class CourseEditorPage extends StatefulWidget {
  final String? courseId;
  const CourseEditorPage({super.key, this.courseId});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  bool get _isEditing => widget.courseId != null;
  bool _isLoading = false;
  bool _isSaving = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _thumbnailCtrl = TextEditingController();
  String _level = 'beginner';
  bool _isPublished = false;

  List<dynamic> _modules = [];
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadCourse();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _thumbnailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminElearningCourseById(widget.courseId!));
      final data = response.data as Map<String, dynamic>;
      _titleCtrl.text = data['title'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _thumbnailCtrl.text = data['thumbnail_url'] ?? '';
      _level = _mapDifficulty(data['difficulty'] as String? ?? 'beginner');
      _isPublished = data['is_published'] ?? false;
      _selectedSchoolId = data['school_id'];
      _modules = List.from(data['modules'] ?? []);
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _unmapDifficulty(String v) =>
      v == 'beginner' ? 'debutant' : v == 'intermediate' ? 'intermediaire' : 'avance';

  static String _mapDifficulty(String v) =>
      v == 'debutant' ? 'beginner' : v == 'intermediaire' ? 'intermediate' : 'advanced';

  Future<void> _saveCourse() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      AdminSnackbar.error(context, 'Titre et description requis');
      return;
    }
    setState(() => _isSaving = true);

    try {
      final api = getIt<ApiClient>();
      final data = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'thumbnail_url': _thumbnailCtrl.text.isNotEmpty ? _thumbnailCtrl.text : null,
        'difficulty': _unmapDifficulty(_level),
      };

      if (_isEditing) {
        await api.put(ApiEndpoints.adminElearningCourseById(widget.courseId!), data: data);
        if (mounted) AdminSnackbar.success(context, 'Cours mis à jour');
      } else {
        if (_selectedSchoolId != null) {
          data['school_id'] = _selectedSchoolId;
        }
        final response = await api.post(ApiEndpoints.adminElearningCourses, data: data);
        if (mounted) {
          AdminSnackbar.success(context, 'Cours créé');
          context.go('/elearning/courses/${response.data['id']}/edit');
        }
        return;
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
    setState(() => _isSaving = false);
  }

  Future<void> _togglePublish() async {
    try {
      final api = getIt<ApiClient>();
      await api.put(
        ApiEndpoints.adminElearningCourseById(widget.courseId!),
        data: {'is_published': !_isPublished},
      );
      setState(() => _isPublished = !_isPublished);
      if (mounted) AdminSnackbar.success(context, _isPublished ? 'Cours publié' : 'Cours masqué');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  bool _uploadingImage = false;

  Future<void> _duplicateCourse() async {
    final titleCtrl = TextEditingController(text: '${_titleCtrl.text} (copie)');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dupliquer le cours'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre de la copie')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dupliquer')),
        ],
      ),
    );
    if (result != true) return;

    try {
      final api = getIt<ApiClient>();
      final res = await api.post(
        ApiEndpoints.adminElearningCourseDuplicate(widget.courseId!),
        data: {'new_title': titleCtrl.text},
      );
      if (mounted) {
        AdminSnackbar.success(context, 'Cours dupliqué');
        context.go('/elearning/courses/${res.data['id']}/edit');
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur lors de la duplication');
    }
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) AdminSnackbar.error(context, 'Fichier illisible');
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final api = getIt<ApiClient>();
      final ext = file.name.split('.').last.toLowerCase();
      final contentType = switch (ext) {
        'png' => DioMediaType.parse('image/png'),
        'webp' => DioMediaType.parse('image/webp'),
        _ => DioMediaType.parse('image/jpeg'),
      };
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name, contentType: contentType),
      });
      final res = await api.post(ApiEndpoints.adminUpload('elearning'), data: form);
      final url = res.data['url'] as String?;
      if (url != null) {
        setState(() => _thumbnailCtrl.text = url);
        if (mounted) AdminSnackbar.success(context, 'Image téléversée');
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, "Échec de l'upload");
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _openExamEditor() async {
    await showDialog(
      context: context,
      builder: (_) => ExamEditorDialog(courseId: widget.courseId!),
    );
  }

  Future<void> _addModule() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau module'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
        ],
      ),
    );

    if (result != true || titleCtrl.text.isEmpty) return;

    try {
      final api = getIt<ApiClient>();
      final response = await api.post(
        ApiEndpoints.adminElearningCourseModules(widget.courseId!),
        data: {
          'title': titleCtrl.text,
          'description': descCtrl.text.isNotEmpty ? descCtrl.text : null,
          'display_order': _modules.length,
        },
      );
      setState(() => _modules.add(response.data));
      if (mounted) AdminSnackbar.success(context, 'Module ajouté');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _deleteModule(String moduleId) async {
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminElearningModule(moduleId));
      setState(() => _modules.removeWhere((m) => m['id'] == moduleId));
      if (mounted) AdminSnackbar.success(context, 'Module supprimé');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _addLesson(String moduleId) async {
    final titleCtrl = TextEditingController();
    String lessonType = 'text';
    final contentCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    final videoProvider = TextEditingController(text: 'youtube');
    final markdownCtrl = TextEditingController();
    final challengeInstructionsCtrl = TextEditingController();
    final challengeCodeCtrl = TextEditingController();
    final challengeLanguageCtrl = TextEditingController(text: 'python');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle leçon'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: lessonType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                  DropdownMenuItem(value: 'article', child: Text('Article (Markdown)')),
                  DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                  DropdownMenuItem(value: 'challenge', child: Text('Défi')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                ],
                onChanged: (v) => setDialogState(() => lessonType = v!),
              ),
              const SizedBox(height: 12),
              if (lessonType == 'text')
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Contenu'), maxLines: 6),
              if (lessonType == 'article') ...[
                TextField(controller: markdownCtrl, decoration: const InputDecoration(labelText: 'Contenu (Markdown)', hintText: '# Titre\n\nParagraphe avec **gras** et - listes'), maxLines: 10),
              ],
              if (lessonType == 'video') ...[
                TextField(controller: videoCtrl, decoration: const InputDecoration(labelText: 'URL vidéo')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: videoProvider.text,
                  decoration: const InputDecoration(labelText: 'Plateforme', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                    DropdownMenuItem(value: 'vimeo', child: Text('Vimeo')),
                  ],
                  onChanged: (v) => setDialogState(() => videoProvider.text = v!),
                ),
              ],
              if (lessonType == 'challenge') ...[
                TextField(controller: challengeInstructionsCtrl, decoration: const InputDecoration(labelText: 'Instructions'), maxLines: 6),
                const SizedBox(height: 8),
                TextField(controller: challengeCodeCtrl, decoration: const InputDecoration(labelText: 'Code de départ (optionnel)'), maxLines: 6, style: const TextStyle(fontFamily: 'monospace')),
                const SizedBox(height: 8),
                TextField(controller: challengeLanguageCtrl, decoration: const InputDecoration(labelText: 'Langage (python, dart, etc.)')),
              ],
              if (lessonType == 'pdf')
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'URL du PDF')),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
          ],
        ),
      ),
    );

    if (result != true || titleCtrl.text.isEmpty) return;

    try {
      final api = getIt<ApiClient>();
      final data = <String, dynamic>{
        'title': titleCtrl.text,
        'lesson_type': lessonType,
        'display_order': 0,
      };
      if (lessonType == 'video' && videoCtrl.text.isNotEmpty) {
        data['video_url'] = videoCtrl.text;
        data['video_provider'] = videoProvider.text;
      }
      if (lessonType == 'article') {
        data['markdown_body'] = markdownCtrl.text;
      }
      if (lessonType == 'challenge') {
        data['challenge_instructions'] = challengeInstructionsCtrl.text;
        data['challenge_starter_code'] = challengeCodeCtrl.text;
        data['challenge_language'] = challengeLanguageCtrl.text;
      }
      if ((lessonType == 'text' || lessonType == 'pdf') && contentCtrl.text.isNotEmpty) {
        data['content'] = contentCtrl.text;
      }

      await api.post(ApiEndpoints.adminElearningModuleLessons(moduleId), data: data);
      await _loadCourse();
      if (mounted) AdminSnackbar.success(context, 'Leçon ajoutée');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _reorderModules() async {
    try {
      final api = getIt<ApiClient>();
      await api.put(
        ApiEndpoints.adminElearningReorderModules(widget.courseId!),
        data: {'module_ids': _modules.map((m) => m['id'] as String).toList()},
      );
    } catch (_) {}
  }

  Future<void> _reorderLessons(String moduleId, List lessons) async {
    try {
      final api = getIt<ApiClient>();
      await api.put(
        ApiEndpoints.adminElearningReorderLessons(moduleId),
        data: {'lesson_ids': lessons.map((l) => l['id'] as String).toList()},
      );
    } catch (_) {}
  }

  Future<void> _deleteLesson(String lessonId) async {
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminElearningLesson(lessonId));
      await _loadCourse();
      if (mounted) AdminSnackbar.success(context, 'Leçon supprimée');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le cours' : 'Nouveau cours'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/elearning/courses')),
        actions: [
          if (_isEditing)
            TextButton.icon(
              icon: Icon(_isPublished ? Icons.visibility_off : Icons.visibility),
              label: Text(_isPublished ? 'Masquer' : 'Publier'),
              onPressed: _togglePublish,
            ),
          if (_isEditing)
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Dupliquer'),
              onPressed: _duplicateCourse,
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isSaving ? null : _saveCourse,
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Informations du cours', style: AppTypography.heading3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre *'))),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(
                    labelText: 'Niveau',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Débutant', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'advanced', child: Text('Avancé', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 4),
            const SizedBox(height: 16),
            // Image du cours (catalogue) : upload + apercu
            Text('Image du cours (catalogue)', style: AppTypography.label),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 120, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  image: _thumbnailCtrl.text.isNotEmpty
                      ? DecorationImage(image: NetworkImage(_thumbnailCtrl.text), fit: BoxFit.cover)
                      : null,
                ),
                child: _thumbnailCtrl.text.isEmpty
                    ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton.icon(
                  icon: _uploadingImage
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload, size: 18),
                  label: Text(_uploadingImage ? 'Téléversement...' : 'Téléverser une image'),
                  onPressed: _uploadingImage ? null : _uploadImage,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _thumbnailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ou coller une URL',
                    isDense: true,
                    prefixIcon: Icon(Icons.link, size: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ])),
            ]),
          ]))),
          const SizedBox(height: 24),
          if (_isEditing) ...[
            // Examen du cours
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.quiz_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Examen final (QCM)', style: AppTypography.heading3),
                Text('Définissez les questions, le score de passage et le badge',
                    style: AppTypography.subtitle),
              ])),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Gérer l\'examen'),
                onPressed: _openExamEditor,
              ),
            ]))),
            const SizedBox(height: 24),
            Row(children: [
              Text('Modules et Leçons', style: AppTypography.heading3),
              const Spacer(),
              ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Module'), onPressed: _addModule),
            ]),
            const SizedBox(height: 16),
            if (_modules.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun module. Ajoutez un module pour commencer.'))))
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _modules.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _modules.removeAt(oldIndex);
                    _modules.insert(newIndex, item);
                  });
                  _reorderModules();
                },
                itemBuilder: (_, i) {
                  final module = _modules[i];
                  final lessons = List.from(module['lessons'] ?? []);
                  return Card(
                    key: ValueKey(module['id']),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(module['title'] ?? ''),
                      subtitle: Text('${lessons.length} leçons'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.drag_handle), tooltip: 'Réordonner', onPressed: () {}),
                        IconButton(icon: const Icon(Icons.add), tooltip: 'Ajouter une leçon', onPressed: () => _addLesson(module['id'])),
                        IconButton(icon: const Icon(Icons.delete, color: AppColors.error), tooltip: 'Supprimer', onPressed: () => _deleteModule(module['id'])),
                      ]),
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lessons.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            final item = lessons.removeAt(oldIndex);
                            lessons.insert(newIndex, item);
                            module['lessons'] = lessons;
                            _reorderLessons(module['id'], lessons);
                          },
                          itemBuilder: (_, j) => ListTile(
                            key: ValueKey(lessons[j]['id']),
                            leading: Icon(_getLessonIcon(lessons[j]['lesson_type'])),
                            title: Text(lessons[j]['title'] ?? ''),
                            subtitle: Text(lessons[j]['lesson_type'] ?? ''),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.drag_handle, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              IconButton(icon: const Icon(Icons.delete, color: AppColors.error, size: 20), onPressed: () => _deleteLesson(lessons[j]['id'])),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ]),
      ),
    );
  }

  IconData _getLessonIcon(String? type) {
    switch (type) {
      case 'video': return Icons.play_circle;
      case 'quiz': return Icons.quiz;
      case 'pdf': return Icons.picture_as_pdf;
      case 'challenge': return Icons.code;
      case 'article': return Icons.article;
      default: return Icons.article;
    }
  }
}