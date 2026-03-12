import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/auth/domain/entities/user.dart';
import 'package:activ_education_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:activ_education_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:activ_education_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:activ_education_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:activ_education_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:activ_education_app/features/auth/presentation/bloc/auth_state.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

// ============================================================================
// Fixtures
// ============================================================================

final tUser = User(
  id: 'user-123',
  email: 'test@activeeducation.com',
  firstName: 'Kofi',
  lastName: 'Mensah',
  createdAt: DateTime(2025, 1, 1),
);

final tTokens = AuthTokens(
  accessToken: 'access_token_test',
  refreshToken: 'refresh_token_test',
  expiresIn: 1800,
);

final tAuthResult = AuthResult(user: tUser, tokens: tTokens);

// ============================================================================
// Tests
// ============================================================================

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const RegisterParams(
      email: '',
      password: '',
      firstName: '',
      lastName: '',
    ));
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockAuthRepository = MockAuthRepository();

    authBloc = AuthBloc(
      mockLoginUseCase,
      mockRegisterUseCase,
      mockLogoutUseCase,
      mockGetCurrentUserUseCase,
      mockAuthRepository,
    );
  });

  tearDown(() => authBloc.close());

  // --------------------------------------------------------------------------
  // État initial
  // --------------------------------------------------------------------------

  test('état initial est AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  // --------------------------------------------------------------------------
  // AuthCheckRequested
  // --------------------------------------------------------------------------

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] quand un utilisateur est connecté',
      build: () {
        when(() => mockGetCurrentUserUseCase())
            .thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockGetCurrentUserUseCase()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] quand aucun utilisateur connecté',
      build: () {
        when(() => mockGetCurrentUserUseCase())
            .thenAnswer((_) async => Left(AuthFailure('Non connecté')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // AuthLoginRequested
  // --------------------------------------------------------------------------

  group('AuthLoginRequested', () {
    const tEvent = AuthLoginRequested(
      email: 'test@activeeducation.com',
      password: 'SecurePass123!',
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] sur login réussi',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthError] sur login échoué',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Left(AuthFailure('Email ou mot de passe incorrect')));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
      verify: (_) {
        final errorState = authBloc.state;
        if (errorState is AuthError) {
          expect(errorState.message, isNotEmpty);
        }
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthAuthenticated contient le bon utilisateur',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        predicate<AuthState>(
          (s) => s is AuthAuthenticated && s.user.email == tUser.email,
          'AuthAuthenticated avec le bon utilisateur',
        ),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // AuthRegisterRequested
  // --------------------------------------------------------------------------

  group('AuthRegisterRequested', () {
    const tEvent = AuthRegisterRequested(
      email: 'nouveau@activeeducation.com',
      password: 'SecurePass123!',
      firstName: 'Ama',
      lastName: 'Koffi',
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] sur inscription réussie',
      build: () {
        when(() => mockRegisterUseCase(any()))
            .thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthError] si email déjà utilisé',
      build: () {
        when(() => mockRegisterUseCase(any()))
            .thenAnswer((_) async => Left(AuthFailure('Email déjà utilisé')));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });

  // --------------------------------------------------------------------------
  // AuthLogoutRequested
  // --------------------------------------------------------------------------

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] sur déconnexion',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}
