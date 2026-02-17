import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<dynamic> _announcements = [];
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
      final response = await api.get(ApiEndpoints.adminAnnouncements, queryParameters: {'page': _page, 'per_page': 20});
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _announcements = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl = TextEditingController(text: existing?['content'] ?? '');
    String type = existing?['type'] ?? 'info';
    String audience = existing?['target_audience'] ?? 'all';
    bool isActive = existing?['is_active'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Modifier l\'annonce' : 'Nouvelle annonce'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre *')),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Contenu *'), maxLines: 4),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AdminConstants.announcementTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                )),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  items: AdminConstants.targetAudiences.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => audience = v!),
                )),
              ]),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing != null ? 'Modifier' : 'Creer')),
          ],
        ),
      ),
    );
    if (result != true) return;

    final data = {
      'title': titleCtrl.text, 'content': contentCtrl.text,
      'type': type, 'target_audience': audience, 'is_active': isActive,
    };

    try {
      final api = getIt<ApiClient>();
      if (existing != null) {
        await api.put(ApiEndpoints.adminAnnouncementById(existing['id']), data: data);
      } else {
        await api.post(ApiEndpoints.adminAnnouncements, data: data);
      }
      if (mounted) AdminSnackbar.success(context, 'Sauvegarde');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Supprimer', message: 'Supprimer cette annonce ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminAnnouncementById(id));
      if (mounted) AdminSnackbar.success(context, 'Supprimee');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / 20).ceil();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Annonces', style: AppTypography.heading1),
            const Spacer(),
            ElevatedButton.icon(onPressed: () => _createOrEdit(), icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter')),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading ? const Center(child: CircularProgressIndicator())
                  : Column(children: [
                      Expanded(child: SingleChildScrollView(child: SizedBox(width: double.infinity, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                        columns: const [
                          DataColumn(label: Text('Titre')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Audience')),
                          DataColumn(label: Text('Active')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _announcements.map((a) {
                          final ann = a as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(ann['title'] ?? '')),
                            DataCell(Text(ann['type'] ?? '')),
                            DataCell(Text(ann['target_audience'] ?? '')),
                            DataCell(Icon(ann['is_active'] == true ? Icons.check_circle : Icons.cancel,
                                color: ann['is_active'] == true ? AppColors.success : AppColors.textMuted, size: 20)),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _createOrEdit(existing: ann)),
                              IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: () => _delete(ann['id'])),
                            ])),
                          ]);
                        }).toList(),
                      )))),
                      if (totalPages > 1)
                        Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < totalPages ? () { _page++; _load(); } : null),
                        ])),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}
