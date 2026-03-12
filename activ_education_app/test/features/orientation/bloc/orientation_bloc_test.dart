import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/orientation/domain/entities/orientation_test.dart';
import 'package:activ_education_app/features/orientation/domain/entities/test_result.dart';
import 'package:activ_education_app/features/orientation/domain/usecases/get_orientation_tests.dart';
import 'package:activ_education_app/features/orientation/domain/usecases/submit_test.dart';
import 'package:activ_education_app/features/orientation/presentation/bloc/orientation_bloc.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockGetOrientationTests extends Mock implements GetOrientationTests {}
class MockSubmitTest extends Mock implements SubmitTest {}

// ============================================================================
// Fixtures
// ============================================================================

final tTests = [
  OrientationTest(
    id: 'test-riasec-1',
    name: 'Test RIASEC',
    description: 'Découvrez votre profil d\'orientation',
    type: TestType.riasec,
    durationMinutes: 15,
    questions: const [],
  ),
  OrientationTest(
    id: 'test-personality-1',
    name: 'Test de Personnalité',
    description: 'Explorez votre personnalité',
    type: TestType.personality,
    durationMinutes: 10,
    questions: const [],
  ),
];

final tResult = TestResult(
  testId: 'test-riasec-1',
  scores: const {'R': 0.8, 'I': 0.6, 'A': 0.4, 'S': 0.7, 'E': 0.5, 'C': 0.3},
  dominantTraits: const ['R', 'S', 'I'],
  recommendations: const [],
  interpretation: ProfileInterpretation(
    profileSummary: 'Profil RSI — Réaliste, Social, Investigateur',
    profileCode: 'RSI',
    strengths: const ['Résolution de problèmes', 'Travail en équipe'],
    workStyle: 'Pratique et collaboratif',
    advice: 'Considérez des carrières en ingénierie sociale ou en médecine.',
    recommendedSectors: const ['Santé', 'Ingénierie'],
    traitDetails: const {},
  ),
  matchingPrograms: const [],
);

// ============================================================================
// Tests
// ============================================================================

void main() {
  late MockGetOrientationTests mockGetOrientationTests;
  late MockSubmitTest mockSubmitTest;
  late OrientationBloc orientationBloc;

  setUpAll(() {
    registerFallbackValue(const SubmitTestParams(testId: '', responses: {}));
  });

  setUp(() {
    mockGetOrientationTests = MockGetOrientationTests();
    mockSubmitTest = MockSubmitTest();

    orientationBloc = OrientationBloc(
      mockGetOrientationTests,
      mockSubmitTest,
    );
  });

  tearDown(() => orientationBloc.close());

  // --------------------------------------------------------------------------
  // État initial
  // --------------------------------------------------------------------------

  test('état initial est OrientationInitial', () {
    expect(orientationBloc.state, isA<OrientationInitial>());
  });

  // --------------------------------------------------------------------------
  // LoadOrientationTests
  // --------------------------------------------------------------------------

  group('LoadOrientationTests', () {
    blocTest<OrientationBloc, OrientationState>(
      'émet [OrientationLoading, OrientationTestsLoaded] sur succès',
      build: () {
        when(() => mockGetOrientationTests())
            .thenAnswer((_) async => Right(tTests));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(LoadOrientationTests()),
      expect: () => [
        isA<OrientationLoading>(),
        isA<OrientationTestsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockGetOrientationTests()).called(1);
      },
    );

    blocTest<OrientationBloc, OrientationState>(
      'OrientationTestsLoaded contient les bons tests',
      build: () {
        when(() => mockGetOrientationTests())
            .thenAnswer((_) async => Right(tTests));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(LoadOrientationTests()),
      expect: () => [
        isA<OrientationLoading>(),
        predicate<OrientationState>(
          (s) => s is OrientationTestsLoaded && s.tests.length == 2,
          'OrientationTestsLoaded avec 2 tests',
        ),
      ],
    );

    blocTest<OrientationBloc, OrientationState>(
      'émet [OrientationLoading, OrientationError] sur erreur réseau',
      build: () {
        when(() => mockGetOrientationTests())
            .thenAnswer((_) async => Left(ServerFailure('Erreur réseau')));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(LoadOrientationTests()),
      expect: () => [
        isA<OrientationLoading>(),
        isA<OrientationError>(),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // SubmitTestEvent
  // --------------------------------------------------------------------------

  group('SubmitTestEvent', () {
    final tEvent = SubmitTestEvent(
      testId: 'test-riasec-1',
      responses: const {
        'q1': 5,
        'q2': 3,
        'q3': 4,
      },
    );

    blocTest<OrientationBloc, OrientationState>(
      'émet [TestSubmitting, TestCompleted] sur soumission réussie',
      build: () {
        when(() => mockSubmitTest(any()))
            .thenAnswer((_) async => Right(tResult));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<TestSubmitting>(),
        isA<TestCompleted>(),
      ],
    );

    blocTest<OrientationBloc, OrientationState>(
      'TestCompleted contient le bon résultat',
      build: () {
        when(() => mockSubmitTest(any()))
            .thenAnswer((_) async => Right(tResult));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<TestSubmitting>(),
        predicate<OrientationState>(
          (s) => s is TestCompleted && s.result.dominantTraits.contains('R'),
          'TestCompleted avec le trait dominant R',
        ),
      ],
    );

    blocTest<OrientationBloc, OrientationState>(
      'émet [TestSubmitting, OrientationError] sur erreur de soumission',
      build: () {
        when(() => mockSubmitTest(any()))
            .thenAnswer((_) async => Left(ServerFailure('Erreur serveur')));
        return orientationBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<TestSubmitting>(),
        isA<OrientationError>(),
      ],
    );
  });
}
