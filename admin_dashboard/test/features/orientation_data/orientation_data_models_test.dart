import 'package:flutter_test/flutter_test.dart';

import 'package:admin_dashboard/features/orientation_data/data/orientation_data_models.dart';

void main() {
  group('CareerSubjects', () {
    test('parse les matieres cles', () {
      final c = CareerSubjects.fromJson({
        'id': 'c1',
        'name': 'Developpeur',
        'key_subjects': ['Mathematiques', 'Informatique'],
        'is_active': true,
      });
      expect(c.id, 'c1');
      expect(c.keySubjects, ['Mathematiques', 'Informatique']);
      expect(c.isMissing, isFalse);
    });

    test('isMissing quand aucune matiere (critere notes inactif)', () {
      final c = CareerSubjects.fromJson({'id': 'c2', 'name': 'X'});
      expect(c.keySubjects, isEmpty);
      expect(c.isMissing, isTrue);
    });

    test('copyWith remplace les matieres', () {
      const c = CareerSubjects(id: 'c1', name: 'X');
      final updated = c.copyWith(keySubjects: ['SVT']);
      expect(updated.keySubjects, ['SVT']);
      expect(updated.id, 'c1');
      expect(updated.isMissing, isFalse);
    });
  });

  group('ProgramCost', () {
    test('parse le cout et le statut public', () {
      final p = ProgramCost.fromJson({
        'id': 'p1',
        'name': 'Licence Info',
        'degree_level': 'Licence',
        'tuition_annual_fcfa': 250000,
        'is_public': true,
      });
      expect(p.tuitionAnnualFcfa, 250000);
      expect(p.isPublic, isTrue);
      expect(p.isMissing, isFalse);
    });

    test('isMissing quand cout absent (critere budget inactif)', () {
      final p = ProgramCost.fromJson({'id': 'p2', 'name': 'Master'});
      expect(p.tuitionAnnualFcfa, isNull);
      expect(p.isMissing, isTrue);
    });

    test('copyWith met a jour cout et statut', () {
      const p = ProgramCost(id: 'p1', name: 'X');
      final updated = p.copyWith(tuitionAnnualFcfa: 100000, isPublic: false);
      expect(updated.tuitionAnnualFcfa, 100000);
      expect(updated.isPublic, isFalse);
      expect(updated.isMissing, isFalse);
    });
  });
}
