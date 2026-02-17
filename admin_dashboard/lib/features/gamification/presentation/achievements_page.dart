import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<dynamic> _achievements = [];
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
      final response = await api.get(ApiEndpoints.adminAchievements);
      setState(() { _achievements = response.data as List? ?? []; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final iconCtrl = TextEditingController(text: existing?['icon'] ?? '');
    final categoryCtrl = TextEditingController(text: existing?['category'] ?? '');
    final pointsCtrl = TextEditingController(text: '${existing?['points_reward'] ?? 0}');
    final reqTypeCtrl = TextEditingController(text: existing?['requirement_type'] ?? '');
    final reqValCtrl = TextEditingController(text: '${existing?['requirement_value'] ?? 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Modifier' : 'Nouveau achievement'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icone'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Categorie'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: 'Points'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: reqTypeCtrl, decoration: const InputDecoration(labelText: 'Type requis'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: reqValCtrl, decoration: const InputDecoration(labelText: 'Valeur requise'), keyboardType: TextInputType.number)),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing != null ? 'Modifier' : 'Creer')),
        ],
      ),
    );
    if (result != true) return;

    final data = {
      'name': nameCtrl.text, 'description': descCtrl.text, 'icon': iconCtrl.text,
      'category': categoryCtrl.text, 'points_reward': int.tryParse(pointsCtrl.text) ?? 0,
      'requirement_type': reqTypeCtrl.text, 'requirement_value': int.tryParse(reqValCtrl.text) ?? 1,
    };

    try {
      final api = getIt<ApiClient>();
      if (existing != null) {
        await api.put(ApiEndpoints.adminAchievementById(existing['id']), data: data);
      } else {
        await api.post(ApiEndpoints.adminAchievements, data: data);
      }
      if (mounted) AdminSnackbar.success(context, 'Sauvegarde');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Supprimer', message: 'Supprimer cet achievement ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminAchievementById(id));
      if (mounted) AdminSnackbar.success(context, 'Supprime');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Achievements', style: AppTypography.heading1),
            const Spacer(),
            ElevatedButton.icon(onPressed: () => _createOrEdit(), icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter')),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(child: SizedBox(width: double.infinity, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                      columns: const [
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text('Categorie')),
                        DataColumn(label: Text('Points')),
                        DataColumn(label: Text('Condition')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _achievements.map((a) {
                        final ach = a as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(ach['name'] ?? '')),
                          DataCell(Text(ach['category'] ?? '')),
                          DataCell(Text('${ach['points_reward'] ?? 0}')),
                          DataCell(Text('${ach['requirement_type'] ?? ''} >= ${ach['requirement_value'] ?? 0}')),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _createOrEdit(existing: ach)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: () => _delete(ach['id'])),
                          ])),
                        ]);
                      }).toList(),
                    ))),
            ),
          ),
        ],
      ),
    );
  }
}
