import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

class AdminDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int totalItems;
  final int currentPage;
  final int itemsPerPage;
  final ValueChanged<int>? onPageChanged;
  final Widget? searchWidget;
  final List<Widget>? filterWidgets;
  final List<Widget>? actions;
  final bool isLoading;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.totalItems = 0,
    this.currentPage = 1,
    this.itemsPerPage = 20,
    this.onPageChanged,
    this.searchWidget,
    this.filterWidgets,
    this.actions,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar
            if (searchWidget != null || filterWidgets != null || actions != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    if (searchWidget != null)
                      SizedBox(width: 300, child: searchWidget!),
                    if (filterWidgets != null) ...[
                      const SizedBox(width: 12),
                      ...filterWidgets!.map((w) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: w,
                          )),
                    ],
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),

            // Table
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: columns,
                      rows: rows,
                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 64,
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      showCheckboxColumn: false,
                    ),
                  ),
                ),
              ),

            // Pagination
            if (totalPages > 1) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Affichage ${((currentPage - 1) * itemsPerPage) + 1} - '
                      '${(currentPage * itemsPerPage).clamp(0, totalItems)} '
                      'sur $totalItems',
                      style: AppTypography.bodySmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 1
                              ? () => onPageChanged?.call(currentPage - 1)
                              : null,
                        ),
                        Text('$currentPage / $totalPages', style: AppTypography.body),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < totalPages
                              ? () => onPageChanged?.call(currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
