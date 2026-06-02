import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class MentorsListPage extends StatefulWidget {
  const MentorsListPage({super.key});

  @override
  State<MentorsListPage> createState() => _MentorsListPageState();
}

class _MentorsListPageState extends State<MentorsListPage> {
  List<dynamic> _mentors = [];
  int _total = 0;
  int _page = 1;
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
      final response = await api.get(ApiEndpoints.adminMentors, queryParameters: {'page': _page, 'per_page': 20});
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _mentors = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVerify(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorVerify(id));
      if (mounted) AdminSnackbar.success(context, 'Statut mis a jour');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _toggleActive(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorToggleActive(id));
      if (mounted) AdminSnackbar.success(context, 'Statut mis a jour');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _showCreateMentorDialog() async {
    final fullName = TextEditingController();
    final specialty = TextEditingController();
    final email = TextEditingController();
    final experience = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer un mentor'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Nom complet *')),
              const SizedBox(height: 10),
              TextField(controller: specialty, decoration: const InputDecoration(labelText: 'Spécialité *')),
              const SizedBox(height: 10),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(controller: experience, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Années d'expérience")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (created != true) return;
    if (fullName.text.trim().isEmpty || specialty.text.trim().isEmpty) {
      if (mounted) AdminSnackbar.error(context, 'Nom et spécialité requis');
      return;
    }
    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminMentors, data: {
        'full_name': fullName.text.trim(),
        'specialty': specialty.text.trim(),
        if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
        if (experience.text.trim().isNotEmpty)
          'years_experience': int.tryParse(experience.text.trim()),
      });
      if (mounted) AdminSnackbar.success(context, 'Mentor créé');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Création impossible');
    }
  }

  Future<void> _showTasksSheet(String mentorId, String mentorName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MentorTasksSheet(mentorId: mentorId, mentorName: mentorName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / 20).ceil();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mentors', style: AppTypography.heading1),
                    Text('$_total mentors', style: AppTypography.subtitle),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer un mentor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _showCreateMentorDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading ? const Center(child: CircularProgressIndicator())
                  : Column(children: [
                      Expanded(child: SingleChildScrollView(child: SizedBox(width: double.infinity, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                        columns: const [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Profession')),
                          DataColumn(label: Text('Entreprise')),
                          DataColumn(label: Text('Experience')),
                          DataColumn(label: Text('Mentees')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Verifie')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _mentors.map((m) {
                          final mentor = m as Map<String, dynamic>;
                          final userInfo = mentor['user_profiles'] as Map<String, dynamic>? ?? {};
                          final name = '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'.trim();
                          return DataRow(cells: [
                            DataCell(Text(name.isEmpty ? userInfo['email'] ?? '-' : name)),
                            DataCell(Text(mentor['profession'] ?? '')),
                            DataCell(Text(mentor['company'] ?? '-')),
                            DataCell(Text('${mentor['years_experience'] ?? '-'} ans')),
                            DataCell(Text('${mentor['current_mentees'] ?? 0}/${mentor['max_mentees'] ?? 5}')),
                            DataCell(Text('${mentor['rating_avg'] ?? '-'}')),
                            DataCell(Icon(
                              mentor['is_verified'] == true ? Icons.verified : Icons.cancel_outlined,
                              color: mentor['is_verified'] == true ? AppColors.success : AppColors.textMuted,
                              size: 20,
                            )),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: Icon(mentor['is_verified'] == true ? Icons.verified : Icons.verified_outlined,
                                    size: 18, color: AppColors.primary),
                                onPressed: () => _toggleVerify(mentor['id']),
                                tooltip: 'Verifier',
                              ),
                              IconButton(
                                icon: Icon(mentor['is_active'] == true ? Icons.block : Icons.check_circle,
                                    size: 18, color: mentor['is_active'] == true ? AppColors.error : AppColors.success),
                                onPressed: () => _toggleActive(mentor['id']),
                                tooltip: mentor['is_active'] == true ? 'Desactiver' : 'Activer',
                              ),
                              IconButton(
                                icon: const Icon(Icons.task_alt, size: 18, color: AppColors.secondary),
                                onPressed: () => _showTasksSheet(
                                    mentor['id'].toString(),
                                    name.isEmpty ? (userInfo['email'] ?? 'Mentor') : name),
                                tooltip: 'Tâches',
                              ),
                            ])),
                          ]);
                        }).toList(),
                      )))),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
                            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < totalPages ? () { _page++; _load(); } : null),
                          ]),
                        ),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet de gestion des taches d'un mentor (liste + ajout + statut).
class _MentorTasksSheet extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  const _MentorTasksSheet({required this.mentorId, required this.mentorName});

  @override
  State<_MentorTasksSheet> createState() => _MentorTasksSheetState();
}

class _MentorTasksSheetState extends State<_MentorTasksSheet> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.get(ApiEndpoints.adminMentorTasks(widget.mentorId));
      setState(() {
        _tasks = (res.data['items'] ?? []) as List;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    String priority = 'normal';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nouvelle tâche'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Titre *')),
                const SizedBox(height: 10),
                TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priorité'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'normal', child: Text('Normale')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                  ],
                  onChanged: (v) => setSt(() => priority = v ?? 'normal'),
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
    if (ok != true || title.text.trim().isEmpty) return;
    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminMentorTasks(widget.mentorId), data: {
        'title': title.text.trim(),
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
        'priority': priority,
      });
      if (mounted) AdminSnackbar.success(context, 'Tâche ajoutée');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Ajout impossible');
    }
  }

  Future<void> _setStatus(String taskId, String status) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorTaskById(taskId), data: {'status': status});
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Mise à jour impossible');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Tâches — ${widget.mentorName}',
                    style: AppTypography.heading3),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                onPressed: _addTask,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucune tâche assignée', style: AppTypography.subtitle)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _tasks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final t = _tasks[i] as Map<String, dynamic>;
                  final done = t['status'] == 'done';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: done,
                      onChanged: (v) => _setStatus(
                          t['id'].toString(), (v ?? false) ? 'done' : 'todo'),
                    ),
                    title: Text(
                      t['title'] ?? '',
                      style: AppTypography.body.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: (t['description'] ?? '').toString().isNotEmpty
                        ? Text(t['description'], style: AppTypography.bodySmall)
                        : null,
                    trailing: _priorityBadge(t['priority'] ?? 'normal'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String p) {
    final (color, label) = switch (p) {
      'high' => (AppColors.error, 'Haute'),
      'low' => (AppColors.textMuted, 'Basse'),
      _ => (AppColors.primary, 'Normale'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTypography.label.copyWith(color: color)),
    );
  }
}
