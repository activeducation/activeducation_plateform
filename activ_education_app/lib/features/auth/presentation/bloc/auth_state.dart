part of 'auth_bloc.dart';

/// Etats du BLoC d'authentification.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Etat initial.
class AuthInitial extends AuthState {}

/// Chargement en cours.
class AuthLoading extends AuthState {}

/// Utilisateur authentifie.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

/// Utilisateur non authentifie.
class AuthUnauthenticated extends AuthState {}

/// Erreur d'authentification.
class AuthError extends AuthState {
  final String message;
  final AuthFailureType? type;

  const AuthError(this.message, [this.type]);

  @override
  List<Object?> get props => [message, type];
}

/// Email de reinitialisation envoye.
class AuthPasswordResetSent extends AuthState {}

/// Mot de passe reinitialise avec succes.
class AuthPasswordResetSuccess extends AuthState {}
