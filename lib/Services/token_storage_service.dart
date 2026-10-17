import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in session to disk via [SharedPreferences].
///
/// Any Service that needs to read, save, or clear the session (the access
/// token above all) should go through this instead of touching
/// SharedPreferences directly, so the storage keys stay in exactly one
/// place.
class TokenStorageService {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _mustChangePasswordKey = 'auth_must_change_password';
  static const _staffIdKey = 'auth_staff_id';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required bool mustChangePassword,
    required String staffId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setBool(_mustChangePasswordKey, mustChangePassword);
    await prefs.setString(_staffIdKey, staffId);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getStaffId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_staffIdKey);
  }

  Future<bool> getMustChangePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mustChangePasswordKey) ?? false;
  }

  Future<void> setMustChangePassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mustChangePasswordKey, value);
  }

  /// Whether a previous login is still stored (does not check that the
  /// token hasn't expired server-side — a 401 from [ApiClient] is what
  /// ultimately catches that).
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_mustChangePasswordKey);
    await prefs.remove(_staffIdKey);
  }
}
