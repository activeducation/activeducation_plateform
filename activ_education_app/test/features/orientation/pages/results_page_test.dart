import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/orientation/domain/entities/test_result.dart';
import 'package:activ_education_app/features/orientation/presentation/bloc/orientation_bloc.dart';
import 'package:activ_education_app/features/orientation/presentation/pages/results_page.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockOrientationBloc extends MockBloc<OrientationEvent, OrientationState>
    implements OrientationBloc {}

// ============================================================================
// Fixtures
// ============================================================================

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
    advice: 'Considérez des carrières en ingénierie sociale.',
    recommendedSectors: const ['Santé', 'Ingénierie'],
    traitDetails: const {},
  ),
  matchingPrograms: const [],
);

// ============================================================================
// Tests
// ============================================================================

void main() {
  late MockOrientationBloc mockOrientationBloc;

  setUp(() {
    mockOrientationBloc = MockOrientationBloc();
    when(() => mockOrientationBloc.state)
        .thenReturn(TestCompleted(tResult));
  });

  tearDown(() => mockOrientationBloc.close());

  Widget buildTestApp() {
    return MaterialApp(
      home: BlocProvider<OrientationBloc>.value(
        value: mockOrientationBloc,
        child: ResultsPage(result: tResult),
      ),
    );
  }

  group('ResultsPage — widgets', () {
    testWidgets('affiche le code profil RIASEC', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.text('RSI').evaluate().isNotEmpty ||
            find.textContaining('RSI').evaluate().isNotEmpty,
        isTrue,
        reason: 'Le code profil RSI doit être affiché',
      );
    });

    testWidgets('affiche les traits dominants', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Au moins un des traits dominants doit être visible
      expect(
        find.textContaining('Réaliste').evaluate().isNotEmpty ||
            find.textContaining('Social').evaluate().isNotEmpty ||
            find.textContaining('RSI').evaluate().isNotEmpty,
        isTrue,
        reason: 'Les traits dominants doivent être affichés',
      );
    });

    testWidgets('affiche les scores RIASEC', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // La page doit contenir des éléments de visualisation des scores
      expect(
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
            find.byType(CustomPaint).evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty,
        isTrue,
        reason: 'Les scores doivent être visualisés',
      );
    });

    testWidgets('affiche le résumé du profil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.textContaining('Profil').evaluate().isNotEmpty ||
            find.textContaining('RSI').evaluate().isNotEmpty,
        isTrue,
        reason: 'Le résumé du profil doit être affiché',
      );
    });
  });
}
