import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'admin_access_token';
  static const _refreshTokenKey = 'admin_refresh_token';
  static const _userIdKey = 'admin_user_id';
  static const _userEmailKey = 'admin_user_email';
  static const _userRoleKey = 'admin_user_role';
  static const _userNameKey = 'admin_user_name';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs?.setString(_accessTokenKey, accessToken);
    await _prefs?.setString(_refreshTokenKey, refreshToken);
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

  String? get accessToken => _prefs?.getString(_accessTokenKey);
  String? get refreshToken => _prefs?.getString(_refreshTokenKey);
  String? get userId => _prefs?.getString(_userIdKey);
  String? get userEmail => _prefs?.getString(_userEmailKey);
  String? get userRole => _prefs?.getString(_userRoleKey);
  String? get userName => _prefs?.getString(_userNameKey);

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  bool get isSuperAdmin => userRole == 'super_admin';

  Future<void> clear() async {
    await _prefs?.remove(_accessTokenKey);
    await _prefs?.remove(_refreshTokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_userEmailKey);
    await _prefs?.remove(_userRoleKey);
    await _prefs?.remove(_userNameKey);
  }
}
