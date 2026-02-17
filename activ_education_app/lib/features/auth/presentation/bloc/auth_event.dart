part of 'auth_bloc.dart';

/// Evenements du BLoC d'authentification.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Verifie l'etat d'authentification au demarrage.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Demande de connexion.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Demande d'inscription.
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, phoneNumber];
}

/// Demande de deconnexion.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Demande de rafraichissement des tokens.
class AuthRefreshRequested extends AuthEvent {
  const AuthRefreshRequested();
}

/// Demande de reinitialisation de mot de passe.
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

/// Demande de reinitialisation avec token.
class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object> get props => [token, newPassword];
}
