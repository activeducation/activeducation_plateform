import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';

final _getIt = getIt;
const int _pageSize = 20;

class OpportunitiesListPage extends StatefulWidget {
  const OpportunitiesListPage({super.key});

  @override
  State<OpportunitiesListPage> createState() => _OpportunitiesListPageState();
}

class _OpportunitiesListPageState extends State<OpportunitiesListPage> {
  List<Map<String, dynamic>> _opportunities = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) {
      setState(() { _loading = true; _error = null; });
    } else {
      setState(() { _loadingMore = true; });
    }

    try {
      final dio = _getIt<Dio>(instanceName: 'apiClient');
      final response = await dio.get(
        ApiEndpoints.opportunities,
        queryParameters: {'limit': _pageSize, 'offset': (page - 1) * _pageSize},
      );

      final data = response.data;
      List<Map<String, dynamic>> items;

      if (data is List) {
        items = data.cast<Map<String, dynamic>>();
        _hasMore = items.length >= _pageSize;
      } else if (data is Map) {
        items = (data['data'] as List?)?.cast<Map<String, dynamic>>() ??
                (data['items'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
        final total = data['total'] as int?;
        if (total != null) {
          _hasMore = _opportunities.length + items.length < total;
        } else {
          _hasMore = items.length >= _pageSize;
        }
      } else {
        items = [];
        _hasMore = false;
      }

      if (mounted) {
        setState(() {
          if (page == 1) {
            _opportunities = items;
          } else {
            _opportunities.addAll(items);
          }
          _page = page;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _loadNextPage() {
    if (!_loadingMore && _hasMore) {
      _loadPage(_page + 1);
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
            ElevatedButton(onPressed: () => _loadPage(1), child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_opportunities.isEmpty) {
      return const Center(child: Text('Aucune opportunité disponible'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _opportunities.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _opportunities.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _loadNextPage,
                      child: const Text('Charger plus'),
                    ),
            ),
          );
        }

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
