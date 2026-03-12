/// Helper pour les tests E2E — construit une version mockée de l'app
/// sans dépendances réseau ni backend réel.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/auth/domain/entities/user.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:activ_education_app/features/auth/presentation/pages/login_page.dart';
import 'package:activ_education_app/features/home/presentation/pages/home_page.dart';
import 'package:activ_education_app/core/theme/theme.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// ============================================================================
// Fixture utilisateur de test
// ============================================================================

final _testUser = User(
  id: 'test-user-id',
  email: 'test@activeeducation.com',
  firstName: 'Test',
  lastName: 'User',
  createdAt: DateTime(2024, 1, 1),
);

// ============================================================================
// MockAppRunner
// ============================================================================

/// Construit un widget d'application complet avec des mocks injectés.
///
/// Paramètres :
/// - [startAuthenticated] : démarrer en état connecté (pour tester déconnexion)
/// - [simulateAuthError] : simuler une erreur d'authentification
class MockAppRunner {
  MockAppRunner._();

  static Widget build({
    bool startAuthenticated = false,
    bool simulateAuthError = false,
  }) {
    final mockAuthBloc = MockAuthBloc();

    if (startAuthenticated) {
      // État initial : utilisateur connecté
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(_testUser));
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([AuthAuthenticated(_testUser)]),
        initialState: AuthAuthenticated(_testUser),
      );
    } else if (simulateAuthError) {
      // État initial : connecté, puis erreur après tentative de login
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          AuthLoading(),
          const AuthError('Email ou mot de passe incorrect'),
        ]),
        initialState: AuthInitial(),
      );
    } else {
      // État initial : non connecté
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          AuthLoading(),
          AuthAuthenticated(_testUser),
        ]),
        initialState: AuthInitial(),
      );
    }

    return _MockApp(
      authBloc: mockAuthBloc,
      startAuthenticated: startAuthenticated,
    );
  }
}

// ============================================================================
// Widget applicatif minimal pour les tests E2E
// ============================================================================

class _MockApp extends StatelessWidget {
  final AuthBloc authBloc;
  final bool startAuthenticated;

  const _MockApp({
    required this.authBloc,
    required this.startAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        title: 'ActivEducation — Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const _MockHomePage();
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Pages simulées pour les tests E2E
// ============================================================================

/// Page d'accueil simulée avec les clés attendues par les tests.
class _MockHomePage extends StatelessWidget {
  const _MockHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home_page'),
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            key: const Key('profile_button'),
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => _ProfileMenu(parentContext: context),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Tableau de bord', key: Key('dashboard_page')),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final BuildContext parentContext;

  const _ProfileMenu({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('logout_button'),
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              parentContext
                  .read<AuthBloc>()
                  .add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}
