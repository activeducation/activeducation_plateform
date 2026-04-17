import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';
import 'bloc/users_bloc.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  String? _searchQuery;
  String? _roleFilter;
  final _searchController = TextEditingController();
  late final UsersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<UsersBloc>()..add(const LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadUsers({int page = 1}) {
    _bloc.add(LoadUsers(page: page, search: _searchQuery, role: _roleFilter));
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

    _bloc.add(DeactivateUser(userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsersBloc>(
      create: (_) => _bloc,
      child: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            AdminSnackbar.success(context, state.message);
          } else if (state is UsersError) {
            AdminSnackbar.error(context, state.message);
          }
        },
        child: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            final users = state is UsersLoaded ? state.data.items : <dynamic>[];
            final total = state is UsersLoaded ? state.data.total : 0;
            final currentPage = state is UsersLoaded ? state.data.page : 1;
            final totalPages = state is UsersLoaded ? state.data.totalPages : 1;
            final isLoading = state is UsersLoading || state is UsersInitial;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Utilisateurs', style: AppTypography.heading1),
                  const SizedBox(height: 4),
                  Text(
                    '$total utilisateurs au total',
                    style: AppTypography.subtitle,
                  ),
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
                                _loadUsers();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String?>(
                            value: _roleFilter,
                            hint: const Text('Tous les roles'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Tous les roles'),
                              ),
                              ...AdminConstants.userRoles.map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    AdminConstants.roleLabels[r] ?? r,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              _roleFilter = v;
                              _loadUsers();
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => _loadUsers(page: currentPage),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table
                  Expanded(
                    child: Card(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : state is UsersError
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: AppTypography.body,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _loadUsers(page: currentPage),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reessayer'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              AppColors.surfaceVariant,
                                            ),
                                        columns: const [
                                          DataColumn(label: Text('Nom')),
                                          DataColumn(label: Text('Email')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Statut')),
                                          DataColumn(
                                            label: Text('Inscription'),
                                          ),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: users.map((u) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(u.fullName)),
                                              DataCell(Text(u.email)),
                                              DataCell(_RoleChip(role: u.role)),
                                              DataCell(
                                                _StatusChip(
                                                  isActive: u.isActive,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  u.createdAt
                                                      .toIso8601String()
                                                      .split('T')
                                                      .first,
                                                  style:
                                                      AppTypography.bodySmall,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.visibility,
                                                        size: 18,
                                                      ),
                                                      onPressed: () => context
                                                          .go('/users/${u.id}'),
                                                      tooltip: 'Voir',
                                                    ),
                                                    if (u.isActive)
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.block,
                                                          size: 18,
                                                          color:
                                                              AppColors.error,
                                                        ),
                                                        onPressed: () =>
                                                            _deactivateUser(
                                                              u.id,
                                                            ),
                                                        tooltip: 'Desactiver',
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
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
                                        Text(
                                          'Page $currentPage / $totalPages',
                                          style: AppTypography.bodySmall,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: currentPage > 1
                                              ? () => _loadUsers(
                                                  page: currentPage - 1,
                                                )
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: currentPage < totalPages
                                              ? () => _loadUsers(
                                                  page: currentPage + 1,
                                                )
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
          },
        ),
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
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
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
        color: (isActive ? AppColors.success : AppColors.error).withValues(
          alpha: 0.1,
        ),
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
