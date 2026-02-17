import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<dynamic> _logs = [];
  int _total = 0;
  int _page = 1;
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
      final response = await api.get(ApiEndpoints.adminAuditLog,
          queryParameters: {'page': _page, 'per_page': 50});
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _logs = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / 50).ceil();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Journal d\'audit', style: AppTypography.heading1),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
          Text('$_total entrees', style: AppTypography.subtitle),
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
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Admin')),
                                  DataColumn(label: Text('Action')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Entite')),
                                ],
                                rows: _logs.map((l) {
                                  final log = l as Map<String, dynamic>;
                                  final userInfo = log['user_profiles'] as Map<String, dynamic>? ?? {};
                                  final adminName = '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'.trim();
                                  return DataRow(cells: [
                                    DataCell(Text(
                                      (log['created_at'] ?? '').toString().replaceFirst('T', ' ').split('.').first,
                                      style: AppTypography.bodySmall,
                                    )),
                                    DataCell(Text(adminName.isEmpty ? userInfo['email'] ?? '-' : adminName)),
                                    DataCell(_ActionChip(action: log['action'] ?? '')),
                                    DataCell(Text(log['entity_type'] ?? '')),
                                    DataCell(Text(
                                      log['entity_id'] ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall,
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
                                    onPressed: _page > 1 ? () { _page--; _load(); } : null),
                                IconButton(icon: const Icon(Icons.chevron_right),
                                    onPressed: _page < totalPages ? () { _page++; _load(); } : null),
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

class _ActionChip extends StatelessWidget {
  final String action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = switch (action) {
      'create' => AppColors.success,
      'delete' => AppColors.error,
      'update' || 'update_role' => AppColors.info,
      'verify' => AppColors.primary,
      'deactivate' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(action, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
