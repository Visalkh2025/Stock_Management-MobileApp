import 'dart:io';

/// The signed-in user's editable profile. A single [ProfileController]
/// (see Controller/profile_controller.dart) owns one of these and is
/// shared app-wide, so an edit made on the Profile screen is immediately
/// reflected everywhere else it's shown — the More screen's profile row,
/// the Home header's avatar.
class UserProfileData {
  const UserProfileData({
    required this.name,
    required this.role,
    required this.email,
    this.phone,
    this.avatarImage,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String email;
  final String? phone;
  final File? avatarImage;

  /// The signed-in user's avatar as a URL from the backend (currently an
  /// auto-generated ui-avatars.com image — see UsersService.generateAvatar
  /// server-side). Only used when [avatarImage] (a freshly-picked local
  /// file, set while editing) isn't set.
  final String? avatarUrl;

  /// Up to two initials for the avatar tile, e.g. "Visal Khem" -> "VK".
  /// Used whenever [avatarImage] isn't set.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0]).take(2);
    return letters.join().toUpperCase();
  }

  UserProfileData copyWith({
    String? name,
    String? role,
    String? email,
    String? phone,
    File? avatarImage,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfileData(
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarImage: clearAvatar ? null : (avatarImage ?? this.avatarImage),
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}
