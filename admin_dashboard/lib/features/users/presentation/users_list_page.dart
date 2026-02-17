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

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<dynamic> _users = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = true;
  String? _searchQuery;
  String? _roleFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final params = <String, dynamic>{
        'page': _page,
        'per_page': 20,
      };
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      if (_roleFilter != null) params['role'] = _roleFilter;

      final response = await api.get(ApiEndpoints.adminUsers, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _users = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
  }

  Future<void> _deactivateUser(String userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Desactiver l\'utilisateur',
      message: 'Etes-vous sur de vouloir desactiver cet utilisateur ?',
      confirmLabel: 'Desactiver',
      isDanger: true,
    );
    if (confirmed != true) return;

    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminUserDeactivate(userId));
      if (mounted) AdminSnackbar.success(context, 'Utilisateur desactive');
      _loadUsers();
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
          Text('Utilisateurs', style: AppTypography.heading1),
          const SizedBox(height: 4),
          Text('$_total utilisateurs au total', style: AppTypography.subtitle),
          const SizedBox(height: 24),

          // Toolbar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher par nom ou email...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        _searchQuery = v;
                        _page = 1;
                        _loadUsers();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: _roleFilter,
                    hint: const Text('Tous les roles'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les roles')),
                      ...AdminConstants.userRoles.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(AdminConstants.roleLabels[r] ?? r),
                          )),
                    ],
                    onChanged: (v) {
                      _roleFilter = v;
                      _page = 1;
                      _loadUsers();
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
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
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Role')),
                                  DataColumn(label: Text('Statut')),
                                  DataColumn(label: Text('Inscription')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _users.map((u) {
                                  final user = u as Map<String, dynamic>;
                                  return DataRow(cells: [
                                    DataCell(Text(
                                      '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isEmpty
                                          ? '-'
                                          : '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                                    )),
                                    DataCell(Text(user['email'] ?? '')),
                                    DataCell(_RoleChip(role: user['role'] ?? 'student')),
                                    DataCell(_StatusChip(isActive: user['is_active'] ?? true)),
                                    DataCell(Text(
                                      (user['created_at'] ?? '').toString().split('T').first,
                                      style: AppTypography.bodySmall,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 18),
                                          onPressed: () => context.go('/users/${user['id']}'),
                                          tooltip: 'Voir',
                                        ),
                                        if (user['is_active'] == true)
                                          IconButton(
                                            icon: const Icon(Icons.block, size: 18, color: AppColors.error),
                                            onPressed: () => _deactivateUser(user['id']),
                                            tooltip: 'Desactiver',
                                          ),
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
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _page > 1 ? () { _page--; _loadUsers(); } : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _page < totalPages ? () { _page++; _loadUsers(); } : null,
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

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'super_admin' => AppColors.error,
      'admin' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AdminConstants.roleLabels[role] ?? role,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Actif' : 'Inactif',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
