import '../../domain/entities/achievement.dart';

class AchievementModel extends Achievement {
  const AchievementModel({
    required super.id,
    required super.name,
    super.description,
    super.iconUrl,
    required super.points,
    required super.category,
    required super.isActive,
    required super.createdAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      points: json['points'] as int? ?? 0,
      category: json['category'] as String? ?? 'general',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AdminChallengeModel extends AdminChallenge {
  const AdminChallengeModel({
    required super.id,
    required super.title,
    super.description,
    required super.targetValue,
    required super.rewardPoints,
    required super.isActive,
    super.startDate,
    super.endDate,
  });

  factory AdminChallengeModel.fromJson(Map<String, dynamic> json) {
    return AdminChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetValue: json['target_value'] as int? ?? 1,
      rewardPoints: json['reward_points'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
    );
  }
}
