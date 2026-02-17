import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage securise des tokens d'authentification.
///
/// Utilise SharedPreferences pour la persistance.
/// En production, envisager flutter_secure_storage pour plus de securite.
@lazySingleton
class TokenStorage {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _userIdKey = 'auth_user_id';

  SharedPreferences? _prefs;

  /// Initialise le stockage (doit etre appele au demarrage).
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Verifie si le stockage est initialise.
  bool get isInitialized => _prefs != null;

  /// Assure l'initialisation avant toute operation.
  Future<SharedPreferences> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Sauvegarde les tokens d'authentification.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? userId,
  }) async {
    final prefs = await _ensureInitialized();

    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
      if (expiresAt != null)
        prefs.setInt(_tokenExpiryKey, expiresAt.millisecondsSinceEpoch),
      if (userId != null) prefs.setString(_userIdKey, userId),
    ]);

    debugPrint('[TokenStorage] Tokens saved successfully');
  }

  /// Recupere le token d'acces.
  Future<String?> getAccessToken() async {
    final prefs = await _ensureInitialized();
    return prefs.getString(_accessTokenKey);
  }

  /// Recupere le token de rafraichissement.
  Future<String?> getRefreshToken() async {
    final prefs = await _ensureInitialized();
    return prefs.getString(_refreshTokenKey);
  }

  /// Recupere l'ID utilisateur stocke.
  Future<String?> getUserId() async {
    final prefs = await _ensureInitialized();
    return prefs.getString(_userIdKey);
  }

  /// Recupere la date d'expiration du token.
  Future<DateTime?> getTokenExpiry() async {
    final prefs = await _ensureInitialized();
    final expiryMs = prefs.getInt(_tokenExpiryKey);
    if (expiryMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiryMs);
  }

  /// Verifie si le token est expire.
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    // Considerer comme expire 5 minutes avant l'expiration reelle
    final bufferTime = expiry.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(bufferTime);
  }

  /// Verifie si un utilisateur est authentifie.
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return false;
    }

    // Meme si le access token est expire, on peut rafraichir
    return true;
  }

  /// Supprime tous les tokens (deconnexion).
  Future<void> clearTokens() async {
    final prefs = await _ensureInitialized();

    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_userIdKey),
    ]);

    debugPrint('[TokenStorage] Tokens cleared');
  }

  /// Met a jour uniquement le token d'acces (apres refresh).
  Future<void> updateAccessToken(String accessToken, {DateTime? expiresAt}) async {
    final prefs = await _ensureInitialized();

    await prefs.setString(_accessTokenKey, accessToken);
    if (expiresAt != null) {
      await prefs.setInt(_tokenExpiryKey, expiresAt.millisecondsSinceEpoch);
    }

    debugPrint('[TokenStorage] Access token updated');
  }
}
