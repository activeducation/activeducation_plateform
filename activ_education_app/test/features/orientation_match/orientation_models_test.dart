import 'package:flutter_test/flutter_test.dart';

import 'package:activ_education_app/features/orientation_match/data/models/orientation_profile_model.dart';
import 'package:activ_education_app/features/orientation_match/data/models/recommendation_model.dart';

void main() {
  group('OrientationProfileModel', () {
    test('fromJson / toJson round-trip', () {
      final p = OrientationProfileModel.fromJson({
        'grades': {'Mathématiques': 14.5, 'Physique': 12},
        'favorite_subjects': ['Mathématiques'],
        'interests': ['sport'],
        'budget_annual_fcfa': 300000,
        'career_project': 'devenir ingénieur',
      });

      expect(p.grades['Mathématiques'], 14.5);
      expect(p.grades['Physique'], 12.0);
      expect(p.budgetAnnualFcfa, 300000);
      expect(p.careerProject, 'devenir ingénieur');

      final json = p.toJson();
      expect(json['grades'], {'Mathématiques': 14.5, 'Physique': 12.0});
      expect(json['budget_annual_fcfa'], 300000);
    });

    test('empty profile has no data', () {
      final p = OrientationProfileModel.empty();
      expect(p.grades, isEmpty);
      expect(p.budgetAnnualFcfa, isNull);
    });
  });

  group('RecommendationsResult', () {
    test('parse recommandations, breakdown null et complétude', () {
      final result = RecommendationsResult.fromJson({
        'recommendations': [
          {
            'career_id': 'c1',
            'career_name': 'Développeur',
            'score': 82.0,
            'breakdown': {
              'riasec': 70.0,
              'academic': null,
              'interests': 90.0,
              'project': null,
              'budget': null,
            },
            'reasons': ['Vos notes soutiennent ce choix'],
            'factors_used': 2,
          }
        ],
        'has_test_result': true,
        'profile_completeness': {'percent': 60, 'missing': ['votre budget']},
      });

      expect(result.recommendations.length, 1);
      final r = result.recommendations.first;
      expect(r.careerName, 'Développeur');
      expect(r.score, 82.0);
      // Seuls riasec + interests sont disponibles (les autres null).
      final available = r.breakdown.where((c) => c.isAvailable).toList();
      expect(available.length, 2);
      expect(r.reasons.single, contains('notes'));

      expect(result.hasTestResult, isTrue);
      expect(result.completeness.percent, 60);
      expect(result.completeness.missing, ['votre budget']);
    });

    test('valeurs par défaut sur JSON vide', () {
      final result = RecommendationsResult.fromJson(const {});
      expect(result.recommendations, isEmpty);
      expect(result.hasTestResult, isFalse);
      expect(result.completeness.percent, 0);
    });
  });
}
