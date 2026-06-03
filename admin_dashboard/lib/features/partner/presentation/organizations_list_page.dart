import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String orgType;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final String? city;
  final bool isApproved;
  final bool isActive;
  final String? createdBy;
  final String createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.orgType,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.city,
    this.isApproved = false,
    this.isActive = true,
    this.createdBy,
    this.createdAt = '',
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      orgType: json['org_type'] ?? 'cdej',
      description: json['description'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      city: json['city'],
      isApproved: json['is_approved'] ?? false,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: json['created_at'] ?? '',
    );
  }

  String get typeLabel {
    switch (orgType) {
      case 'cdej':
        return 'CDEJ';
      case 'ong':
        return 'ONG';
      case 'association':
        return 'Association';
      default:
        return orgType;
    }
  }
}

class OrganizationsListPage extends StatefulWidget {
  const OrganizationsListPage({super.key});

  @override
  State<OrganizationsListPage> createState() => _OrganizationsListPageState();
}

class _OrganizationsListPageState extends State<OrganizationsListPage> {
  List<OrganizationModel> _orgs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = getIt<TokenStorage>().accessToken;
      if (token == null) { setState(() { _loading = false; _error = 'Session expirée. Veuillez vous reconnecter.'; }); return; }

      final response = await getIt<ApiClient>().dio.get(
        '${ApiEndpoints.baseUrl}/partner/organizations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {'page': 1, 'page_size': 100},
      );
      final data = response.data;
      final items = (data['items'] ?? data ?? []) as List;
      setState(() {
        _orgs = items.map((o) => OrganizationModel.fromJson(o)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Impossible de charger les organisations.'; });
    }
  }

  Future<void> _approveOrg(String orgId) async {
    try {
      final token = getIt<TokenStorage>().accessToken;
      if (token == null) return;

      await getIt<ApiClient>().dio.post(
        '${ApiEndpoints.baseUrl}/admin/partner/organizations/$orgId/approve',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _loadOrgs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organisation approuvée')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'approbation")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Organisations partenaires', style: AppTypography.heading2),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_error!, style: AppTypography.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadOrgs, child: const Text('Réessayer')),
                ],
              ),
            ))
          else
            Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_orgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Aucune organisation pour le moment', style: AppTypography.body),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Contact')),
          DataColumn(label: Text('Ville')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _orgs.map((org) => DataRow(cells: [
          DataCell(Text(org.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
          DataCell(_TypeChip(label: org.typeLabel, orgType: org.orgType)),
          DataCell(Text(org.contactEmail ?? org.contactPhone ?? '—', style: AppTypography.bodySmall)),
          DataCell(Text(org.city ?? '—', style: AppTypography.bodySmall)),
          DataCell(_StatusChip(isApproved: org.isApproved, isActive: org.isActive)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!org.isApproved)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Approuver'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  onPressed: () => _approveOrg(org.id),
                ),
              if (!org.isActive)
                Text('Inactif', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
            ],
          )),
        ])).toList(),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String orgType;
  const _TypeChip({required this.label, required this.orgType});

  Color get _color {
    switch (orgType) {
      case 'cdej': return AppColors.info;
      case 'ong': return AppColors.success;
      case 'association': return AppColors.secondary;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isApproved;
  final bool isActive;
  const _StatusChip({required this.isApproved, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return Text('Inactif', style: TextStyle(color: AppColors.error, fontSize: 12));
    if (!isApproved) return Text('En attente', style: TextStyle(color: AppColors.warning, fontSize: 12));
    return Text('Approuvé', style: TextStyle(color: AppColors.success, fontSize: 12));
  }
}
