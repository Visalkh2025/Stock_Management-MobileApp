import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/home_controller.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';
import 'package:stock_management/View/Components/quick_action_tile.dart';
import 'package:stock_management/View/Components/breakdown_card.dart';
import 'package:stock_management/View/Components/insight_card.dart';
import 'package:stock_management/View/Components/transaction_row.dart';
import 'package:stock_management/View/Components/user_avatar.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AppMainScaffold(
      tab: AppNavTab.home,
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        edgeOffset: topInset + 80,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HomeHeaderDelegate(
              topInset: topInset,
              // Full purple header height, measured below the status bar.
              expandedHeight: 270,
              collapsedHeight: 80,
              child: _headerContent(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, MediaQuery.paddingOf(context).bottom * 0.5 + 76),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kpiGrid,
                  const SizedBox(height: 18),
                  _quickActions,
                  const SizedBox(height: 18),
                  _breakdownCard,
                  const SizedBox(height: 16),
                  if (controller.canSeeActivity) _recentActivityCard,
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// The full, expanded header. Rounded bottom corners + drop shadow are added
  /// by [_HomeHeaderDelegate] so they follow the header as it collapses; this
  /// only paints the gradient fill and lays out the content.
  Widget _headerContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22, 22 + MediaQuery.paddingOf(context).top, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.9, 1.1),
          colors: [AppColors.brand900, AppColors.brand800],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: controller.openProfile,
                  borderRadius: BorderRadius.circular(14),
                  child: Obx(() {
                    final profile = controller.profileController.profile.value;
                    return UserAvatar(
                      profile: profile,
                      size: 42,
                      borderRadius: BorderRadius.circular(14),
                      initialsColor: const Color(0xFFF3F2FA),
                      initialsFontSize: 13,
                    );
                  }),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      controller.greeting,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand300),
                    ),
                    Obx(
                      () => Text(
                        controller.profileController.profile.value.name,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              _notificationButton,
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'total_stock_value'.tr,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand300),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.visibility_outlined, size: 14, color: AppColors.brand300),
                ],
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  controller.totalStockValue,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  'skus_warehouses'.trParams({
                    'sku': '${controller.skuCount}',
                    'wh': '${controller.warehouseCount}',
                  }),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _headerActionButton(
                  icon: Icons.call_made_rounded,
                  label: 'stock_in'.tr,
                  onTap: controller.stockIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _headerActionButton(
                  icon: Icons.call_received_rounded,
                  label: 'stock_out'.tr,
                  onTap: controller.stockOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget get _notificationButton {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.openNotifications,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_outlined, size: 18, color: Colors.white),
              Obx(
                () => controller.hasUnreadNotifications.value
                    ? const Positioned(
                        top: 8,
                        right: 8,
                        child: _NotificationDot(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _kpiGrid {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final kpis = controller.kpis;
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: KpiCard(data: kpis[0])),
                const SizedBox(width: 10),
                Expanded(child: KpiCard(data: kpis[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: KpiCard(data: kpis[2])),
                const SizedBox(width: 10),
                Expanded(child: KpiCard(data: kpis[3])),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget get _quickActions {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_actions'.tr,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) => QuickActionTile(data: controller.quickActions[index]),
          ),
        ],
      ),
    );
  }

  Widget get _breakdownCard {
    return Obx(
      () => BreakdownCard(
        slices: controller.chartSlices,
        totalLabel: HomeController.groupDigits(controller.totalUnits),
        mode: controller.chartMode.value,
        onModeChanged: controller.setChartMode,
      ),
    );
  }

  Widget get _recentActivityCard {
    return Obx(
      () => RecentActivityCard(
        entries: controller.recentActivity.toList(),
        isLoading: controller.activityLoading.value,
        error: controller.activityError.value,
        timeAgo: controller.timeAgo,
        onSeeAll: controller.openStockHistory,
      ),
    );
  }
}

/// Pinned header for [HomeScreen]. At rest it shows the whole purple header;
/// as the list scrolls up it crops the header from the bottom so only the
/// profile row (avatar + the greeting + user name + notification button) stays.
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topInset,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.child,
  });

  /// Status-bar / notch inset, added to both extents so the gradient always
  /// bleeds behind it.
  final double topInset;

  /// Header height below the status bar when fully expanded / collapsed.
  final double expandedHeight;
  final double collapsedHeight;

  /// The full header content ([HomeScreen._headerContent]).
  final Widget child;

  @override
  double get maxExtent => topInset + expandedHeight;

  @override
  double get minExtent => topInset + collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand900.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        // Lay the header out at its full height, pinned to the top, and let
        // ClipRRect trim whatever falls past the current (shrinking) extent.
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: maxExtent,
          maxHeight: maxExtent,
          child: SizedBox(height: maxExtent, child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return topInset != oldDelegate.topInset ||
        expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        child != oldDelegate.child;
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.danger,
        border: Border.all(color: AppColors.brand900, width: 1.5),
      ),
    );
  }
}
