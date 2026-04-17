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

final tUser = UserProfile(
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
    registerFallbackValue('');
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockAuthRepository = MockAuthRepository();

    // Defaults pour AuthCheckRequested
    when(
      () => mockAuthRepository.isAuthenticated(),
    ).thenAnswer((_) async => false);
    when(
      () => mockAuthRepository.getCachedUser(),
    ).thenAnswer((_) async => null);

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
        when(
          () => mockAuthRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockAuthRepository.getCachedUser(),
        ).thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] quand aucun utilisateur connecté',
      build: () {
        when(
          () => mockAuthRepository.isAuthenticated(),
        ).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });

  // --------------------------------------------------------------------------
  // AuthLoginRequested
  // --------------------------------------------------------------------------

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] sur login réussi',
      build: () {
        when(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@activeeducation.com',
          password: 'SecurePass123!',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (_) {
        verify(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthError] sur login échoué',
      build: () {
        when(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@activeeducation.com',
          password: 'wrong',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
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
        when(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@activeeducation.com',
          password: 'SecurePass123!',
        ),
      ),
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
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] sur inscription réussie',
      build: () {
        when(
          () => mockRegisterUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer((_) async => Right(tAuthResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: 'nouveau@activeeducation.com',
          password: 'SecurePass123!',
          firstName: 'Ama',
          lastName: 'Koffi',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthError] si email déjà utilisé',
      build: () {
        when(
          () => mockRegisterUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer((_) async => Left(AuthFailure.emailAlreadyExists()));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: 'nouveau@activeeducation.com',
          password: 'SecurePass123!',
          firstName: 'Ama',
          lastName: 'Koffi',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });

  // --------------------------------------------------------------------------
  // AuthLogoutRequested
  // --------------------------------------------------------------------------

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] sur déconnexion',
      build: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
