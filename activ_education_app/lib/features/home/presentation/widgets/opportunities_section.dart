import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';

final _getIt = getIt;

class OpportunityModel {
  final String id;
  final String title;
  final String opportunityType;
  final String organizationName;
  final String? organizationLogo;
  final String? location;
  final String? remoteType;
  final DateTime? applicationDeadline;
  final bool isFeatured;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.opportunityType,
    required this.organizationName,
    this.organizationLogo,
    this.location,
    this.remoteType,
    this.applicationDeadline,
    this.isFeatured = false,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      opportunityType: json['opportunity_type'] ?? '',
      organizationName: json['organization_name'] ?? '',
      organizationLogo: json['organization_logo'],
      location: json['location'],
      remoteType: json['remote_type'],
      applicationDeadline: json['application_deadline'] != null
          ? DateTime.parse(json['application_deadline'])
          : null,
      isFeatured: json['is_featured'] ?? false,
    );
  }

  String get typeLabel {
    switch (opportunityType) {
      case 'internship':
        return 'Stage';
      case 'job':
        return 'Emploi';
      case 'volunteer':
        return 'Bénévole';
      case 'scholarship':
        return 'Bourse';
      default:
        return opportunityType;
    }
  }

  Color get typeColor {
    switch (opportunityType) {
      case 'internship':
        return AppColors.primary;
      case 'job':
        return AppColors.success;
      case 'volunteer':
        return AppColors.gold;
      case 'scholarship':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class OpportunitiesSection extends StatefulWidget {
  const OpportunitiesSection({super.key});

  @override
  State<OpportunitiesSection> createState() => _OpportunitiesSectionState();
}

class _OpportunitiesSectionState extends State<OpportunitiesSection> {
  List<OpportunityModel> _opportunities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  Future<void> _loadOpportunities() async {
    try {
      final dio = _getIt<Dio>(instanceName: 'apiClient');
      final response = await dio.get(
        ApiEndpoints.opportunities,
        queryParameters: {'limit': 5},
      );

      final opportunities = (response.data as List)
          .map((o) => OpportunityModel.fromJson(o))
          .toList();

      if (mounted) {
        setState(() {
          _opportunities = opportunities;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_opportunities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePaddingHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Opportunités',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/opportunities'),
                child: Text(
                  'Voir tout',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePaddingHorizontal),
            itemCount: _opportunities.length,
            itemBuilder: (context, index) {
              return _OpportunityCard(opportunity: _opportunities[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;

  const _OpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: opportunity.typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              opportunity.typeLabel,
              style: AppTypography.labelSmall.copyWith(
                color: opportunity.typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            opportunity.title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            opportunity.organizationName,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (opportunity.location != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    opportunity.location!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}