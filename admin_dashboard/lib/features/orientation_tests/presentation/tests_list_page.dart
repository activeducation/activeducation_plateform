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
import 'bloc/tests_bloc.dart';

class TestsListPage extends StatefulWidget {
  const TestsListPage({super.key});

  @override
  State<TestsListPage> createState() => _TestsListPageState();
}

class _TestsListPageState extends State<TestsListPage> {
  late final TestsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TestsBloc>();
    _bloc.add(const LoadTests());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _duplicateTest(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminTestDuplicate(id));
      if (mounted) AdminSnackbar.success(context, 'Test duplique');
      _bloc.add(const LoadTests());
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _deleteTest(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer',
      message: 'Supprimer ce test et toutes ses questions ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminTestById(id));
      if (mounted) AdminSnackbar.success(context, 'Test supprime');
      _bloc.add(const LoadTests());
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
            BlocBuilder<TestsBloc, TestsState>(
              builder: (context, state) {
                final total = state is TestsLoaded ? state.data.total : 0;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tests d\'orientation',
                            style: AppTypography.heading1,
                          ),
                          Text('$total tests', style: AppTypography.subtitle),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/tests/new'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nouveau test'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: BlocBuilder<TestsBloc, TestsState>(
                  builder: (context, state) {
                    if (state is TestsLoading || state is TestsInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is TestsError) {
                      return Center(
                        child: Text(state.message, style: AppTypography.body),
                      );
                    }

                    final data = (state as TestsLoaded).data;
                    final tests = data.items;
                    final page = data.page;
                    final totalPages = (data.total / data.perPage).ceil();

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
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Duree')),
                                  DataColumn(label: Text('Questions')),
                                  DataColumn(label: Text('Sessions')),
                                  DataColumn(label: Text('Actif')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: tests.map((test) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(test.name)),
                                      DataCell(Text(test.type)),
                                      DataCell(
                                        Text('${test.durationMinutes} min'),
                                      ),
                                      DataCell(Text('${test.questionCount}')),
                                      DataCell(const Text('-')),
                                      DataCell(
                                        Icon(
                                          test.isActive == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: test.isActive == true
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                          size: 20,
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
                                                '/tests/${test.id}/edit',
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _duplicateTest(test.id),
                                              tooltip: 'Dupliquer',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: AppColors.error,
                                              ),
                                              onPressed: () =>
                                                  _deleteTest(test.id),
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
                                  'Page $page / $totalPages',
                                  style: AppTypography.bodySmall,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: page > 1
                                      ? () =>
                                            _bloc.add(LoadTests(page: page - 1))
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: page < totalPages
                                      ? () =>
                                            _bloc.add(LoadTests(page: page + 1))
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
