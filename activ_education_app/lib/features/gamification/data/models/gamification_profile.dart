import 'package:flutter/material.dart';

class GamificationStats {
  final int totalXp;
  final int currentLevel;
  final int currentStreak;
  final int longestStreak;
  final int totalAchievements;
  final int completedChallenges;
  final int? leaderboardRank;

  GamificationStats({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalAchievements = 0,
    this.completedChallenges = 0,
    this.leaderboardRank,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      totalXp: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalAchievements: json['total_achievements'] ?? 0,
      completedChallenges: json['completed_challenges'] ?? 0,
      leaderboardRank: json['leaderboard_rank'],
    );
  }

  Map<String, dynamic> toJson() => {
    'total_xp': totalXp,
    'current_level': currentLevel,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'total_achievements': totalAchievements,
    'completed_challenges': completedChallenges,
    'leaderboard_rank': leaderboardRank,
  };
}

class AchievementModel {
  final String id;
  final String achievementType;
  final Map<String, dynamic> achievementData;
  final DateTime earnedAt;

  AchievementModel({
    required this.id,
    required this.achievementType,
    this.achievementData = const {},
    required this.earnedAt,
  });

  String get displayName {
    switch (achievementType) {
      case 'first_test':
        return 'Premier Test';
      case 'first_course':
        return 'Premier Cours';
      case 'streak_7':
        return 'Semaine Streak';
      case 'streak_30':
        return 'Mois Streak';
      case 'first_mentor':
        return 'Premier Mentor';
      case 'career_explorer':
        return 'Explorateur de Carrières';
      case 'school_finder':
        return 'Trouveur d\'École';
      default:
        return achievementType;
    }
  }

  IconData get icon {
    if (achievementType.contains('streak')) return Icons.local_fire_department_rounded;
    if (achievementType.contains('test')) return Icons.assignment_rounded;
    if (achievementType.contains('course')) return Icons.menu_book_rounded;
    if (achievementType.contains('mentor')) return Icons.school_rounded;
    if (achievementType.contains('career')) return Icons.work_history_rounded;
    if (achievementType.contains('school')) return Icons.business_rounded;
    return Icons.emoji_events_rounded;
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      achievementType: json['achievement_type'] ?? 'unknown',
      achievementData: json['achievement_data'] ?? {},
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'achievement_type': achievementType,
    'achievement_data': achievementData,
    'earned_at': earnedAt.toIso8601String(),
  };
}

class ActiveChallenge {
  final String id;
  final String challengeId;
  final String title;
  final String? description;
  final int points;
  final String status;
  final int? score;
  final DateTime? completedAt;

  ActiveChallenge({
    required this.id,
    required this.challengeId,
    required this.title,
    this.description,
    this.points = 0,
    this.status = 'not_started',
    this.score,
    this.completedAt,
  });

  factory ActiveChallenge.fromJson(Map<String, dynamic> json) {
    return ActiveChallenge(
      id: json['id'] ?? '',
      challengeId: json['challenge_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      points: json['points'] ?? 0,
      status: json['status'] ?? 'not_started',
      score: json['score'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'challenge_id': challengeId,
    'title': title,
    'description': description,
    'points': points,
    'status': status,
    'score': score,
    'completed_at': completedAt?.toIso8601String(),
  };
}

class GamificationProfile {
  final GamificationStats stats;
  final List<AchievementModel> achievements;
  final List<ActiveChallenge> activeChallenges;
  final int nextLevelXp;
  final int xpToNextLevel;

  GamificationProfile({
    required this.stats,
    this.achievements = const [],
    this.activeChallenges = const [],
    this.nextLevelXp = 1000,
    this.xpToNextLevel = 1000,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      stats: json['stats'] != null
          ? GamificationStats.fromJson(json['stats'])
          : GamificationStats(),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => AchievementModel.fromJson(e))
              .toList() ??
          [],
      activeChallenges: (json['active_challenges'] as List<dynamic>?)
              ?.map((e) => ActiveChallenge.fromJson(e))
              .toList() ??
          [],
      nextLevelXp: json['next_level_xp'] ?? 1000,
      xpToNextLevel: json['xp_to_next_level'] ?? 1000,
    );
  }

  double get levelProgress {
    if (nextLevelXp <= 0) return 0;
    final startOfLevel = (stats.currentLevel - 1) * stats.currentLevel ~/ 2 * 100;
    final range = nextLevelXp - startOfLevel;
    if (range <= 0) return 0;
    return ((stats.totalXp - startOfLevel) / range).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'stats': stats.toJson(),
    'achievements': achievements.map((e) => e.toJson()).toList(),
    'active_challenges': activeChallenges.map((e) => e.toJson()).toList(),
    'next_level_xp': nextLevelXp,
    'xp_to_next_level': xpToNextLevel,
  };
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int currentLevel;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.totalXp = 0,
    this.currentLevel = 1,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
      totalXp: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'total_xp': totalXp,
    'current_level': currentLevel,
  };
}