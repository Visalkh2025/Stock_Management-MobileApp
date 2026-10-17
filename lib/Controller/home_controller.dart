import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';
import 'package:stock_management/Model/home_models.dart';

class HomeController extends GetxController {
  ProfileController get profileController {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    return Get.find<ProfileController>();
  }

  void openProfile() => Get.toNamed(Routes.profile);

  final totalStockValue = '\$284,500'.obs;
  final skuCount = 312;
  final warehouseCount = 4;
  final hasUnreadNotifications = true.obs;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }

  List<InsightCardData> get insightCards => [
    InsightCardData(
      icon: Icons.warning_amber_rounded,
      title: 'insight_reorder_needed'.tr,
      subtitle: 'insight_reorder_needed_sub'.trParams({'count': '18'}),
      iconColor: AppColors.warning,
      iconBg: AppColors.cardBg,
      cardColor: AppColors.warningBg,
      subtitleColor: const Color(0xFF92400E),
    ),
    InsightCardData(
      icon: Icons.arrow_upward_rounded,
      title: 'insight_units_in'.tr,
      subtitle: 'insight_units_sub'.trParams({'count': '740'}),
      iconColor: AppColors.success,
      iconBg: AppColors.successBg,
    ),
    InsightCardData(
      icon: Icons.arrow_downward_rounded,
      title: 'insight_units_out'.tr,
      subtitle: 'insight_units_sub'.trParams({'count': '590'}),
      iconColor: AppColors.brand700,
      iconBg: AppColors.brand50,
    ),
    InsightCardData(
      icon: Icons.swap_horiz_rounded,
      title: 'insight_active_transfers'.tr,
      subtitle: 'insight_active_transfers_sub'.trParams({'count': '2'}),
      iconColor: AppColors.brand700,
      iconBg: AppColors.brand50,
    ),
  ];

  List<QuickActionData> get quickActions => [
    QuickActionData(icon: Icons.inventory_2_outlined, label: 'qa_manage'.tr, onTap: openManage),
    QuickActionData(icon: Icons.shopping_bag_outlined, label: 'qa_purchase'.tr, onTap: openPurchaseOrders),
    QuickActionData(icon: Icons.swap_horiz_rounded, label: 'qa_transfer'.tr, onTap: openTransfer),
    if (can(Perm.stockAdjust)) QuickActionData(icon: Icons.tune_rounded, label: 'qa_adjust'.tr, onTap: openAdjust),
  ];

  final List<double> stockInSeries = const [0.55, 0.68, 0.40, 0.72, 0.15, 0.92, 0.78];
  final List<double> stockOutSeries = const [0.62, 0.58, 0.75, 0.48, 0.65, 0.90, 0.60];
  final List<String> weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final int highlightedWeekdayIndex = 4; 

  final List<TransactionData> recentTransactions = const [
    TransactionData(
      icon: Icons.add_rounded,
      title: 'Received USB-C Cable',
      subtitle: 'Warehouse A • 10 min ago',
      amountLabel: '+120',
      tagLabel: 'Received',
      kind: TransactionKind.received,
    ),
    TransactionData(
      icon: Icons.swap_horiz_rounded,
      title: 'Transferred HDMI Cable',
      subtitle: 'A → B • 32 min ago',
      amountLabel: '40',
      tagLabel: 'Transfer',
      kind: TransactionKind.transfer,
    ),
    TransactionData(
      icon: Icons.warning_amber_rounded,
      title: 'Low stock: A4 Paper Ream',
      subtitle: 'Warehouse B • 1 hr ago',
      amountLabel: 'Low',
      tagLabel: 'Alert',
      kind: TransactionKind.alert,
    ),
  ];

  void openManage() => Get.toNamed(Routes.manage);

  void openPurchaseOrders() => Get.toNamed(Routes.purchaseOrders);

  void openTransfer() => Get.toNamed(Routes.transfer);

  void openAdjust() => Get.toNamed(Routes.adjust);

  void stockIn() => Get.toNamed(Routes.stockIn, arguments: StockMovementDirection.stockIn);

  void stockOut() => Get.toNamed(Routes.stockOut, arguments: StockMovementDirection.stockOut);

  void openNotifications() {}
}
