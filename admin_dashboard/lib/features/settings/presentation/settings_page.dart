import 'package:flutter/material.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<dynamic> _settings = [];
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
      final response = await api.get(ApiEndpoints.adminSettings);
      setState(() { _settings = response.data as List? ?? []; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editSetting(Map<String, dynamic> setting) async {
    final ctrl = TextEditingController(text: '${setting['value'] ?? ''}');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier: ${setting['key']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (setting['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(setting['description'], style: AppTypography.bodySmall),
                ),
              TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Valeur'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sauvegarder')),
        ],
      ),
    );
    if (result != true) return;

    try {
      final api = getIt<ApiClient>();
      await api.put(ApiEndpoints.adminSettingByKey(setting['key']), data: {'value': ctrl.text});
      if (mounted) AdminSnackbar.success(context, 'Parametre sauvegarde');
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
          Text('Parametres', style: AppTypography.heading1),
          Text('Configuration de l\'application', style: AppTypography.subtitle),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _settings.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final s = _settings[i] as Map<String, dynamic>;
                        return ListTile(
                          title: Text(s['key'] ?? '', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s['description'] != null)
                                Text(s['description'], style: AppTypography.bodySmall),
                              const SizedBox(height: 4),
                              Text('Valeur: ${s['value']}', style: AppTypography.body),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editSetting(s),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
