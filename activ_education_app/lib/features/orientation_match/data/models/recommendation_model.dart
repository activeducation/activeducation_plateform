// Recommandations multi-critères (miroir de /orientation/recommendations/multi-factor).

/// Un critère du calcul, avec son libellé et son sous-score (null si absent).
class CriterionScore {
  final String key;
  final String label;
  final double? value; // 0-100 ou null si non évalué

  const CriterionScore({required this.key, required this.label, this.value});

  bool get isAvailable => value != null;
}

const _criterionLabels = {
  'riasec': 'Tests d\'orientation',
  'academic': 'Notes',
  'interests': 'Centres d\'intérêt',
  'project': 'Projet professionnel',
  'budget': 'Budget',
};

class CareerRecommendation {
  final String? careerId;
  final String careerName;
  final double score;
  final List<CriterionScore> breakdown;
  final List<String> reasons;
  final int factorsUsed;

  const CareerRecommendation({
    required this.careerName,
    required this.score,
    this.careerId,
    this.breakdown = const [],
    this.reasons = const [],
    this.factorsUsed = 0,
  });

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = (json['breakdown'] as Map?) ?? const {};
    final breakdown = _criterionLabels.entries.map((e) {
      final raw = rawBreakdown[e.key];
      return CriterionScore(
        key: e.key,
        label: e.value,
        value: (raw as num?)?.toDouble(),
      );
    }).toList();

    return CareerRecommendation(
      careerId: json['career_id']?.toString(),
      careerName: json['career_name'] as String? ?? 'Métier',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      breakdown: breakdown,
      reasons:
          (json['reasons'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      factorsUsed: (json['factors_used'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileCompleteness {
  final int percent;
  final List<String> missing;

  const ProfileCompleteness({this.percent = 0, this.missing = const []});

  factory ProfileCompleteness.fromJson(Map<String, dynamic> json) {
    return ProfileCompleteness(
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      missing:
          (json['missing'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class RecommendationsResult {
  final List<CareerRecommendation> recommendations;
  final bool hasTestResult;
  final ProfileCompleteness completeness;

  const RecommendationsResult({
    this.recommendations = const [],
    this.hasTestResult = false,
    this.completeness = const ProfileCompleteness(),
  });

  factory RecommendationsResult.fromJson(Map<String, dynamic> json) {
    return RecommendationsResult(
      recommendations: ((json['recommendations'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CareerRecommendation.fromJson)
          .toList(),
      hasTestResult: json['has_test_result'] as bool? ?? false,
      completeness: ProfileCompleteness.fromJson(
        (json['profile_completeness'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
