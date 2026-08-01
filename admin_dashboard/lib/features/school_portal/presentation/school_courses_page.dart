import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class SchoolCoursesPage extends StatefulWidget {
  const SchoolCoursesPage({super.key});

  @override
  State<SchoolCoursesPage> createState() => _SchoolCoursesPageState();
}

class _SchoolCoursesPageState extends State<SchoolCoursesPage> {
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.schoolCourses);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _courses = data['courses'] as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePublish(String id, bool current) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.schoolCoursePublish(id), data: {'is_published': !current});
      await _load();
      if (mounted) AdminSnackbar.success(context, current ? 'Cours masqué' : 'Cours publié');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id, String title) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Supprimer', message: 'Supprimer "$title" ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.schoolCourseById(id));
      await _load();
      if (mounted) AdminSnackbar.success(context, 'Cours supprimé');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau cours'),
            onPressed: () => context.go('/school-portal/courses/new'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.school_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Aucun cours', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Créez votre premier cours e-learning'),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: () => context.go('/school-portal/courses/new'), icon: const Icon(Icons.add), label: const Text('Créer un cours')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => context.go('/school-portal/courses/${course['id']}/edit'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60, height: 60,
                              child: course['thumbnail_url'] != null && course['thumbnail_url'].toString().isNotEmpty
                                  ? Image.network(course['thumbnail_url'], fit: BoxFit.cover, errorBuilder: (_, e, s) => Container(
                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
                                      child: const Icon(Icons.school_rounded, color: AppColors.primary),
                                    ))
                                  : Container(
                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
                                      child: const Icon(Icons.school_rounded, color: AppColors.primary),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${course['modules_count'] ?? 0} modules • ${course['lessons_count'] ?? 0} leçons', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: course['is_published'] == true ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(course['is_published'] == true ? 'Publié' : 'Brouillon', style: TextStyle(fontSize: 12, color: course['is_published'] == true ? Colors.green : Colors.orange)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(course['is_published'] == true ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => _togglePublish(course['id'], course['is_published'] ?? false),
                            tooltip: course['is_published'] == true ? 'Masquer' : 'Publier',
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(course['id'], course['title'] ?? '')),
                        ])),
                      ),
                    );
                  },
                ),
    );
  }
}