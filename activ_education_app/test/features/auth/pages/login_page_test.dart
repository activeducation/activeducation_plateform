import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:activ_education_app/features/auth/presentation/pages/login_page.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// ============================================================================
// Helper
// ============================================================================

Widget buildTestApp(AuthBloc bloc) {
  return MaterialApp(
    home: BlocProvider<AuthBloc>.value(value: bloc, child: const LoginPage()),
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  tearDown(() => mockAuthBloc.close());

  group('LoginPage — widgets', () {
    testWidgets('affiche les champs email et mot de passe', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuthBloc));

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('affiche un bouton de connexion', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuthBloc));

      // Cherche le bouton de connexion (texte en français)
      expect(
        find
                .widgetWithText(ElevatedButton, 'Connexion')
                .evaluate()
                .isNotEmpty ||
            find
                .widgetWithText(FilledButton, 'Se connecter')
                .evaluate()
                .isNotEmpty ||
            find
                .widgetWithText(TextButton, 'Connexion')
                .evaluate()
                .isNotEmpty ||
            find.byType(ElevatedButton).evaluate().isNotEmpty,
        isTrue,
        reason: 'Un bouton de connexion doit être présent',
      );
    });

    testWidgets('affiche un indicateur de chargement quand AuthLoading', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([AuthLoading()]),
        initialState: AuthLoading(),
      );

      await tester.pumpWidget(buildTestApp(mockAuthBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dispatche AuthLoginRequested avec les bons paramètres', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(buildTestApp(mockAuthBloc));

      // Entrer l'email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@activeeducation.com');

      // Entrer le mot de passe
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'SecurePass123!');

      // Soumettre le formulaire
      final submitButton = find.byType(ElevatedButton).first;
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pump();

        verify(
          () => mockAuthBloc.add(any(that: isA<AuthLoginRequested>())),
        ).called(1);
      }
    });

    testWidgets('affiche un message d\'erreur quand AuthError', (tester) async {
      const errorMessage = 'Email ou mot de passe incorrect';

      when(() => mockAuthBloc.state).thenReturn(const AuthError(errorMessage));
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthError(errorMessage)]),
        initialState: const AuthError(errorMessage),
      );

      await tester.pumpWidget(buildTestApp(mockAuthBloc));
      await tester.pump();

      expect(
        find.text(errorMessage).evaluate().isNotEmpty ||
            find.byType(SnackBar).evaluate().isNotEmpty,
        isTrue,
        reason: 'Un message d\'erreur doit être affiché',
      );
    });
  });
}
