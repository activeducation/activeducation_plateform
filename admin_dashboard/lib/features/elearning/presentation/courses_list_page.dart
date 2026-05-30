import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../domain/entities/admin_course.dart';
import '../domain/repositories/elearning_repository.dart';
import 'bloc/courses_bloc.dart';

class CoursesListPage extends StatelessWidget {
  const CoursesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CoursesBloc(getIt<ElearningRepository>())
        ..add(const LoadCourses())
        ..add(LoadSchoolsWithCourses()),
      child: const _CoursesListView(),
    );
  }
}

class _CoursesListView extends StatefulWidget {
  const _CoursesListView();

  @override
  State<_CoursesListView> createState() => _CoursesListViewState();
}

class _CoursesListViewState extends State<_CoursesListView> {
  final _searchController = TextEditingController();
  String? _selectedSchoolId;
  bool? _selectedPublished;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<CoursesBloc>().add(LoadCourses(
          search: _searchController.text,
          schoolId: _selectedSchoolId,
          isPublished: _selectedPublished,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours E-Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CoursesBloc>().add(const LoadCourses()),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau cours'),
            onPressed: () => context.go('/elearning/courses/new'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocConsumer<CoursesBloc, CoursesState>(
              listener: (context, state) {
                if (state is CourseDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cours supprimé')),
                  );
                }
                if (state is CoursesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is CoursesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CoursesLoaded) {
                  if (state.courses.items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'Aucun cours',
                      subtitle: 'Aucun cours e-learning trouvé',
                    );
                  }
                  return _buildCoursesList(state.courses, state.schools);
                }
                return const Center(child: Text('Une erreur est survenue'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return BlocBuilder<CoursesBloc, CoursesState>(
      builder: (context, state) {
        final schools = state is CoursesLoaded ? state.schools : <SchoolWithCourses>[];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un cours...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedSchoolId,
                  decoration: const InputDecoration(
                    labelText: 'École',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes')),
                    ...schools.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedSchoolId = v);
                    _search();
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<bool?>(
                  initialValue: _selectedPublished,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    DropdownMenuItem(value: true, child: Text('Publiés')),
                    DropdownMenuItem(value: false, child: Text('Brouillon')),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedPublished = v);
                    _search();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursesList(PaginatedCourses courses, List<SchoolWithCourses> schools) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.items.length,
      itemBuilder: (context, index) {
        final course = courses.items[index];
        return _CourseCard(
          course: course,
          onDelete: () => _confirmDelete(course),
        );
      },
    );
  }

  void _confirmDelete(AdminCourse course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Voulez-vous vraiment supprimer "${course.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CoursesBloc>().add(DeleteCourse(course.id));
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AdminCourse course;
  final VoidCallback onDelete;

  const _CourseCard({required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/elearning/courses/${course.id}/edit'),
        child: ListTile(
        leading: course.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  course.thumbnailUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.school),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school),
              ),
        title: Text(
          course.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.schoolName != null)
              Text(
                course.schoolName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  context,
                  '${course.modulesCount ?? 0} modules',
                  Icons.view_module,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  context,
                  '${course.lessonsCount ?? 0} leçons',
                  Icons.play_circle_outline,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: course.isPublished
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                course.isPublished ? 'Publié' : 'Brouillon',
                style: TextStyle(
                  color: course.isPublished ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}