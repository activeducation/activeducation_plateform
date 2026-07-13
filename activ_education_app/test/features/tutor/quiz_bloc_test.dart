import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/tutor/data/datasources/tutor_remote_datasource.dart';
import 'package:activ_education_app/features/tutor/data/models/quiz_model.dart';
import 'package:activ_education_app/features/tutor/presentation/bloc/quiz_bloc.dart';

class MockTutorRemoteDataSource extends Mock implements TutorRemoteDataSource {}

final _quiz = Quiz(questions: [
  const QuizQuestion(
    question: 'Combien font 2+2 ?',
    options: [
      QuizOption(text: '4', isCorrect: true),
      QuizOption(text: '3', isCorrect: false),
    ],
    explanation: '2+2=4',
  ),
]);

void main() {
  late MockTutorRemoteDataSource ds;

  setUpAll(() => registerFallbackValue(<bool>[]));

  setUp(() => ds = MockTutorRemoteDataSource());

  blocTest<QuizBloc, QuizState>(
    'GenerateQuiz succès → [QuizLoading, QuizReady]',
    build: () {
      when(() => ds.generateQuiz(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
          )).thenAnswer((_) async => _quiz);
      return QuizBloc(ds);
    },
    act: (bloc) => bloc.add(const GenerateQuiz('maths')),
    expect: () => [
      isA<QuizLoading>(),
      isA<QuizReady>(),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'quiz vide → QuizFailure',
    build: () {
      when(() => ds.generateQuiz(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
          )).thenAnswer((_) async => const Quiz(questions: []));
      return QuizBloc(ds);
    },
    act: (bloc) => bloc.add(const GenerateQuiz('maths')),
    expect: () => [isA<QuizLoading>(), isA<QuizFailure>()],
  );

  blocTest<QuizBloc, QuizState>(
    '404 → QuizFailure marqué unavailable',
    build: () {
      when(() => ds.generateQuiz(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
          )).thenThrow(const TutorApiException('off', statusCode: 404));
      return QuizBloc(ds);
    },
    act: (bloc) => bloc.add(const GenerateQuiz('maths')),
    expect: () => [
      isA<QuizLoading>(),
      predicate<QuizState>((s) => s is QuizFailure && s.unavailable),
    ],
  );

  blocTest<QuizBloc, QuizState>(
    'erreur réseau → QuizFailure',
    build: () {
      when(() => ds.generateQuiz(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
          )).thenThrow(Exception('boom'));
      return QuizBloc(ds);
    },
    act: (bloc) => bloc.add(const GenerateQuiz('maths')),
    expect: () => [
      isA<QuizLoading>(),
      predicate<QuizState>((s) => s is QuizFailure && !s.unavailable),
    ],
  );

  test('SubmitQuizResults transmet skill_id et réponses au datasource', () async {
    when(() => ds.submitQuiz(
          skillId: any(named: 'skillId'),
          answers: any(named: 'answers'),
        )).thenAnswer((_) async => <String, dynamic>{});

    final bloc = QuizBloc(ds);
    bloc.add(const SubmitQuizResults('s1', [true, false, true]));
    await Future<void>.delayed(Duration.zero);

    final captured = verify(() => ds.submitQuiz(
          skillId: captureAny(named: 'skillId'),
          answers: captureAny(named: 'answers'),
        )).captured;
    expect(captured[0], 's1');
    expect(captured[1], [true, false, true]);
    await bloc.close();
  });
}
