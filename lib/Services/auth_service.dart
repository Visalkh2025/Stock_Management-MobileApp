import 'dart:io';

import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/auth_models.dart';
import 'package:stock_management/Services/api_client.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/image_upload.dart';
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

  /// Calls `POST /auth/change-password` with the access token saved at sign-in (works for both the must-change-password flow right after login and any future "change my password" screen).
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

  /// Called once at app start.
  Future<AuthUser?> restoreSession() async {
    if (!await _tokenStorage.hasSession()) return null;
    // A temporary password still has to be replaced: needs the login screen.
    if (await _tokenStorage.getMustChangePassword()) {
      await _tokenStorage.clear();
      return null;
    }
    try {
      return await _fetchMe();
    } on ApiException catch (e) {
      // Server unreachable etc.: keep the tokens, just show login this time.
      if (!e.isUnauthorized) return null;
      if (!await _tryRefresh()) {
        await _tokenStorage.clear();
        return null;
      }
      try {
        return await _fetchMe();
      } on ApiException {
        return null;
      }
    }
  }

  /// `PATCH /users/me`: the signed-in person changes their own name, email
  /// and phone. Returns the updated user.
  Future<AuthUser> updateProfile({required String name, required String email, required String phone}) async {
    final json = await _apiClient.patch(ApiConfig.me, body: {'fullName': name, 'email': email, 'phone': phone});
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /users/me/avatar`: replaces the profile photo. Returns the updated user.
  Future<AuthUser> uploadAvatar(File image) async {
    final file = await imageMultipart('image', image);
    final json = await _apiClient.postMultipart('${ApiConfig.me}/avatar', fields: const {}, files: [file]);
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthUser> _fetchMe() async {
    final json = await _apiClient.get(ApiConfig.me);
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final json = await _apiClient.post(
        ApiConfig.refreshToken,
        auth: false,
        body: {'refreshToken': refresh},
      ) as Map<String, dynamic>;
      final mustChange = json['mustChangePassword'] == true;
      await _tokenStorage.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        mustChangePassword: mustChange,
        staffId: await _tokenStorage.getStaffId() ?? '',
      );
      return !mustChange;
    } on ApiException {
      return false;
    }
  }


  /// Forgot password, step 1: emails a 6-digit code to the account's address.
  Future<void> forgotPassword(String staffId) async {
    await _apiClient.post(ApiConfig.forgotPassword, auth: false, body: {'staffId': staffId});
  }

  /// Step 2: checks the code. Returns the one-time reset token.
  Future<String> verifyResetOtp({required String staffId, required String otp}) async {
    final json = await _apiClient.post(
      ApiConfig.verifyResetOtp,
      auth: false,
      body: {'staffId': staffId, 'otp': otp},
    );
    return (json as Map<String, dynamic>)['resetToken'].toString();
  }

  /// Step 3: sets the new password (the server signs the user out everywhere).
  Future<void> resetPassword({required String resetToken, required String newPassword}) async {
    await _apiClient.post(
      ApiConfig.resetPassword,
      auth: false,
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<bool> isSignedIn() => _tokenStorage.hasSession();
}
