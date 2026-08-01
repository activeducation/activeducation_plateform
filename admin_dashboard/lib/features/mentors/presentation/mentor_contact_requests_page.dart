import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class MentorContactRequestsPage extends StatefulWidget {
  const MentorContactRequestsPage({super.key});

  @override
  State<MentorContactRequestsPage> createState() => _MentorContactRequestsPageState();
}

class _MentorContactRequestsPageState extends State<MentorContactRequestsPage> {
  List<dynamic> _requests = [];
  int _total = 0;
  int _page = 1;
  static const int _perPage = 20;
  bool _loading = true;
  String? _error;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _totalPages => (_total / _perPage).ceil();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = getIt<ApiClient>();
      final res = await api.get(
        ApiEndpoints.adminMentorContactRequests,
        queryParameters: {
          if (_status.isNotEmpty) 'status': _status,
          'page': _page,
          'per_page': _perPage,
        },
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _requests = data['items'] as List? ?? [];
        _total = data['total'] as int? ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Impossible de charger les demandes.'; });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(ApiEndpoints.adminMentorContactRequestRead(id));
      if (mounted) AdminSnackbar.success(context, 'Demande marquée comme lue');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Action impossible');
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminMentorContactRequestById(id));
      if (mounted) AdminSnackbar.success(context, 'Demande supprimée');
      _load();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Suppression impossible');
    }
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
            Text('Demandes de contact mentor', style: AppTypography.heading1),
            const SizedBox(height: 4),
            Text('Consultez et gérez les demandes de contact des élèves',
                style: AppTypography.subtitle),
            const SizedBox(height: 16),
            Row(
              children: [
                _statusChip('pending', 'En attente'),
                const SizedBox(width: 8),
                _statusChip('read', 'Lues'),
                const SizedBox(width: 8),
                _statusChip('archived', 'Archivées'),
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
      onSelected: (_) {
        setState(() { _status = value; _page = 1; });
        _load();
      },
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
    if (_requests.isEmpty) {
      return Center(
        child: Text('Aucune demande', style: AppTypography.subtitle),
      );
    }
    return ListView.separated(
      itemCount: _requests.length + (_totalPages > 1 ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= _requests.length) return _buildPagination();
        return _RequestCard(
          request: _requests[i] as Map<String, dynamic>,
          onMarkRead: () => _markAsRead(_requests[i]['id'].toString()),
          onDelete: () => _delete(_requests[i]['id'].toString()),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () { setState(() => _page--); _load(); }
                : null,
          ),
          Text('Page $_page / $_totalPages', style: AppTypography.bodySmall),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages
                ? () { setState(() => _page++); _load(); }
                : null,
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.request,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final studentName = request['student_name'] as String? ?? '—';
    final studentEmail = request['student_email'] as String? ?? '';
    final mentorName = request['mentor_name'] as String? ?? '—';
    final mentorSpecialty = request['mentor_specialty'] as String? ?? '';
    final message = request['message'] as String? ?? '';
    final createdAt = request['created_at'] as String? ?? '';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: isPending ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  studentName.characters.first.toUpperCase(),
                  style: AppTypography.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: AppTypography.heading3),
                    if (studentEmail.isNotEmpty)
                      Text(studentEmail, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(mentorName, style: AppTypography.body),
              if (mentorSpecialty.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('· $mentorSpecialty', style: AppTypography.bodySmall),
              ],
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(_formatDate(createdAt), style: AppTypography.bodySmall),
              const Spacer(),
              if (isPending)
                TextButton.icon(
                  icon: const Icon(Icons.mark_email_read, size: 16),
                  label: const Text('Marquer lue'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onMarkRead,
                ),
              if (!isPending)
                TextButton.icon(
                  icon: Icon(Icons.check_circle_outline, size: 16, color: AppColors.textMuted),
                  label: Text(status == 'read' ? 'Lue' : 'Archivée',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  onPressed: null,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'read' => (AppColors.success, 'Lue'),
      'archived' => (AppColors.textMuted, 'Archivée'),
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

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      final months = [
        '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}
