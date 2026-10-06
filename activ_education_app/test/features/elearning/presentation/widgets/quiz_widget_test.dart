import 'package:flutter_test/flutter_test.dart';

import 'package:activ_education_app/features/elearning/presentation/widgets/quiz_widget.dart';

void main() {
  group('QuizWidget.fromContentData', () {
    test('marque la bonne option via correct_option_id (format seed / API)', () {
      final questions = QuizWidget.fromContentData({
        'questions': [
          {
            'id': 'q1',
            'text': 'Question ?',
            'options': [
              {'id': 'q1a', 'text': 'A'},
              {'id': 'q1b', 'text': 'B'},
              {'id': 'q1c', 'text': 'C'},
            ],
            'correct_option_id': 'q1c',
          },
        ],
      });

      expect(
        questions.single.options.map((o) => o.isCorrect).toList(),
        [false, false, true],
      );
    });

    test('conserve is_correct quand il est porte par les options', () {
      final questions = QuizWidget.fromContentData({
        'questions': [
          {
            'id': 'q1',
            'text': 'Question ?',
            'options': [
              {'id': 'a', 'text': 'A', 'is_correct': true},
              {'id': 'b', 'text': 'B', 'is_correct': false},
            ],
          },
        ],
      });

      expect(
        questions.single.options.map((o) => o.isCorrect).toList(),
        [true, false],
      );
    });
  });
}
