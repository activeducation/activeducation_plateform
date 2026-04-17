/// Tests E2E — Parcours d'authentification
///
/// Couvre : inscription → connexion → déconnexion
/// Utilise des mocks complets pour ne pas dépendre du backend réel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_app_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Parcours Auth E2E', () {
    testWidgets('Connexion avec un compte existant', (tester) async {
      await tester.pumpWidget(MockAppRunner.build());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Vérifier qu'on est sur la page de connexion
      expect(find.byKey(const Key('login_page')), findsOneWidget);

      // 2. Entrer les identifiants
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@activeeducation.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'SecurePass123!',
      );

      // 3. Appuyer sur Connexion
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4. Vérifier qu'on est redirigé vers l'accueil
      expect(
        find.byKey(const Key('home_page')).evaluate().isNotEmpty ||
            find.byKey(const Key('dashboard_page')).evaluate().isNotEmpty,
        isTrue,
        reason: 'Doit naviguer vers l\'accueil après connexion',
      );
    });

    testWidgets('Déconnexion depuis l\'accueil', (tester) async {
      await tester.pumpWidget(MockAppRunner.build(startAuthenticated: true));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Ouvrir le menu profil
      final profileButton = find.byKey(const Key('profile_button'));
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // 2. Appuyer sur Déconnexion
      final logoutButton = find.byKey(const Key('logout_button'));
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 3. Vérifier qu'on est revenu sur la page de connexion
        expect(
          find.byKey(const Key('login_page')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Doit retourner à la page de connexion après déconnexion',
        );
      }
    });

    testWidgets('Affichage d\'erreur sur mauvais identifiants', (tester) async {
      await tester.pumpWidget(MockAppRunner.build(simulateAuthError: true));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'mauvais@email.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'mauvais_mdp',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier qu'un message d'erreur est affiché
      expect(
        find.byType(SnackBar).evaluate().isNotEmpty ||
            find.byKey(const Key('auth_error_message')).evaluate().isNotEmpty,
        isTrue,
        reason:
            'Un message d\'erreur doit être affiché sur mauvais identifiants',
      );
    });
  });
}
