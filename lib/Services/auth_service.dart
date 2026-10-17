import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/auth_models.dart';
import 'package:stock_management/Services/api_client.dart';
import 'package:stock_management/Services/token_storage_service.dart';

/// Everything auth-related: sign in, sign out, and the stored session.
/// [LoginController] (and later, any screen that needs to know who's
/// signed in) goes through this rather than calling [ApiClient] directly.
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorageService? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorageService();

  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  /// Calls `POST /auth/login` and, on success, persists the session so the
  /// rest of the app (and [ApiClient]) can find it again.
  Future<LoginResult> login({required String staffId, required String password}) async {
    final json = await _apiClient.post(
      ApiConfig.login,
      auth: false,
      body: {'staffId': staffId, 'password': password},
    );

    final result = LoginResult.fromJson(json as Map<String, dynamic>);

    await _tokenStorage.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      mustChangePassword: result.mustChangePassword,
      staffId: result.user.staffId,
    );

    return result;
  }

  /// Calls `POST /auth/change-password` with the access token saved at
  /// sign-in (works for both the must-change-password flow right after
  /// login and any future "change my password" screen). On success, marks
  /// the local session as no longer needing a password change so the next
  /// login goes straight to Home.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConfig.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );

    await _tokenStorage.setMustChangePassword(false);
  }
  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<bool> isSignedIn() => _tokenStorage.hasSession();
}
