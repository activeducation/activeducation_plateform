import 'package:dartz/dartz.dart';
import '../entities/user.dart';

/// Repository abstrait pour l'authentification.
abstract class AuthRepository {
  /// Connecte un utilisateur avec email et mot de passe.
  Future<Either<AuthFailure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// Inscrit un nouvel utilisateur.
  Future<Either<AuthFailure, AuthResult>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });

  /// Deconnecte l'utilisateur courant.
  Future<Either<AuthFailure, void>> logout();

  /// Rafraichit les tokens avec le refresh token.
  Future<Either<AuthFailure, AuthTokens>> refreshTokens();

  /// Demande une reinitialisation de mot de passe.
  Future<Either<AuthFailure, void>> forgotPassword(String email);

  /// Reinitialise le mot de passe avec un token.
  Future<Either<AuthFailure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Change le mot de passe de l'utilisateur connecte.
  Future<Either<AuthFailure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Recupere le profil de l'utilisateur courant.
  Future<Either<AuthFailure, UserProfile>> getCurrentUserProfile();

  /// Met a jour le profil de l'utilisateur courant.
  Future<Either<AuthFailure, UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? schoolName,
    String? classLevel,
  });

  /// Verifie si l'utilisateur est connecte.
  Future<bool> isAuthenticated();

  /// Recupere l'utilisateur courant depuis le cache.
  Future<User?> getCachedUser();

  /// Recupere les tokens stockes.
  Future<AuthTokens?> getStoredTokens();
}

/// Types d'erreurs d'authentification.
enum AuthFailureType {
  invalidCredentials,
  emailAlreadyExists,
  weakPassword,
  networkError,
  serverError,
  tokenExpired,
  tokenInvalid,
  unauthorized,
  unknown,
}

/// Classe representant une erreur d'authentification.
class AuthFailure {
  final AuthFailureType type;
  final String message;
  final dynamic originalError;

  const AuthFailure({
    required this.type,
    required this.message,
    this.originalError,
  });

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        type: AuthFailureType.invalidCredentials,
        message: 'Email ou mot de passe incorrect',
      );

  factory AuthFailure.emailAlreadyExists() => const AuthFailure(
        type: AuthFailureType.emailAlreadyExists,
        message: 'Cet email est deja utilise',
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        type: AuthFailureType.weakPassword,
        message: 'Le mot de passe est trop faible',
      );

  factory AuthFailure.networkError() => const AuthFailure(
        type: AuthFailureType.networkError,
        message: 'Erreur de connexion reseau',
      );

  factory AuthFailure.serverError([String? message]) => AuthFailure(
        type: AuthFailureType.serverError,
        message: message ?? 'Erreur serveur',
      );

  factory AuthFailure.tokenExpired() => const AuthFailure(
        type: AuthFailureType.tokenExpired,
        message: 'Session expiree, veuillez vous reconnecter',
      );

  factory AuthFailure.tokenInvalid() => const AuthFailure(
        type: AuthFailureType.tokenInvalid,
        message: 'Token invalide',
      );

  factory AuthFailure.unauthorized() => const AuthFailure(
        type: AuthFailureType.unauthorized,
        message: 'Acces non autorise',
      );

  factory AuthFailure.unknown([dynamic error]) => AuthFailure(
        type: AuthFailureType.unknown,
        message: 'Une erreur inattendue s\'est produite',
        originalError: error,
      );

  @override
  String toString() => 'AuthFailure($type): $message';
}
