import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/profile_models.dart';

/// The signed-in user's avatar, wherever it's shown — the Profile screen,
/// the More row, the Home header. One widget handles all three states so
/// none of those screens re-implement the same ternary:
///  - a freshly-picked local file (mid-edit on the Profile screen), else
///  - a network URL from the backend (cached via [CachedNetworkImage] —
///    not re-downloaded every time the widget rebuilds with the same
///    URL), else
///  - initials, also used as the network image's placeholder/error state.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.profile,
    required this.size,
    this.borderRadius,
    this.backgroundColor,
    this.gradientColors,
    this.initialsColor,
    this.initialsFontSize,
  });

  final UserProfileData profile;
  final double size;

  /// Defaults to a full circle. Pass e.g. `BorderRadius.circular(14)` for
  /// a rounded-square tile (More row, Home header).
  final BorderRadius? borderRadius;

  /// Solid background for the initials fallback (e.g. the More row's
  /// white chip). Takes priority over [gradientColors] when set.
  final Color? backgroundColor;

  /// Gradient background for the initials fallback. Defaults to the
  /// brand gradient used across the app.
  final List<Color>? gradientColors;

  final Color? initialsColor;
  final double? initialsFontSize;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    Widget child;
    if (profile.avatarImage != null) {
      child = Image.file(profile.avatarImage!, width: size, height: size, fit: BoxFit.cover);
    } else if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: profile.avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) => _initials(),
        errorWidget: (_, _, _) => _initials(),
      );
    } else {
      child = _initials();
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _initials() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: backgroundColor == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? const [AppColors.brand400, Color(0xFF8B5CF6)],
              )
            : null,
      ),
      child: Text(
        profile.initials,
        style: TextStyle(
          fontSize: initialsFontSize ?? size * 0.34,
          fontWeight: FontWeight.w700,
          color: initialsColor ?? Colors.white,
        ),
      ),
    );
  }
}
