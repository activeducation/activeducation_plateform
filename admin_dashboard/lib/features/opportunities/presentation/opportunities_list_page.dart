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

class OpportunitiesListPage extends StatefulWidget {
  const OpportunitiesListPage({super.key});

  @override
  State<OpportunitiesListPage> createState() => _OpportunitiesListPageState();
}

class _OpportunitiesListPageState extends State<OpportunitiesListPage> {
  List<dynamic> _opportunities = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = true;
  String? _typeFilter;
  bool? _publishedFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final params = <String, dynamic>{
        'page': _page,
        'per_page': 20,
      };
      if (_typeFilter != null) params['opportunity_type'] = _typeFilter;
      if (_publishedFilter != null) params['is_published'] = _publishedFilter;

      final response = await api.get(ApiEndpoints.adminOpportunities, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _opportunities = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePublish(String id, bool current) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch('${ApiEndpoints.adminOpportunityPublish(id)}', data: {'is_published': !current});
      await _load();
      if (mounted) AdminSnackbar.success(context, current ? 'Masqué' : 'Publié');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _toggleFeatured(String id, bool current) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch('${ApiEndpoints.adminOpportunityFeatured(id)}', data: {'is_featured': !current});
      await _load();
      if (mounted) AdminSnackbar.success(context, current ? 'Retiré des featured' : 'Ajouté aux featured');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Supprimer', message: 'Supprimer cette opportunité ?', confirmLabel: 'Supprimer', isDanger: true);
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminOpportunityById(id));
      await _load();
      if (mounted) AdminSnackbar.success(context, 'Supprimée');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / 20).ceil();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Opportunités', style: AppTypography.heading1),
          const Spacer(),
          ElevatedButton.icon(onPressed: () => context.go('/opportunities/new'), icon: const Icon(Icons.add, size: 18), label: const Text('Nouvelle opportunité')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(width: 150, child: DropdownButtonFormField<String?>(
            value: _typeFilter,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: 'internship', child: Text('Stage')),
              DropdownMenuItem(value: 'job', child: Text('Emploi')),
              DropdownMenuItem(value: 'volunteer', child: Text('Bénévolat')),
              DropdownMenuItem(value: 'scholarship', child: Text('Bourse')),
            ],
            onChanged: (v) { setState(() => _typeFilter = v); _load(); },
          )),
          const SizedBox(width: 16),
          SizedBox(width: 150, child: DropdownButtonFormField<bool?>(
            value: _publishedFilter,
            decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: true, child: Text('Publiés')),
              DropdownMenuItem(value: false, child: Text('Brouillon')),
            ],
            onChanged: (v) { setState(() => _publishedFilter = v); _load(); },
          )),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : _opportunities.isEmpty ? const Center(child: Text('Aucune opportunité'))
                : Column(children: [
                    Expanded(child: SingleChildScrollView(child: SizedBox(width: double.infinity, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                      columns: const [
                        DataColumn(label: Text('Titre')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Organisation')),
                        DataColumn(label: Text('Deadline')),
                        DataColumn(label: Text('Statut')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _opportunities.map((o) {
                        final opp = o as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            if (opp['is_featured'] == true) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.star, color: Colors.amber, size: 16)),
                            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(opp['title'] ?? '', overflow: TextOverflow.ellipsis)),
                          ])),
                          DataCell(_buildTypeChip(opp['opportunity_type'])),
                          DataCell(Text(opp['organization_name'] ?? '')),
                          DataCell(Text(opp['application_deadline'] != null ? _formatDate(opp['application_deadline']) : '-')),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            Switch(value: opp['is_published'] ?? false, onChanged: (v) => _togglePublish(opp['id'], opp['is_published'])),
                          ])),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => context.go('/opportunities/${opp['id']}/edit')),
                            IconButton(icon: Icon(opp['is_featured'] == true ? Icons.star : Icons.star_border, size: 18, color: opp['is_featured'] == true ? Colors.amber : null), onPressed: () => _toggleFeatured(opp['id'], opp['is_featured'] ?? false)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: () => _delete(opp['id'])),
                          ])),
                        ]);
                      }).toList(),
                    )))),
                    if (totalPages > 1) Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < totalPages ? () { _page++; _load(); } : null),
                    ])),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTypeChip(String? type) {
    Color color;
    String label;
    switch (type) {
      case 'internship': color = Colors.blue; label = 'Stage';
      case 'job': color = Colors.green; label = 'Emploi';
      case 'volunteer': color = Colors.purple; label = 'Bénévolat';
      case 'scholarship': color = Colors.orange; label = 'Bourse';
      default: color = Colors.grey; label = type ?? '';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(color: color, fontSize: 12)));
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return date; }
  }
}