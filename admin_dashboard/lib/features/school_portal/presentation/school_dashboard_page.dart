import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/auth/token_storage.dart';

class SchoolDashboardPage extends StatefulWidget {
  const SchoolDashboardPage({super.key});

  @override
  State<SchoolDashboardPage> createState() => _SchoolDashboardPageState();
}

class _SchoolDashboardPageState extends State<SchoolDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.schoolDashboard);
      setState(() {
        _stats = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenStorage = getIt<TokenStorage>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bienvenue, ${tokenStorage.userName}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tokenStorage.schoolName ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted)),
            ])),
            FilledButton.icon(
              onPressed: () => context.go('/school-portal/courses/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau cours'),
            ),
          ]),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(children: [
              Expanded(child: _buildStatCard('Cours', _stats?['total_courses']?.toString() ?? '0', Icons.school_rounded, AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Modules', _stats?['total_modules']?.toString() ?? '0', Icons.view_module_rounded, Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Leçons', _stats?['total_lessons']?.toString() ?? '0', Icons.play_circle_rounded, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Étudiants', _stats?['total_students']?.toString() ?? '0', Icons.people_rounded, Colors.green)),
            ]),
          const SizedBox(height: 32),
          Text('Cours récents', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildRecentCourses(),
        ]),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      ])),
    );
  }

  Widget _buildRecentCourses() {
    return FutureBuilder(
      future: getIt<ApiClient>().get(ApiEndpoints.schoolCourses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.data == null) {
          return const Center(child: Text('Aucun cours'));
        }
        final courses = (snapshot.data!.data as Map<String, dynamic>)['courses'] as List? ?? [];
        if (courses.isEmpty) {
          return Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
            const Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Aucun cours pour le moment'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/school-portal/courses/new'), child: const Text('Créer mon premier cours')),
          ])));
        }
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index] as Map<String, dynamic>;
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  child: InkWell(
                    onTap: () => context.go('/school-portal/courses/${course['id']}/edit'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 36, height: 36,
                            child: course['thumbnail_url'] != null && course['thumbnail_url'].toString().isNotEmpty
                                ? Image.network(course['thumbnail_url'], fit: BoxFit.cover, errorBuilder: (_, e, s) => Container(
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
                                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                                  ))
                                : Container(
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
                                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                                  ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: course['is_published'] == true ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(course['is_published'] == true ? 'Publié' : 'Brouillon', style: TextStyle(fontSize: 11, color: course['is_published'] == true ? Colors.green : Colors.orange)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text('${course['modules_count'] ?? 0} modules • ${course['lessons_count'] ?? 0} leçons', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ])),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}