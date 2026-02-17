import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<dynamic> _challenges = [];
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
      final response = await api.get(ApiEndpoints.adminChallenges);
      setState(() { _challenges = response.data as List? ?? []; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final typeCtrl = TextEditingController(text: existing?['challenge_type'] ?? 'weekly');
    final pointsCtrl = TextEditingController(text: '${existing?['points_reward'] ?? 50}');
    final reqTypeCtrl = TextEditingController(text: existing?['requirement_type'] ?? '');
    final reqValCtrl = TextEditingController(text: '${existing?['requirement_value'] ?? 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Modifier' : 'Nouveau challenge'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (daily/weekly/special)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: 'Points'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: reqTypeCtrl, decoration: const InputDecoration(labelText: 'Type requis'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: reqValCtrl, decoration: const InputDecoration(labelText: 'Valeur'), keyboardType: TextInputType.number)),
            ]),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing != null ? 'Modifier' : 'Creer')),
        ],
      ),
    );
    if (result != true) return;

    final data = {
      'name': nameCtrl.text, 'description': descCtrl.text, 'challenge_type': typeCtrl.text,
      'points_reward': int.tryParse(pointsCtrl.text) ?? 50,
      'requirement_type': reqTypeCtrl.text, 'requirement_value': int.tryParse(reqValCtrl.text) ?? 1,
    };

    try {
      final api = getIt<ApiClient>();
      if (existing != null) {
        await api.put(ApiEndpoints.adminChallengeById(existing['id']), data: data);
      } else {
        await api.post(ApiEndpoints.adminChallenges, data: data);
      }
      if (mounted) AdminSnackbar.success(context, 'Sauvegarde');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Supprimer', message: 'Supprimer ce challenge ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminChallengeById(id));
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
            Text('Challenges', style: AppTypography.heading1),
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
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Points')),
                        DataColumn(label: Text('Actif')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _challenges.map((c) {
                        final ch = c as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(ch['name'] ?? '')),
                          DataCell(Text(ch['challenge_type'] ?? '')),
                          DataCell(Text('${ch['points_reward'] ?? 0}')),
                          DataCell(Icon(ch['is_active'] == true ? Icons.check_circle : Icons.cancel,
                              color: ch['is_active'] == true ? AppColors.success : AppColors.textMuted, size: 20)),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _createOrEdit(existing: ch)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: () => _delete(ch['id'])),
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
