import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';
import 'bloc/careers_bloc.dart';

class CareersListPage extends StatefulWidget {
  const CareersListPage({super.key});

  @override
  State<CareersListPage> createState() => _CareersListPageState();
}

class _CareersListPageState extends State<CareersListPage> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  int _currentPage = 1;
  late final CareersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<CareersBloc>()..add(const LoadCareers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadCareers({int? page}) {
    _currentPage = page ?? 1;
    _bloc.add(LoadCareers(page: _currentPage, search: _searchQuery));
  }

  Future<void> _deleteCareer(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer',
      message: 'Supprimer cette carriere ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminCareerById(id));
      if (mounted) AdminSnackbar.success(context, 'Carriere supprimee');
      _loadCareers(page: _currentPage);
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Carrieres', style: AppTypography.heading1),
                      BlocBuilder<CareersBloc, CareersState>(
                        builder: (context, state) {
                          final total = state is CareersLoaded
                              ? state.data.total
                              : 0;
                          return Text(
                            '$total carrieres',
                            style: AppTypography.subtitle,
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          _searchQuery = v.isEmpty ? null : v;
                          _loadCareers(page: 1);
                        },
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<CareersBloc, CareersState>(
                      builder: (context, state) {
                        return IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: state is CareersLoading
                              ? null
                              : () => _loadCareers(page: _currentPage),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: BlocBuilder<CareersBloc, CareersState>(
                  builder: (context, state) {
                    if (state is CareersLoading || state is CareersInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is CareersError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.message,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _loadCareers(page: _currentPage),
                              child: const Text('Reessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final data = (state as CareersLoaded).data;
                    final careers = data.items;
                    final totalPages = data.totalPages;

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppColors.surfaceVariant,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Nom')),
                                  DataColumn(label: Text('Secteur')),
                                  DataColumn(label: Text('Statut')),
                                  DataColumn(label: Text('Niveau etude')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: careers.map((career) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(career.name)),
                                      DataCell(Text(career.sector ?? '-')),
                                      DataCell(
                                        _StatusChip(isActive: career.isActive),
                                      ),
                                      DataCell(
                                        Text(career.minEducationLevel ?? '-'),
                                      ),
                                      DataCell(
                                        Text(
                                          career.description != null &&
                                                  career.description!.length >
                                                      40
                                              ? '${career.description!.substring(0, 40)}...'
                                              : career.description ?? '-',
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                              ),
                                              onPressed: () => context.go(
                                                '/careers/${career.id}/edit',
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: AppColors.error,
                                              ),
                                              onPressed: () =>
                                                  _deleteCareer(career.id),
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
                                  'Page ${data.page} / $totalPages',
                                  style: AppTypography.bodySmall,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: data.page > 1
                                      ? () => _loadCareers(page: data.page - 1)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: data.page < totalPages
                                      ? () => _loadCareers(page: data.page + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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
    final color = isActive ? AppColors.success : AppColors.error;
    final label = isActive ? 'Actif' : 'Inactif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
