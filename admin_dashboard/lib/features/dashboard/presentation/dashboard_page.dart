import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/auth/token_storage.dart';
import '../domain/repositories/dashboard_repository.dart';

part 'dashboard_page.widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = getIt<DashboardRepository>();
      final stats = await repository.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
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
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
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
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
          else if (_error != null)
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
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
}
