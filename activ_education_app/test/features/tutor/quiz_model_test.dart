import 'package:flutter_test/flutter_test.dart';

import 'package:activ_education_app/features/tutor/data/models/quiz_model.dart';
import 'package:activ_education_app/features/tutor/data/models/mastery_model.dart';

void main() {
  group('Quiz.fromJson', () {
    test('parse questions, options et bonne réponse', () {
      final quiz = Quiz.fromJson({
        'questions': [
          {
            'question': 'Combien font 2+2 ?',
            'options': [
              {'text': '4', 'is_correct': true},
              {'text': '3', 'is_correct': false},
            ],
            'explanation': '2+2=4',
          }
        ],
      });

      expect(quiz.length, 1);
      final q = quiz.questions.first;
      expect(q.question, 'Combien font 2+2 ?');
      expect(q.options.length, 2);
      expect(q.correctIndex, 0);
      expect(q.explanation, '2+2=4');
    });

    test('quiz vide quand aucune question', () {
      expect(Quiz.fromJson({}).isEmpty, isTrue);
      expect(Quiz.fromJson({'questions': []}).isEmpty, isTrue);
    });
  });

  group('MasterySkill / Recommendation', () {
    test('MasterySkill parse et calcule le pourcentage', () {
      final m = MasterySkill.fromJson({
        'skill_id': 's1',
        'p_mastery': 0.42,
        'title': 'Fractions',
      });
      expect(m.skillId, 's1');
      expect(m.title, 'Fractions');
      expect(m.percent, 42);
    });

    test('Recommendation parse le message et les compétences faibles', () {
      final r = Recommendation.fromJson({
        'has_recommendation': true,
        'message': 'Renforce les fractions',
        'weak_skills': [
          {'skill_id': 's1', 'p_mastery': 0.2, 'title': 'Fractions'},
        ],
      });
      expect(r.hasRecommendation, isTrue);
      expect(r.message, 'Renforce les fractions');
      expect(r.weakSkills.single.title, 'Fractions');
    });
  });
}
