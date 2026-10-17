/// Signed-in user's basic info shown at the top of the More screen.
class MoreProfileData {
  const MoreProfileData({
    required this.name,
    required this.role,
    required this.email,
  });

  final String name;
  final String role;
  final String email;

  /// Up to two initials for the avatar tile, e.g. "Visal Khem" -> "VK".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0]).take(2);
    return letters.join().toUpperCase();
  }
}
