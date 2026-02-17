import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
class UserDetailPage extends StatefulWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminUserById(widget.userId));
      setState(() {
        _user = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(String newRole) async {
    try {
      final api = getIt<ApiClient>();
      await api.patch(
        ApiEndpoints.adminUserRole(widget.userId),
        data: {'role': newRole},
      );
      if (mounted) AdminSnackbar.success(context, 'Role mis a jour');
      _loadUser();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur lors du changement de role');
    }
  }

  Future<void> _toggleActive() async {
    final isActive = _user?['is_active'] ?? true;
    final endpoint = isActive
        ? ApiEndpoints.adminUserDeactivate(widget.userId)
        : ApiEndpoints.adminUserActivate(widget.userId);

    try {
      final api = getIt<ApiClient>();
      await api.patch(endpoint);
      if (mounted) AdminSnackbar.success(context, isActive ? 'Desactive' : 'Active');
      _loadUser();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_user == null) {
      return const Center(child: Text('Utilisateur non trouve'));
    }

    final activity = _user!['activity'] as Map<String, dynamic>? ?? {};
    final tokenStorage = getIt<TokenStorage>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/users'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}'.trim().isEmpty
                      ? _user!['email'] ?? 'Utilisateur'
                      : '${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}'.trim(),
                  style: AppTypography.heading1,
                ),
              ),
              if (tokenStorage.isSuperAdmin)
                PopupMenuButton<String>(
                  onSelected: _changeRole,
                  itemBuilder: (ctx) => AdminConstants.userRoles
                      .map((r) => PopupMenuItem(
                            value: r,
                            child: Text(AdminConstants.roleLabels[r] ?? r),
                          ))
                      .toList(),
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: Text('Role: ${AdminConstants.roleLabels[_user!['role']] ?? _user!['role']}'),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _toggleActive,
                icon: Icon(
                  _user!['is_active'] == true ? Icons.block : Icons.check_circle,
                  size: 16,
                  color: _user!['is_active'] == true ? AppColors.error : AppColors.success,
                ),
                label: Text(_user!['is_active'] == true ? 'Desactiver' : 'Activer'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info + Activity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile info
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations', style: AppTypography.heading3),
                        const SizedBox(height: 16),
                        _InfoRow('Email', _user!['email'] ?? '-'),
                        _InfoRow('Telephone', _user!['phone_number'] ?? '-'),
                        _InfoRow('Ecole', _user!['school_name'] ?? '-'),
                        _InfoRow('Niveau', _user!['class_level'] ?? '-'),
                        _InfoRow('Langue', _user!['preferred_language'] ?? 'fr'),
                        _InfoRow('Inscription', (_user!['created_at'] ?? '').toString().split('T').first),
                        _InfoRow('Derniere connexion', (_user!['last_login_at'] ?? '-').toString().split('T').first),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Activity summary
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activite', style: AppTypography.heading3),
                        const SizedBox(height: 16),
                        _ActivityStat(Icons.quiz, 'Tests completes', '${activity['tests_completed'] ?? 0}'),
                        _ActivityStat(Icons.hourglass_bottom, 'Tests en cours', '${activity['tests_in_progress'] ?? 0}'),
                        _ActivityStat(Icons.favorite, 'Carrieres favorites', '${activity['favorite_careers'] ?? 0}'),
                        _ActivityStat(Icons.emoji_events, 'Achievements', '${activity['achievements_unlocked'] ?? 0}'),
                        _ActivityStat(Icons.star, 'Points', '${activity['total_points'] ?? 0}'),
                        _ActivityStat(Icons.trending_up, 'Niveau', '${activity['current_level'] ?? 1}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: AppTypography.label),
          ),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ActivityStat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
