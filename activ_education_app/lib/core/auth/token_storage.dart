import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage securise des tokens d'authentification.
///
/// Utilise flutter_secure_storage (Keychain iOS / Keystore Android / DPAPI Web)
/// pour les donnees sensibles (access & refresh tokens). Les metadonnees non
/// sensibles (expiration, user id) restent dans SharedPreferences.
///
/// Migration automatique: au premier acces, si d'anciens tokens existent dans
/// SharedPreferences (versions <= 1.x), ils sont transferes vers le stockage
/// securise et supprimes du stockage en clair.
@lazySingleton
class TokenStorage {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _userIdKey = 'auth_user_id';

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;
  bool _migrationChecked = false;

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Initialise le stockage (doit etre appele au demarrage).
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrateLegacyTokensIfNeeded();
  }

  /// Verifie si le stockage est initialise.
  bool get isInitialized => _prefs != null;

  Future<SharedPreferences> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Migre les tokens des versions precedentes (SharedPreferences plaintext)
  /// vers flutter_secure_storage, puis les supprime du stockage non chiffre.
  Future<void> _migrateLegacyTokensIfNeeded() async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    final prefs = _prefs!;
    final legacyAccess = prefs.getString(_accessTokenKey);
    final legacyRefresh = prefs.getString(_refreshTokenKey);

    if (legacyAccess == null && legacyRefresh == null) return;

    try {
      if (legacyAccess != null) {
        await _secure.write(key: _accessTokenKey, value: legacyAccess);
      }
      if (legacyRefresh != null) {
        await _secure.write(key: _refreshTokenKey, value: legacyRefresh);
      }
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      debugPrint('[TokenStorage] Migrated legacy tokens to secure storage');
    } catch (e) {
      debugPrint('[TokenStorage] Legacy token migration failed: $e');
    }
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
      _secure.write(key: _accessTokenKey, value: accessToken),
      _secure.write(key: _refreshTokenKey, value: refreshToken),
      if (expiresAt != null)
        prefs.setInt(_tokenExpiryKey, expiresAt.millisecondsSinceEpoch),
      if (userId != null) prefs.setString(_userIdKey, userId),
    ]);
  }

  /// Recupere le token d'acces.
  Future<String?> getAccessToken() async {
    await _ensureInitialized();
    return _secure.read(key: _accessTokenKey);
  }

  /// Recupere le token de rafraichissement.
  Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    return _secure.read(key: _refreshTokenKey);
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

  /// Verifie si le token est expire (avec buffer 5 min).
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    final bufferTime = expiry.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(bufferTime);
  }

  /// Verifie si un utilisateur est authentifie.
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Supprime tous les tokens (deconnexion).
  Future<void> clearTokens() async {
    final prefs = await _ensureInitialized();

    await Future.wait([
      _secure.delete(key: _accessTokenKey),
      _secure.delete(key: _refreshTokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_userIdKey),
    ]);
  }

  /// Met a jour uniquement le token d'acces (apres refresh).
  Future<void> updateAccessToken(String accessToken,
      {DateTime? expiresAt}) async {
    final prefs = await _ensureInitialized();

    await _secure.write(key: _accessTokenKey, value: accessToken);
    if (expiresAt != null) {
      await prefs.setInt(_tokenExpiryKey, expiresAt.millisecondsSinceEpoch);
    }
  }
}
