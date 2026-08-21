import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

/// Page admin : candidatures mentor (list + approuver/rejeter).
class MentorApplicationsPage extends StatefulWidget {
  const MentorApplicationsPage({super.key});

  @override
  State<MentorApplicationsPage> createState() => _MentorApplicationsPageState();
}

class _MentorApplicationsPageState extends State<MentorApplicationsPage> {
  List<dynamic> _apps = [];
  bool _loading = true;
  String? _error;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = getIt<ApiClient>();
      final res = await api.get(
        ApiEndpoints.adminMentorApplications,
        queryParameters: {'status': _status, 'per_page': 100},
      );
      setState(() {
        _apps = (res.data['items'] ?? []) as List;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Impossible de charger les candidatures.'; });
    }
  }

  Future<void> _decide(String id, bool approve) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(
        approve
            ? ApiEndpoints.adminMentorAppApprove(id)
            : ApiEndpoints.adminMentorAppReject(id),
      );
      if (mounted) {
        AdminSnackbar.success(
          context,
          approve ? 'Candidature approuvée — mentor créé' : 'Candidature rejetée',
        );
      }
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, _errorMessage(e));
    }
  }

  /// Remonte la raison renvoyee par l'API plutot qu'un message generique.
  ///
  /// Un simple "Action impossible" masquait la cause reelle : il a fallu lire
  /// le code du backend pour decouvrir que l'insertion echouait sur des
  /// colonnes absentes. Afficher le message du serveur rend le probleme
  /// diagnosticable depuis le back-office.
  String _errorMessage(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Serveur injoignable. Vérifiez votre connexion.';
      }
      final data = error.response?.data;
      if (data is Map) {
        final reason = data['message'] ?? data['detail'] ?? data['error'];
        if (reason is String && reason.trim().isNotEmpty) {
          return reason;
        }
      }
      final code = error.response?.statusCode;
      if (code != null) return 'Action impossible (erreur $code).';
    }
    return 'Action impossible.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidatures mentor', style: AppTypography.heading1),
            const SizedBox(height: 4),
            Text('Examinez les candidatures envoyées depuis l\'app',
                style: AppTypography.subtitle),
            const SizedBox(height: 16),
            // Filtres de statut
            Row(
              children: [
                _statusChip('pending', 'En attente'),
                const SizedBox(width: 8),
                _statusChip('approved', 'Approuvées'),
                const SizedBox(width: 8),
                _statusChip('rejected', 'Rejetées'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) { setState(() => _status = value); _load(); },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: AppTypography.label.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTypography.body),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_apps.isEmpty) {
      return Center(
        child: Text('Aucune candidature ($_status)',
            style: AppTypography.subtitle),
      );
    }
    return ListView.separated(
      itemCount: _apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AppCard(
        app: _apps[i] as Map<String, dynamic>,
        onApprove: () => _decide(_apps[i]['id'].toString(), true),
        onReject: () => _decide(_apps[i]['id'].toString(), false),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AppCard({required this.app, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final status = app['status'] as String? ?? 'pending';
    final pending = status == 'pending';
    final areas = (app['expertise_areas'] as List?)?.join(', ') ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  (app['full_name'] as String? ?? '?').characters.first.toUpperCase(),
                  style: AppTypography.body.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['full_name'] ?? '—',
                        style: AppTypography.heading3),
                    Text(app['specialty'] ?? '—',
                        style: AppTypography.subtitle),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.email_outlined, app['email']),
          if ((app['phone'] ?? '').toString().isNotEmpty)
            _row(Icons.phone_outlined, app['phone']),
          if (app['years_experience'] != null)
            _row(Icons.work_outline, '${app['years_experience']} ans d\'expérience'),
          if (areas.isNotEmpty) _row(Icons.category_outlined, areas),
          if ((app['linkedin_url'] ?? '').toString().isNotEmpty)
            _row(Icons.link, app['linkedin_url']),
          if ((app['bio'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(app['bio'], style: AppTypography.body),
          ],
          if ((app['motivation'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('« ${app['motivation']} »',
                style: AppTypography.subtitle.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeter'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: onReject,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onApprove,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$value',
                style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'approved' => (AppColors.success, 'Approuvée'),
      'rejected' => (AppColors.error, 'Rejetée'),
      _ => (AppColors.warning, 'En attente'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTypography.label.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
