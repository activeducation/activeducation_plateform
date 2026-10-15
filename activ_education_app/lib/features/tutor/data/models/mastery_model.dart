// Modèles de la maîtrise TutorAI (miroir de /tutor/mastery et /tutor/next-step).

class MasterySkill {
  final String skillId;
  final double pMastery; // [0,1]
  final String? title;

  const MasterySkill({
    required this.skillId,
    required this.pMastery,
    this.title,
  });

  factory MasterySkill.fromJson(Map<String, dynamic> json) {
    return MasterySkill(
      skillId: json['skill_id']?.toString() ?? '',
      pMastery: (json['p_mastery'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String?,
    );
  }

  /// Pourcentage de maîtrise arrondi (0-100).
  int get percent => (pMastery.clamp(0.0, 1.0) * 100).round();
}

class Recommendation {
  final bool hasRecommendation;
  final String message;
  final List<MasterySkill> weakSkills;

  const Recommendation({
    required this.hasRecommendation,
    required this.message,
    this.weakSkills = const [],
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final raw = (json['weak_skills'] as List?) ?? const [];
    return Recommendation(
      hasRecommendation: json['has_recommendation'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      weakSkills: raw
          .whereType<Map<String, dynamic>>()
          .map(MasterySkill.fromJson)
          .toList(),
    );
  }
}
