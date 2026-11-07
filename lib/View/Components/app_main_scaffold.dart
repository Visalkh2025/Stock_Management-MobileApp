import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/nav_badge_controller.dart';
import 'package:stock_management/View/Components/app_bottom_nav_bar.dart';

/// Which of the 4 bottom-nav destinations a main screen represents.
enum AppNavTab { home, stock, requests, more }

/// The Scaffold shell shared by every main (post-login) screen — Home, Stock, Requests, More.
class AppMainScaffold extends StatefulWidget {
  const AppMainScaffold({
    super.key,
    required this.tab,
    required this.body,
    this.backgroundColor,
  });

  /// Which tab this screen is — decides which nav item is highlighted and
  /// is used as the "already here" guard when a tab is tapped.
  final AppNavTab tab;

  final Widget body;
  final Color? backgroundColor;

  @override
  State<AppMainScaffold> createState() => _AppMainScaffoldState();
}

class _AppMainScaffoldState extends State<AppMainScaffold> {
  static const List<String> _tabRoutes = [Routes.home, Routes.stock, Routes.requests, Routes.more];

  // Nav bar + center button hide while scrolling further into the content and reappear once the user scrolls back toward the top — same convention as most feeds/lists.
  bool _navVisible = true;

  late final NavBadgeController _badges;

  @override
  void initState() {
    super.initState();
    _badges = Get.isRegistered<NavBadgeController>()
        ? Get.find<NavBadgeController>()
        : Get.put<NavBadgeController>(NavBadgeController(), permanent: true);
    // The tab being shown clears its own badge; new items later show it again.
    _badges.setActiveTab(widget.tab).then((_) {
      if (widget.tab == AppNavTab.requests) _badges.markRequestsSeen();
      if (widget.tab == AppNavTab.stock) _badges.markStockSeen();
    });
  }

  void _onTabTap(int index) {
    if (index == widget.tab.index) return;
    Get.offNamed(_tabRoutes[index]);
  }

  bool _handleScrollNotification(UserScrollNotification notification) {
    // Only the outermost scrollable's notifications should drive this (a
    // nested horizontal list, e.g. Home's insight cards, would otherwise
    // fight it) — depth 0 is exactly that outermost one.
    if (notification.depth != 0) return false;
    final hide = notification.direction == ScrollDirection.reverse;
    final show = notification.direction == ScrollDirection.forward;
    if (hide && _navVisible) {
      setState(() => _navVisible = false);
    } else if (show && !_navVisible) {
      setState(() => _navVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body content scrolls underneath the translucent nav bar instead of
      // stopping above it, so there's actually something visible through it.
      extendBody: true,
      backgroundColor: widget.backgroundColor ?? (AppColors.isDark ? AppColors.pageBg : const Color(0xFFF6F5F9)),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.body,
      ),
      bottomNavigationBar: IgnorePointer(
        ignoring: !_navVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          offset: _navVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: _navVisible ? 1 : 0,
            child: Obx(
              () => AppBottomNavBar(
                currentIndex: widget.tab.index,
                onTap: _onTabTap,
                items: [
                  AppBottomNavItem(icon: Icons.home_outlined, label: 'nav_home'.tr),
                  AppBottomNavItem(icon: Icons.inventory_2_outlined, label: 'nav_stock'.tr, badgeCount: _badges.stockBadge.value),
                  AppBottomNavItem(icon: Icons.assignment_outlined, label: 'nav_requests'.tr, badgeCount: _badges.requestsBadge.value),
                  AppBottomNavItem(icon: Icons.more_horiz_rounded, label: 'nav_more'.tr),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_navVisible,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          scale: _navVisible ? 1 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: _navVisible ? 1 : 0,
            child: AppBottomNavCenterButton(onTap: () => Get.toNamed(Routes.scanQr)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
