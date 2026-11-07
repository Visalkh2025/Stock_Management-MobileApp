/// Minimal shape of the `user` object `/auth/login` returns (itself the response of the backend's `UsersService.getMe`).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    this.permissions = const [],
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;

  /// Permission codes from the backend (e.g. `USER_VIEW`). Drives which
  /// buttons/menus the UI shows — the API still enforces them.
  final List<String> permissions;
  final String? phone;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    return AuthUser(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? '',
      firstName: profile['firstName']?.toString() ?? '',
      lastName: profile['lastName']?.toString() ?? '',
      email: profile['email']?.toString() ?? '',
      roles: (json['roles'] as List?)?.map((role) => role.toString()).toList() ?? const [],
      permissions: (json['permissions'] as List?)?.map((p) => p.toString()).toList() ?? const [],
      phone: profile['phone']?.toString(),
      avatarUrl: profile['avatar']?.toString(),
    );
  }
}

/// Response of `POST /auth/login`.
class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.mustChangePassword,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;
  final AuthUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
