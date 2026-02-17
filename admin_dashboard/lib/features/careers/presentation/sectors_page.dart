import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class SectorsPage extends StatefulWidget {
  const SectorsPage({super.key});

  @override
  State<SectorsPage> createState() => _SectorsPageState();
}

class _SectorsPageState extends State<SectorsPage> {
  List<dynamic> _sectors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSectors();
  }

  Future<void> _loadSectors() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminSectors);
      setState(() {
        _sectors = response.data as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final iconCtrl = TextEditingController(text: existing?['icon'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Modifier le secteur' : 'Nouveau secteur'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing != null ? 'Modifier' : 'Creer')),
        ],
      ),
    );
    if (result != true || nameCtrl.text.isEmpty) return;

    try {
      final api = getIt<ApiClient>();
      final data = {'name': nameCtrl.text, 'description': descCtrl.text, 'icon': iconCtrl.text};
      if (existing != null) {
        await api.put(ApiEndpoints.adminSectorById(existing['id']), data: data);
      } else {
        await api.post(ApiEndpoints.adminSectors, data: data);
      }
      if (mounted) AdminSnackbar.success(context, existing != null ? 'Modifie' : 'Cree');
      _loadSectors();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await ConfirmDialog.show(context,
        title: 'Supprimer', message: 'Supprimer ce secteur ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminSectorById(id));
      if (mounted) AdminSnackbar.success(context, 'Supprime');
      _loadSectors();
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
          Row(
            children: [
              Text('Secteurs d\'activite', style: AppTypography.heading1),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _createOrEdit(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Icone')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _sectors.map((s) {
                            final sector = s as Map<String, dynamic>;
                            return DataRow(cells: [
                              DataCell(Text(sector['name'] ?? '')),
                              DataCell(Text(sector['description'] ?? '', overflow: TextOverflow.ellipsis)),
                              DataCell(Text(sector['icon'] ?? '-')),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _createOrEdit(existing: sector)),
                                  IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                      onPressed: () => _delete(sector['id'])),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
