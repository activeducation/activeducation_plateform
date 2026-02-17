import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class TestsListPage extends StatefulWidget {
  const TestsListPage({super.key});

  @override
  State<TestsListPage> createState() => _TestsListPageState();
}

class _TestsListPageState extends State<TestsListPage> {
  List<dynamic> _tests = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminTests, queryParameters: {'page': _page, 'per_page': 20});
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _tests = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _duplicateTest(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminTestDuplicate(id));
      if (mounted) AdminSnackbar.success(context, 'Test duplique');
      _loadTests();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _deleteTest(String id) async {
    final confirmed = await ConfirmDialog.show(context,
        title: 'Supprimer', message: 'Supprimer ce test et toutes ses questions ?',
        confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminTestById(id));
      if (mounted) AdminSnackbar.success(context, 'Test supprime');
      _loadTests();
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
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tests d\'orientation', style: AppTypography.heading1),
                  Text('$_total tests', style: AppTypography.subtitle),
                ],
              )),
              ElevatedButton.icon(
                onPressed: () => context.go('/tests/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau test'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                                columns: const [
                                  DataColumn(label: Text('Nom')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Duree')),
                                  DataColumn(label: Text('Questions')),
                                  DataColumn(label: Text('Sessions')),
                                  DataColumn(label: Text('Actif')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _tests.map((t) {
                                  final test = t as Map<String, dynamic>;
                                  return DataRow(cells: [
                                    DataCell(Text(test['name'] ?? '')),
                                    DataCell(Text(test['type'] ?? '')),
                                    DataCell(Text('${test['duration_minutes'] ?? 15} min')),
                                    DataCell(Text('${test['questions_count'] ?? 0}')),
                                    DataCell(Text('${test['sessions_count'] ?? 0}')),
                                    DataCell(Icon(
                                      test['is_active'] == true ? Icons.check_circle : Icons.cancel,
                                      color: test['is_active'] == true ? AppColors.success : AppColors.textMuted,
                                      size: 20,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () => context.go('/tests/${test['id']}/edit')),
                                        IconButton(icon: const Icon(Icons.copy, size: 18),
                                            onPressed: () => _duplicateTest(test['id']),
                                            tooltip: 'Dupliquer'),
                                        IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                            onPressed: () => _deleteTest(test['id'])),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                                IconButton(icon: const Icon(Icons.chevron_left),
                                    onPressed: _page > 1 ? () { _page--; _loadTests(); } : null),
                                IconButton(icon: const Icon(Icons.chevron_right),
                                    onPressed: _page < totalPages ? () { _page++; _loadTests(); } : null),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
