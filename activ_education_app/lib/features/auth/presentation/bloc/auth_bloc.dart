import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository;

  AuthBloc(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._authRepository,
  ) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final isAuthenticated = await _authRepository.isAuthenticated();

    if (isAuthenticated) {
      final cachedUser = await _authRepository.getCachedUser();
      if (cachedUser != null) {
        emit(AuthAuthenticated(cachedUser));
        return;
      }

      // Essayer de recuperer le profil
      final result = await _getCurrentUserUseCase();
      result.fold(
        (failure) => emit(AuthUnauthenticated()),
        (profile) => emit(AuthAuthenticated(profile)),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message, failure.type)),
      (authResult) => emit(AuthAuthenticated(authResult.user)),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _registerUseCase(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      phoneNumber: event.phoneNumber,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message, failure.type)),
      (authResult) => emit(AuthAuthenticated(authResult.user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await _logoutUseCase();

    emit(AuthUnauthenticated());
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.refreshTokens();

    result.fold(
      (failure) {
        if (failure.type == AuthFailureType.tokenExpired) {
          emit(AuthUnauthenticated());
        }
      },
      (_) {
        // Tokens refreshed, ne pas changer l'etat
      },
    );
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.forgotPassword(event.email);

    result.fold(
      (failure) => emit(AuthError(failure.message, failure.type)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.resetPassword(
      token: event.token,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message, failure.type)),
      (_) => emit(AuthPasswordResetSuccess()),
    );
  }
}
