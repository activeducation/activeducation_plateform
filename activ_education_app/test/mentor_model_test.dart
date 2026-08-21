import 'package:flutter_test/flutter_test.dart';

import 'package:activ_education_app/features/mentors/data/models/mentor_model.dart';

/// `mentors.available_slots` est un ENTIER en base (nombre de places, defaut 3),
/// alors que le modele l'expose comme une liste de creneaux. La conversion
/// directe levait un NoSuchMethodError qui faisait echouer toute la page
/// Mentors des qu'un mentor devenait visible.
void main() {
  group('MentorModel.fromJson — available_slots', () {
    Map<String, dynamic> payload(Object? slots) => {
          'id': 'abc',
          'full_name': 'Test Activ',
          'specialty': 'Ingénierie mécanique',
          'available_slots': slots,
        };

    test('un entier ne fait pas planter le parsing', () {
      final mentor = MentorModel.fromJson(payload(3));
      expect(mentor.availableSlots, isNull);
      expect(mentor.fullName, 'Test Activ');
    });

    test('une liste est conservee si le backend en fournit une', () {
      final mentor = MentorModel.fromJson(payload(['Lundi 9h', 'Mardi 14h']));
      expect(mentor.availableSlots, ['Lundi 9h', 'Mardi 14h']);
    });

    test('une valeur absente reste nulle', () {
      final mentor = MentorModel.fromJson(payload(null));
      expect(mentor.availableSlots, isNull);
    });

    test('la reponse reelle de production est parsee sans erreur', () {
      final mentor = MentorModel.fromJson({
        'id': '3389f620-cc3a-434d-938f-b642d0dd43df',
        'full_name': 'Test Activ',
        'specialty': 'Ingénierie mécanique',
        'bio': 'Je suis connu pour mes prouesses',
        'avatar_url': null,
        'years_experience': 10,
        'is_verified': true,
        'hourly_rate': null,
        'available_slots': 3,
      });

      expect(mentor.fullName, 'Test Activ');
      expect(mentor.isVerified, isTrue);
      expect(mentor.availableSlots, isNull);
    });
  });
}
