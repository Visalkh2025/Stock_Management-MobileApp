import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label, this.badgeCount});

  final IconData icon;
  final String label;
  final int? badgeCount;
}

/// App-wide bottom navigation bar: 2 items, an empty center slot (for the
/// raised [AppBottomNavCenterButton], docked separately — see that widget's
/// doc comment for why), then 2 more items. The active item sits on a pill
/// background. Reused across every main (post-login) screen — Home, Stock,
/// Requests, More.
///
/// Renders as a floating pill — inset from the screen edges with rounded
/// corners and a soft shadow — rather than a bar glued flush to the bottom
/// edge. The outer [Padding] carries no top inset, so the pill's own top
/// edge is still the top of this widget's layout box; that's what keeps
/// [AppBottomNavCenterButton] (docked via `centerDocked`) sitting flush on
/// the pill instead of floating in the gap below it.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Exactly 4 items — 2 rendered left of the center slot, 2 right.
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Width reserved in the middle of the bar so the docked center button
  /// (see [AppBottomNavCenterButton]) has breathing room and the side items
  /// don't crowd it. Purely a layout spacer — no button lives here.
  static const double _centerSlotWidth = 64;

  static const double _barHeight = 60;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Half the safe-area inset instead of the full amount — sits lower than
    // flush, but still leaves a sliver of clearance above the home
    // indicator / gesture bar rather than sitting flush on top of it.
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset * 0.5),
      // Semi-transparent white, no blur — body content behind stays sharp
      // and visible through the bar, just tinted white, instead of either
      // fully hidden (opaque) or frosted (blurred).
      child: Container(
        height: _barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            _navItem(items[0], 0),
            _navItem(items[1], 1),
            const SizedBox(width: _centerSlotWidth),
            _navItem(items[2], 2),
            _navItem(items[3], 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(AppBottomNavItem item, int index) {
    final isActive = index == currentIndex;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: isActive ? 44 : 34,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.brand600, AppColors.brand700],
                            )
                          : null,
                      color: isActive ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.brand600.withValues(alpha: 0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      size: 18,
                      // Icon sits on the purple gradient pill when active
                      // (white reads fine there); inactive icons sit
                      // straight on the white glass, so they need a dark tone.
                      color: isActive ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      // Unlike the icon, the label always sits directly on
                      // the white glass (never on the pill) — so it needs a
                      // dark tone in both states.
                      color: isActive ? AppColors.brand700 : AppColors.textTertiary,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
              if ((item.badgeCount ?? 0) > 0)
                Positioned(
                  top: 0,
                  right: 14,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 15),
                    height: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBg, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised purple circle docked over the bottom nav bar's top edge.
/// Pass it as `Scaffold.floatingActionButton` alongside
/// `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`
/// — Flutter positions it centered, straddling the bottom bar's top edge.
///
/// This used to live inside [AppBottomNavBar] itself, floated above the bar
/// with an `OverflowBox` + `Transform.translate`. That made it *paint*
/// outside the bar's own layout box, but Flutter's hit-testing rejects a
/// touch outside a widget's own bounds before it ever reaches a child
/// painted past that box — so most of the visible circle was silently
/// untappable (only a thin sliver near its bottom edge actually was).
/// Docking it as the Scaffold's real floating action button uses Flutter's
/// own, correctly hit-tested mechanism for exactly this "half over the
/// bottom bar" look instead.
class AppBottomNavCenterButton extends StatelessWidget {
  const AppBottomNavCenterButton({
    super.key,
    required this.onTap,
    this.icon,
    this.iconAsset = 'assets/icons/barcode-scanner.png',
    this.size = 60,
    this.verticalOffset = 2,
  });

  final VoidCallback onTap;

  /// Overrides [iconAsset] with a Material icon when set.
  final IconData? icon;

  /// Image asset drawn in the button (a white/transparent PNG reads best
  /// against the button's purple fill). Ignored when [icon] is set.
  final String iconAsset;

  /// Diameter of the button.
  final double size;

  /// Nudges the button up/down from `centerDocked`'s default position
  /// (half over the bar's top edge). Negative raises it further above the
  /// bar, positive lowers it back toward/into the bar.
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brand700, AppColors.brand600],
              ),
              border: Border.all(color: AppColors.cardBg, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand600.withValues(alpha: 0.38),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: size * 0.36, color: Colors.white)
                : Image.asset(iconAsset, width: size * 0.32, height: size * 0.32),
          ),
        ),
      ),
    );
  }
}
