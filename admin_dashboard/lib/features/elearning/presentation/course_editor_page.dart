import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

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
      _level = data['level'] ?? 'beginner';
      _isPublished = data['is_published'] ?? false;
      _selectedSchoolId = data['school_id'];
      _modules = List.from(data['modules'] ?? []);
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    setState(() => _isLoading = false);
  }

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
        'level': _level,
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle leçon'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: lessonType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                  DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                ],
                onChanged: (v) => setDialogState(() => lessonType = v!),
              ),
              const SizedBox(height: 12),
              if (lessonType == 'text')
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Contenu'), maxLines: 4),
              if (lessonType == 'video')
                TextField(controller: videoCtrl, decoration: const InputDecoration(labelText: 'URL vidéo')),
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
      final data = {
        'title': titleCtrl.text,
        'lesson_type': lessonType,
        'display_order': 0,
      };
      if (lessonType == 'text' && contentCtrl.text.isNotEmpty) {
        data['content'] = contentCtrl.text;
      }
      if (lessonType == 'video' && videoCtrl.text.isNotEmpty) {
        data['video_url'] = videoCtrl.text;
      }

      await api.post(ApiEndpoints.adminElearningModuleLessons(moduleId), data: data);
      await _loadCourse();
      if (mounted) AdminSnackbar.success(context, 'Leçon ajoutée');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
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
              SizedBox(width: 150, child: DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(labelText: 'Niveau'),
                items: const [
                  DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                  DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                  DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                ],
                onChanged: (v) => setState(() => _level = v!),
              )),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 4),
            const SizedBox(height: 16),
            TextField(controller: _thumbnailCtrl, decoration: const InputDecoration(labelText: 'URL miniature', prefixIcon: Icon(Icons.image))),
          ]))),
          const SizedBox(height: 24),
          if (_isEditing) ...[
            Row(children: [
              Text('Modules et Leçons', style: AppTypography.heading3),
              const Spacer(),
              ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Module'), onPressed: _addModule),
            ]),
            const SizedBox(height: 16),
            if (_modules.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun module. Ajoutez un module pour commencer.'))))
            else
              ...List.generate(_modules.length, (i) {
                final module = _modules[i];
                final lessons = List.from(module['lessons'] ?? []);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(module['title'] ?? ''),
                    subtitle: Text('${lessons.length} leçons'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.add), tooltip: 'Ajouter une leçon', onPressed: () => _addLesson(module['id'])),
                      IconButton(icon: const Icon(Icons.delete, color: AppColors.error), tooltip: 'Supprimer', onPressed: () => _deleteModule(module['id'])),
                    ]),
                    children: lessons.map<Widget>((lesson) => ListTile(
                      leading: Icon(_getLessonIcon(lesson['lesson_type'])),
                      title: Text(lesson['title'] ?? ''),
                      subtitle: Text(lesson['lesson_type'] ?? ''),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: AppColors.error, size: 20), onPressed: () => _deleteLesson(lesson['id'])),
                    )).toList(),
                  ),
                );
              }),
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
      default: return Icons.article;
    }
  }
}