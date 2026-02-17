import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.dashboardStats);
      setState(() {
        _stats = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenStorage = getIt<TokenStorage>();
    final greeting = _getGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, ${tokenStorage.userName ?? 'Admin'} !',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Voici un apercu de votre plateforme ActivEducation aujourd\'hui.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Stat cards
            Row(
              children: [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Utilisateurs',
                  value: '${_stats?['total_users'] ?? 0}',
                  color: AppColors.primary,
                  bgColor: AppColors.primarySurface,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.quiz_rounded,
                  label: 'Tests completes',
                  value: '${_stats?['total_tests_completed'] ?? 0}',
                  color: AppColors.success,
                  bgColor: AppColors.successSurface,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.school_rounded,
                  label: 'Ecoles',
                  value: '${_stats?['total_schools'] ?? 0}',
                  color: AppColors.secondary,
                  bgColor: AppColors.secondarySurface,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.person_search_rounded,
                  label: 'Mentors',
                  value: '${_stats?['total_mentors'] ?? 0}',
                  color: AppColors.info,
                  bgColor: AppColors.infoSurface,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donut chart
                Expanded(
                  flex: 5,
                  child: _DashboardCard(
                    title: 'Tests par type',
                    subtitle: 'Repartition des tests sur la plateforme',
                    child: SizedBox(height: 260, child: _buildDonutChart()),
                  ),
                ),
                const SizedBox(width: 16),
                // Recent activity
                Expanded(
                  flex: 5,
                  child: _DashboardCard(
                    title: 'Activite recente',
                    subtitle: 'Dernieres actions sur la plateforme',
                    child: _buildRecentActivity(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick stats row
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.work_rounded,
                    label: 'Carrieres',
                    value: '${_stats?['total_careers'] ?? 0}',
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.emoji_events_rounded,
                    label: 'Achievements',
                    value: '${_stats?['total_achievements'] ?? 0}',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.flag_rounded,
                    label: 'Challenges',
                    value: '${_stats?['total_challenges'] ?? 0}',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.campaign_rounded,
                    label: 'Annonces actives',
                    value: '${_stats?['total_announcements'] ?? 0}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon apres-midi';
    return 'Bonsoir';
  }

  Widget _buildDonutChart() {
    final testsByType = (_stats?['tests_by_type'] as List?) ?? [];
    if (testsByType.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Aucune donnee disponible', style: AppTypography.bodySmall),
          ],
        ),
      );
    }

    final colors = [
      AppColors.primary, AppColors.secondary, AppColors.success,
      AppColors.info, AppColors.error, AppColors.warning,
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: testsByType.asMap().entries.map((entry) {
                final item = entry.value as Map<String, dynamic>;
                return PieChartSectionData(
                  value: (item['count'] as num).toDouble(),
                  title: '${item['count']}',
                  color: colors[entry.key % colors.length],
                  radius: 50,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 45,
              sectionsSpace: 3,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Legend
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: testsByType.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[entry.key % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item['type'] ?? 'Inconnu'}',
                    style: AppTypography.bodySmall.copyWith(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activity = (_stats?['recent_activity'] as List?) ?? [];
    if (activity.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Aucune activite recente', style: AppTypography.bodySmall),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activity.take(6).map((item) {
        final entry = item as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['user_name'] ?? 'Utilisateur',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      '${entry['action'] ?? ''} ${entry['entity'] ?? ''}',
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                entry['time'] ?? '',
                style: AppTypography.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// Widgets
// ============================================================================

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _DashboardCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.heading3),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: AppTypography.bodySmall),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _hovering
              ? (Matrix4.identity()..storage[13] = -2.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering ? widget.color.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering ? widget.color.withValues(alpha: 0.08) : AppColors.cardShadow,
                blurRadius: _hovering ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.value, style: AppTypography.statValue),
                      const SizedBox(height: 2),
                      Text(widget.label, style: AppTypography.statLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTypography.body.copyWith(fontSize: 13)),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
