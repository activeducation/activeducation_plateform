import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage securise des tokens et des infos de session admin.
///
/// - Access & refresh tokens: flutter_secure_storage (Keychain/Keystore).
/// - Metadonnees (email, nom, role): SharedPreferences (non sensibles).
///
/// Les getters sync sont conserves pour compatibilite avec le code existant:
/// une copie en memoire est hydratee depuis le stockage securise au `init()`
/// et synchronisee a chaque ecriture. La copie memoire disparait a la
/// fermeture du process — seul le Keychain persiste.
///
/// Migration: si d'anciennes installations stockaient les tokens dans
/// SharedPreferences en clair, `init()` les deplace vers secure_storage.
class TokenStorage {
  static const _accessTokenKey = 'admin_access_token';
  static const _refreshTokenKey = 'admin_refresh_token';
  static const _userIdKey = 'admin_user_id';
  static const _userEmailKey = 'admin_user_email';
  static const _userRoleKey = 'admin_user_role';
  static const _userNameKey = 'admin_user_name';

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  String? _accessTokenCache;
  String? _refreshTokenCache;

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyTokensIfNeeded();
    _accessTokenCache = await _secure.read(key: _accessTokenKey);
    _refreshTokenCache = await _secure.read(key: _refreshTokenKey);
  }

  Future<void> _migrateLegacyTokensIfNeeded() async {
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
    } catch (_) {
      // migration best-effort; les prochains saveTokens remettront l'etat propre
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
    await _secure.write(key: _accessTokenKey, value: accessToken);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String role,
    String? name,
  }) async {
    await _prefs?.setString(_userIdKey, userId);
    await _prefs?.setString(_userEmailKey, email);
    await _prefs?.setString(_userRoleKey, role);
    if (name != null) await _prefs?.setString(_userNameKey, name);
  }

  String? get accessToken => _accessTokenCache;
  String? get refreshToken => _refreshTokenCache;
  String? get userId => _prefs?.getString(_userIdKey);
  String? get userEmail => _prefs?.getString(_userEmailKey);
  String? get userRole => _prefs?.getString(_userRoleKey);
  String? get userName => _prefs?.getString(_userNameKey);

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  bool get isSuperAdmin => userRole == 'super_admin';

  Future<void> clear() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    await Future.wait([
      _secure.delete(key: _accessTokenKey),
      _secure.delete(key: _refreshTokenKey),
      _prefs?.remove(_userIdKey) ?? Future.value(true),
      _prefs?.remove(_userEmailKey) ?? Future.value(true),
      _prefs?.remove(_userRoleKey) ?? Future.value(true),
      _prefs?.remove(_userNameKey) ?? Future.value(true),
    ]);
  }
}
