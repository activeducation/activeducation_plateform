import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class SchoolsListPage extends StatefulWidget {
  const SchoolsListPage({super.key});

  @override
  State<SchoolsListPage> createState() => _SchoolsListPageState();
}

class _SchoolsListPageState extends State<SchoolsListPage> {
  List<dynamic> _schools = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = true;
  String? _searchQuery;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_searchQuery != null && _searchQuery!.isNotEmpty) params['search'] = _searchQuery;

      final response = await api.get(ApiEndpoints.adminSchools, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _schools = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
  }

  Future<void> _toggleVerify(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminSchoolVerify(id));
      if (mounted) AdminSnackbar.success(context, 'Verification mise a jour');
      _loadSchools();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _toggleActive(String id, bool currentlyActive) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminSchoolToggleActive(id));
      if (mounted) {
        AdminSnackbar.success(
          context,
          currentlyActive ? 'Ecole desactivee' : 'Ecole activee',
        );
      }
      _loadSchools();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _deleteSchool(String id, String name) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer "$name"',
      message: 'Cette action supprimera l\'ecole et toutes ses filieres. Cette action est irreversible.',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminSchoolById(id));
      if (mounted) AdminSnackbar.success(context, 'Ecole supprimee');
      _loadSchools();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de suppression');
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
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ecoles & Universites', style: AppTypography.heading1),
                    Text('$_total etablissements', style: AppTypography.subtitle),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/schools/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un etablissement'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher par nom ou ville...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        _searchQuery = v;
                        _page = 1;
                        _loadSchools();
                      },
                    ),
                  ),
                  if (_searchQuery != null && _searchQuery!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text('Effacer: "$_searchQuery"'),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = null;
                        _page = 1;
                        _loadSchools();
                      },
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSchools,
                    tooltip: 'Rafraichir',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Card(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _schools.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('Aucun etablissement trouve', style: AppTypography.subtitle),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/schools/new'),
                                child: const Text('Creer un etablissement'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                                    columns: const [
                                      DataColumn(label: Text('Etablissement')),
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Ville')),
                                      DataColumn(label: Text('Frais'), numeric: true),
                                      DataColumn(label: Text('Filieres'), numeric: true),
                                      DataColumn(label: Text('Etudiants'), numeric: true),
                                      DataColumn(label: Text('Statut')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _schools.map((s) {
                                      final school = s as Map<String, dynamic>;
                                      final isActive = school['is_active'] ?? true;
                                      final isVerified = school['is_verified'] ?? false;
                                      final accreditations = (school['accreditations'] as List?)?.cast<String>() ?? [];

                                      return DataRow(
                                        color: WidgetStateProperty.resolveWith((_) {
                                          if (!isActive) return AppColors.error.withValues(alpha: 0.05);
                                          return null;
                                        }),
                                        cells: [
                                          // Nom + accreditations
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Logo thumbnail
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: school['logo_url'] != null
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(6),
                                                          child: Image.network(
                                                            school['logo_url'],
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 16, color: AppColors.textMuted),
                                                          ),
                                                        )
                                                      : const Icon(Icons.school, size: 16, color: AppColors.textMuted),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      school['name'] ?? '',
                                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    if (accreditations.isNotEmpty)
                                                      Text(
                                                        accreditations.join(', '),
                                                        style: TextStyle(fontSize: 11, color: AppColors.success),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Type
                                          DataCell(Text(
                                            AdminConstants.schoolTypeLabels[school['type']] ?? school['type'] ?? '',
                                            style: AppTypography.bodySmall,
                                          )),
                                          // Ville
                                          DataCell(Text(school['city'] ?? '')),
                                          // Frais
                                          DataCell(Text(
                                            school['tuition_range'] ?? '-',
                                            style: AppTypography.bodySmall,
                                          )),
                                          // Filieres
                                          DataCell(Text('${school['programs_count'] ?? 0}')),
                                          // Etudiants
                                          DataCell(Text(
                                            school['student_count'] != null
                                                ? '${school['student_count']}'
                                                : '-',
                                          )),
                                          // Statut
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isVerified)
                                                Tooltip(
                                                  message: 'Verifiee',
                                                  child: Icon(Icons.verified, size: 18, color: AppColors.success),
                                                ),
                                              if (!isActive)
                                                Tooltip(
                                                  message: 'Inactive',
                                                  child: Container(
                                                    margin: const EdgeInsets.only(left: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text('Inactive', style: TextStyle(fontSize: 10, color: AppColors.error)),
                                                  ),
                                                ),
                                              if (isActive && !isVerified)
                                                Text('Active', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          )),
                                          // Actions
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () => context.go('/schools/${school['id']}/edit'),
                                                tooltip: 'Modifier',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isVerified ? Icons.verified : Icons.verified_outlined,
                                                  size: 18,
                                                  color: isVerified ? AppColors.success : AppColors.textMuted,
                                                ),
                                                onPressed: () => _toggleVerify(school['id']),
                                                tooltip: isVerified ? 'Retirer la verification' : 'Verifier',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isActive ? Icons.visibility : Icons.visibility_off,
                                                  size: 18,
                                                  color: isActive ? AppColors.primary : AppColors.error,
                                                ),
                                                onPressed: () => _toggleActive(school['id'], isActive),
                                                tooltip: isActive ? 'Desactiver' : 'Activer',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                                onPressed: () => _deleteSchool(school['id'], school['name'] ?? ''),
                                                tooltip: 'Supprimer',
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            // Pagination
                            if (totalPages > 1)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _page > 1
                                          ? () {
                                              _page--;
                                              _loadSchools();
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: _page < totalPages
                                          ? () {
                                              _page++;
                                              _loadSchools();
                                            }
                                          : null,
                                    ),
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
