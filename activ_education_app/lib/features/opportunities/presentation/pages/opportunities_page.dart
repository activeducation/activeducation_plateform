import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';

final _getIt = getIt;

class OpportunitiesListPage extends StatefulWidget {
  const OpportunitiesListPage({super.key});

  @override
  State<OpportunitiesListPage> createState() => _OpportunitiesListPageState();
}

class _OpportunitiesListPageState extends State<OpportunitiesListPage> {
  List<Map<String, dynamic>> _opportunities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final dio = _getIt<Dio>(instanceName: 'apiClient');
      final response = await dio.get(ApiEndpoints.opportunities);
      if (mounted) {
        setState(() {
          _opportunities = (response.data as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'internship': return 'Stage';
      case 'job': return 'Emploi';
      case 'volunteer': return 'Bénévole';
      case 'scholarship': return 'Bourse';
      default: return type;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'internship': return AppColors.primary;
      case 'job': return AppColors.success;
      case 'volunteer': return AppColors.gold;
      case 'scholarship': return AppColors.secondary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Toutes les opportunités',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAll, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_opportunities.isEmpty) {
      return const Center(child: Text('Aucune opportunité disponible'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _opportunities.length,
      itemBuilder: (context, index) {
        final o = _opportunities[index];
        final type = o['opportunity_type'] as String? ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _typeLabel(type),
                    style: TextStyle(color: _typeColor(type), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  o['title'] as String? ?? '',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  o['organization_name'] as String? ?? '',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                if (o['location'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(o['location'] as String, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
