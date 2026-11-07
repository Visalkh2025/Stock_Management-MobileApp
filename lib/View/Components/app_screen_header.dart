import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({super.key, required this.children});

  final List<Widget> children;

  /// The two gradient stops — the single knob for the whole family's tone.
  static const Color _gradientTop = AppColors.brand800;
  static const Color _gradientBottom = AppColors.brand600;

  static const BorderRadius _radius = BorderRadius.only(
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(32),
  );

  // ---- Tokens for content rendered on top of the header ----
  /// Primary text / icon color on the header.
  static const Color onHeader = Colors.white;

  /// Secondary text / icon color on the header (white @ ~70%).
  static const Color onHeaderMuted = Color(0xB3FFFFFF);

  /// Fill for pills / fields / buttons sitting on the header (white @ ~14%).
  static const Color onHeaderSurface = Color(0x24FFFFFF);

  /// Hairline for those surfaces (white @ ~24%).
  static const Color onHeaderSurfaceBorder = Color(0x3DFFFFFF);

  @override
  Widget build(BuildContext context) {
    final topInset = _topInset(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark header → light status-bar icons.
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: DecoratedBox(
        // Purple glow shadow, outside the clip so it isn't trimmed.
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand900.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            children: [
              // Base hero gradient — same vector as the Home header.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment(0.9, 1.1),
                      colors: [_gradientTop, _gradientBottom],
                    ),
                  ),
                ),
              ),
              // Soft light orb bleeding off the top-right, fading to nothing.
              Positioned(
                top: -80,
                right: -60,
                child: _orb(230, AppColors.brand400.withValues(alpha: 0.32)),
              ),
              // A second, tighter highlight lower down for a layered feel.
              Positioned(
                top: 24,
                right: 44,
                child: _orb(120, Colors.white.withValues(alpha: 0.10)),
              ),
              // Screen content.
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20 + topInset, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Height of the status bar / notch / Dynamic Island to clear.
  ///
  /// `padding.top` drops to 0 when an ancestor (a SafeArea, an AppBar) has
  /// already consumed it, which pushed the title up under the status bar on
  /// some screens. `viewPadding.top` is the real, unconsumed inset, so the
  /// larger of the two is used, with a floor for devices that report none.
  static double _topInset(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.padding.top > media.viewPadding.top ? media.padding.top : media.viewPadding.top;
    return inset < 24 ? 24 : inset;
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
