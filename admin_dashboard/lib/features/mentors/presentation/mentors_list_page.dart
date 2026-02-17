import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class MentorsListPage extends StatefulWidget {
  const MentorsListPage({super.key});

  @override
  State<MentorsListPage> createState() => _MentorsListPageState();
}

class _MentorsListPageState extends State<MentorsListPage> {
  List<dynamic> _mentors = [];
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
      final response = await api.get(ApiEndpoints.adminMentors, queryParameters: {'page': _page, 'per_page': 20});
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _mentors = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVerify(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorVerify(id));
      if (mounted) AdminSnackbar.success(context, 'Statut mis a jour');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  Future<void> _toggleActive(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorToggleActive(id));
      if (mounted) AdminSnackbar.success(context, 'Statut mis a jour');
      _load();
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
          Text('Mentors', style: AppTypography.heading1),
          Text('$_total mentors', style: AppTypography.subtitle),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _isLoading ? const Center(child: CircularProgressIndicator())
                  : Column(children: [
                      Expanded(child: SingleChildScrollView(child: SizedBox(width: double.infinity, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                        columns: const [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Profession')),
                          DataColumn(label: Text('Entreprise')),
                          DataColumn(label: Text('Experience')),
                          DataColumn(label: Text('Mentees')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Verifie')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _mentors.map((m) {
                          final mentor = m as Map<String, dynamic>;
                          final userInfo = mentor['user_profiles'] as Map<String, dynamic>? ?? {};
                          final name = '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'.trim();
                          return DataRow(cells: [
                            DataCell(Text(name.isEmpty ? userInfo['email'] ?? '-' : name)),
                            DataCell(Text(mentor['profession'] ?? '')),
                            DataCell(Text(mentor['company'] ?? '-')),
                            DataCell(Text('${mentor['years_experience'] ?? '-'} ans')),
                            DataCell(Text('${mentor['current_mentees'] ?? 0}/${mentor['max_mentees'] ?? 5}')),
                            DataCell(Text('${mentor['rating_avg'] ?? '-'}')),
                            DataCell(Icon(
                              mentor['is_verified'] == true ? Icons.verified : Icons.cancel_outlined,
                              color: mentor['is_verified'] == true ? AppColors.success : AppColors.textMuted,
                              size: 20,
                            )),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: Icon(mentor['is_verified'] == true ? Icons.verified : Icons.verified_outlined,
                                    size: 18, color: AppColors.primary),
                                onPressed: () => _toggleVerify(mentor['id']),
                                tooltip: 'Verifier',
                              ),
                              IconButton(
                                icon: Icon(mentor['is_active'] == true ? Icons.block : Icons.check_circle,
                                    size: 18, color: mentor['is_active'] == true ? AppColors.error : AppColors.success),
                                onPressed: () => _toggleActive(mentor['id']),
                                tooltip: mentor['is_active'] == true ? 'Desactiver' : 'Activer',
                              ),
                            ])),
                          ]);
                        }).toList(),
                      )))),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('Page $_page / $totalPages', style: AppTypography.bodySmall),
                            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
                            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < totalPages ? () { _page++; _load(); } : null),
                          ]),
                        ),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}
