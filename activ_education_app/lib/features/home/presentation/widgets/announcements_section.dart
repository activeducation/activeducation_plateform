import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';

final _getIt = getIt;

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final String? imageUrl;
  final String createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'info',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Color get typeColor {
    switch (type) {
      case 'warning':
        return AppColors.warning;
      case 'promotion':
        return AppColors.secondary;
      case 'update':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'promotion':
        return Icons.discount_rounded;
      case 'update':
        return Icons.new_releases_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }
}

class AnnouncementsSection extends StatefulWidget {
  const AnnouncementsSection({super.key});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  List<AnnouncementModel> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final dio = _getIt<Dio>(instanceName: 'apiClient');
      final response = await dio.get(
        ApiEndpoints.announcements,
        queryParameters: {'audience': 'students', 'limit': 5},
      );

      final announcements = (response.data as List)
          .map((a) => AnnouncementModel.fromJson(a))
          .toList();

      if (mounted) {
        setState(() {
          _announcements = announcements;
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

    if (_announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Annonces',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._announcements.map(
          (a) => Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.sm,
              left: AppSpacing.pagePaddingHorizontal,
              right: AppSpacing.pagePaddingHorizontal,
            ),
            child: _AnnouncementCard(announcement: a),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: announcement.typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: announcement.typeColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: announcement.typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              announcement.typeIcon,
              color: announcement.typeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
