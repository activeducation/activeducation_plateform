/// Interface abstraite pour le stockage des tokens d'authentification.
///
/// Les deux apps (activ_education_app et admin_dashboard) implémentent cette
/// interface avec leurs propres besoins (async vs synchrone, champs différents).
abstract class ITokenStorage {
  /// Retourne le token d'accès courant, ou null si absent.
  Future<String?> getAccessToken();

  /// Retourne le token de rafraîchissement, ou null si absent.
  Future<String?> getRefreshToken();

  /// Retourne l'ID utilisateur stocké, ou null si absent.
  Future<String?> getUserId();

  /// Sauvegarde la paire de tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Efface tous les tokens (déconnexion).
  Future<void> clearTokens();

  /// Indique si l'utilisateur est connecté (token d'accès présent).
  Future<bool> get isLoggedIn;
}

/// Clés de stockage standards utilisées par les deux apps.
/// Chaque app peut redéfinir ses propres clés si nécessaire.
class TokenStorageKeys {
  const TokenStorageKeys._();

  static const String accessToken = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String tokenExpiry = 'auth_token_expiry';
  static const String userId = 'auth_user_id';
  static const String userEmail = 'auth_user_email';
  static const String userRole = 'auth_user_role';

  /// Préfixe pour l'app admin (évite les conflits si les deux apps utilisent
  /// le même appareil en dev).
  static const String adminPrefix = 'admin_';
}

/// Durée tampon avant expiration pour rafraîchir proactivement le token.
const tokenExpiryBuffer = Duration(minutes: 5);
