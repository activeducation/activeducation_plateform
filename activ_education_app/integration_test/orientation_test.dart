/// Tests E2E — Parcours d'orientation
///
/// Couvre : affichage des tests → chargement → gestion des erreurs
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:activ_education_app/features/auth/domain/entities/user.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:activ_education_app/features/orientation/presentation/bloc/orientation_bloc.dart';
import 'package:activ_education_app/features/orientation/domain/entities/orientation_test.dart';
import 'package:activ_education_app/features/orientation/domain/entities/test_result.dart';
import 'package:activ_education_app/features/orientation/presentation/pages/test_selection_page.dart';
import 'package:activ_education_app/core/theme/theme.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockOrientationBloc
    extends MockBloc<OrientationEvent, OrientationState>
    implements OrientationBloc {}

// ============================================================================
// Fixtures
// ============================================================================

final _testUser = User(
  id: 'test-user-id',
  email: 'test@activeeducation.com',
  firstName: 'Test',
  lastName: 'User',
  createdAt: DateTime(2024, 1, 1),
);

final _mockTests = [
  OrientationTest(
    id: 'test-1',
    name: 'Test RIASEC',
    description: "Découvrez votre profil d'orientation",
    type: TestType.riasec,
    durationMinutes: 20,
    questions: const [],
  ),
];

final _mockResult = TestResult(
  testId: 'test-1',
  scores: const {'R': 85, 'I': 72, 'A': 68, 'S': 45, 'E': 38, 'C': 30},
  dominantTraits: const ['Réaliste', 'Investigateur', 'Artistique'],
  recommendations: const [],
);

// ============================================================================
// Helper
// ============================================================================

Widget buildOrientationTestApp({
  required AuthBloc authBloc,
  required OrientationBloc orientationBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<OrientationBloc>.value(value: orientationBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      home: const TestSelectionPage(),
    ),
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockOrientationBloc mockOrientationBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockOrientationBloc = MockOrientationBloc();

    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(_testUser));
  });

  tearDown(() {
    mockAuthBloc.close();
    mockOrientationBloc.close();
  });

  group('Parcours Orientation E2E', () {
    testWidgets('Affiche la liste des tests disponibles', (tester) async {
      when(() => mockOrientationBloc.state)
          .thenReturn(OrientationTestsLoaded(_mockTests));
      whenListen(
        mockOrientationBloc,
        Stream.fromIterable([OrientationTestsLoaded(_mockTests)]),
        initialState: OrientationTestsLoaded(_mockTests),
      );

      await tester.pumpWidget(buildOrientationTestApp(
        authBloc: mockAuthBloc,
        orientationBloc: mockOrientationBloc,
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.byType(ListView).evaluate().isNotEmpty ||
            find.byType(GridView).evaluate().isNotEmpty ||
            find.text('Test RIASEC').evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty,
        isTrue,
        reason: 'La liste des tests doit être affichée',
      );
    });

    testWidgets('Affiche un indicateur de chargement', (tester) async {
      when(() => mockOrientationBloc.state).thenReturn(OrientationLoading());
      whenListen(
        mockOrientationBloc,
        Stream.fromIterable([OrientationLoading()]),
        initialState: OrientationLoading(),
      );

      await tester.pumpWidget(buildOrientationTestApp(
        authBloc: mockAuthBloc,
        orientationBloc: mockOrientationBloc,
      ));
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.byType(LinearProgressIndicator).evaluate().isNotEmpty,
        isTrue,
        reason: 'Un indicateur de chargement doit être affiché',
      );
    });

    testWidgets("Affiche un message d'erreur sur échec de chargement",
        (tester) async {
      const errorMsg = 'Erreur de connexion';
      when(() => mockOrientationBloc.state)
          .thenReturn(const OrientationError(errorMsg));
      whenListen(
        mockOrientationBloc,
        Stream.fromIterable([const OrientationError(errorMsg)]),
        initialState: const OrientationError(errorMsg),
      );

      await tester.pumpWidget(buildOrientationTestApp(
        authBloc: mockAuthBloc,
        orientationBloc: mockOrientationBloc,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(errorMsg).evaluate().isNotEmpty ||
            find.byType(SnackBar).evaluate().isNotEmpty ||
            find.byKey(const Key('orientation_error')).evaluate().isNotEmpty,
        isTrue,
        reason: "Un message d'erreur doit être affiché",
      );
    });

    testWidgets('Dispatche LoadOrientationTests au démarrage', (tester) async {
      when(() => mockOrientationBloc.state).thenReturn(OrientationInitial());
      whenListen(
        mockOrientationBloc,
        Stream.fromIterable([
          OrientationLoading(),
          OrientationTestsLoaded(_mockTests),
        ]),
        initialState: OrientationInitial(),
      );

      await tester.pumpWidget(buildOrientationTestApp(
        authBloc: mockAuthBloc,
        orientationBloc: mockOrientationBloc,
      ));
      await tester.pumpAndSettle();

      verify(() => mockOrientationBloc
          .add(any(that: isA<LoadOrientationTests>()))).called(1);
    });
  });
}
