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

class CareersListPage extends StatefulWidget {
  const CareersListPage({super.key});

  @override
  State<CareersListPage> createState() => _CareersListPageState();
}

class _CareersListPageState extends State<CareersListPage> {
  List<dynamic> _careers = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = true;
  String? _searchQuery;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCareers() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_searchQuery != null && _searchQuery!.isNotEmpty) params['search'] = _searchQuery;

      final response = await api.get(ApiEndpoints.adminCareers, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _careers = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCareer(String id) async {
    final confirmed = await ConfirmDialog.show(context,
        title: 'Supprimer', message: 'Supprimer cette carriere ?',
        confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminCareerById(id));
      if (mounted) AdminSnackbar.success(context, 'Carriere supprimee');
      _loadCareers();
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
                  Text('Carrieres', style: AppTypography.heading1),
                  Text('$_total carrieres', style: AppTypography.subtitle),
                ],
              )),
              ElevatedButton.icon(
                onPressed: () => context.go('/careers/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search), isDense: true),
                      onSubmitted: (v) { _searchQuery = v; _page = 1; _loadCareers(); },
                    ),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCareers),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                                  DataColumn(label: Text('Secteur')),
                                  DataColumn(label: Text('Demande')),
                                  DataColumn(label: Text('Tendance')),
                                  DataColumn(label: Text('Salaire moy.')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _careers.map((c) {
                                  final career = c as Map<String, dynamic>;
                                  return DataRow(cells: [
                                    DataCell(Text(career['name'] ?? '')),
                                    DataCell(Text(career['sector_name'] ?? '')),
                                    DataCell(_DemandChip(demand: career['job_demand'])),
                                    DataCell(Text(career['growth_trend'] ?? '-')),
                                    DataCell(Text(career['salary_avg_fcfa'] != null
                                        ? '${career['salary_avg_fcfa']} FCFA' : '-')),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () => context.go('/careers/${career['id']}/edit')),
                                        IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                          onPressed: () => _deleteCareer(career['id'])),
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
                                    onPressed: _page > 1 ? () { _page--; _loadCareers(); } : null),
                                IconButton(icon: const Icon(Icons.chevron_right),
                                    onPressed: _page < totalPages ? () { _page++; _loadCareers(); } : null),
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

class _DemandChip extends StatelessWidget {
  final String? demand;
  const _DemandChip({this.demand});

  @override
  Widget build(BuildContext context) {
    if (demand == null) return const Text('-');
    final color = switch (demand) { 'high' => AppColors.success, 'low' => AppColors.error, _ => AppColors.warning };
    final label = switch (demand) { 'high' => 'Forte', 'low' => 'Faible', _ => 'Moyenne' };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
