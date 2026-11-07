import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';
import 'package:stock_management/Model/home_models.dart';
import 'package:stock_management/Model/stock_history_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/order_watcher.dart';
import 'package:stock_management/Services/push_service.dart';
import 'package:stock_management/Services/stock_history_service.dart';
import 'package:stock_management/View/Components/flash_card_dialog.dart';

class HomeController extends GetxController {
  ProfileController get profileController {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    return Get.find<ProfileController>();
  }

  /// Stock data (products, quantities, categories) is shared with the Stock
  /// tab, so Home never loads it twice.
  StockController get _stock {
    if (!Get.isRegistered<StockController>()) {
      Get.put<StockController>(StockController(), permanent: true);
    }
    return Get.find<StockController>();
  }

  final _historyService = StockHistoryService();

  void openProfile() => Get.toNamed(Routes.profile);

  /// Red dot on the bell: true while customer orders wait for review.
  final hasUnreadNotifications = false.obs;
  final pendingOrderCount = 0.obs;

  /// Latest stock movements for the "Recent activity" card.
  final recentActivity = <StockHistoryEntry>[].obs;
  final activityLoading = false.obs;
  final activityError = RxnString();

  /// Donut chart grouping: 'category' | 'product'.
  final chartMode = 'category'.obs;

  /// Everyone's activity with ADJUSTMENT_VIEW, otherwise the person's own (REQUEST_CREATE).
  bool get canSeeActivity => can(Perm.adjustmentView) || can(Perm.requestCreate);

  @override
  void onInit() {
    super.onInit();
    // Staff phone starts receiving push (e.g. new customer orders).
    PushService.instance.start();
    // Stock changes (stock in/out, transfer, adjust) reload the product list;
    // refresh the activity feed right after so both stay in step.
    ever<bool>(_stock.isLoading, (loading) {
      if (!loading) loadActivity();
    });
    loadActivity();
    // The bell follows the order watcher, which also polls while the app is open.
    ever<int>(OrderWatcher.instance.pendingCount, (n) {
      pendingOrderCount.value = n;
      hasUnreadNotifications.value = n > 0;
    });
    pendingOrderCount.value = OrderWatcher.instance.pendingCount.value;
    hasUnreadNotifications.value = pendingOrderCount.value > 0;
    OrderWatcher.instance.start();
  }

  @override
  void onReady() {
    super.onReady();
    // The pop-up card (welcome / news) once the Home route has settled.
    Future.delayed(const Duration(milliseconds: 500), FlashCardDialog.showIfNeeded);
  }

  /// Pull-to-refresh: reloads products and the activity feed.
  Future<void> refreshAll() => _stock.load();

  Future<void> loadActivity() async {
    if (!canSeeActivity) return;
    activityLoading.value = true;
    activityError.value = null;
    try {
      final page = await _historyService.fetch(limit: 5);
      recentActivity.assignAll(page.entries);
    } on ApiException catch (e) {
      activityError.value = e.message;
    } finally {
      activityLoading.value = false;
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }

  // ---- Numbers (computed from the loaded products) ----

  List<StockItemData> get _items => _stock.allItems;

  bool get isLoadingStock => _stock.isLoading.value;

  int get skuCount => _items.length;

  int get totalUnits => _items.fold(0, (sum, i) => sum + i.quantity);

  int get lowCount => _stock.lowCount;

  int get outCount => _stock.outCount;

  int get warehouseCount {
    final codes = <String>{};
    for (final item in _items) {
      for (final s in item.warehouseStocks) {
        if (s.quantity > 0) codes.add(s.warehouseCode);
      }
    }
    return codes.length;
  }

  /// Sum of cost × quantity (per variant when the product has variants).
  double get _stockValue {
    var total = 0.0;
    for (final item in _items) {
      if (item.hasVariants) {
        for (final v in item.variants) {
          total += (v.costPrice ?? 0) * v.quantity;
        }
      } else {
        total += (item.costPrice ?? 0) * item.quantity;
      }
    }
    return total;
  }

  String get totalStockValue => '\$${groupDigits(_stockValue.round())}';

  /// 12345 -> "12,345".
  static String groupDigits(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  List<KpiData> get kpis {
    final loading = isLoadingStock && _items.isEmpty;
    String v(int n) => loading ? '–' : groupDigits(n);
    return [
      KpiData(
        icon: Icons.inventory_2_outlined,
        label: 'home_kpi_products'.tr,
        value: v(skuCount),
        iconColor: AppColors.brand700,
        iconBg: AppColors.brand50,
      ),
      KpiData(
        icon: Icons.layers_outlined,
        label: 'home_kpi_units'.tr,
        value: v(totalUnits),
        iconColor: AppColors.success,
        iconBg: AppColors.successBg,
      ),
      KpiData(
        icon: Icons.warning_amber_rounded,
        label: 'home_kpi_low'.tr,
        value: v(lowCount),
        iconColor: AppColors.warning,
        iconBg: AppColors.warningBg,
      ),
      KpiData(
        icon: Icons.remove_circle_outline_rounded,
        label: 'home_kpi_out'.tr,
        value: v(outCount),
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerBg,
      ),
    ];
  }

  // ---- Donut chart ----

  static const _palette = [
    Color(0xFF6D28D9),
    Color(0xFFA78BFA),
    Color(0xFF3B82F6),
    Color(0xFFF472B6),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
  ];
  static const _othersColor = Color(0xFF9CA3AF);
  static const _maxSlices = 5;

  void setChartMode(String mode) => chartMode.value = mode;

  /// Units in stock grouped by category (or by product), biggest first, with
  /// the tail folded into "Others".
  List<ChartSlice> get chartSlices {
    final totals = <String, double>{};
    for (final item in _items) {
      if (item.quantity <= 0) continue;
      final key = chartMode.value == 'category'
          ? (item.category ?? 'home_no_category'.tr)
          : item.name;
      totals[key] = (totals[key] ?? 0) + item.quantity;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final slices = <ChartSlice>[];
    var others = 0.0;
    for (var i = 0; i < sorted.length; i++) {
      if (i < _maxSlices || sorted.length == _maxSlices + 1 && i == _maxSlices) {
        slices.add(ChartSlice(label: sorted[i].key, value: sorted[i].value, color: _palette[i % _palette.length]));
      } else {
        others += sorted[i].value;
      }
    }
    if (others > 0) {
      slices.add(ChartSlice(label: 'home_chart_others'.tr, value: others, color: _othersColor));
    }
    return slices;
  }

  // ---- Recent activity ----

  String timeAgo(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'time_just_now'.tr;
    if (diff.inMinutes < 60) return 'time_minutes_ago'.trParams({'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return 'time_hours_ago'.trParams({'n': '${diff.inHours}'});
    if (diff.inDays < 7) return 'time_days_ago'.trParams({'n': '${diff.inDays}'});
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year}';
  }

  static String qtyText(double q) =>
      q == q.roundToDouble() ? groupDigits(q.round()) : q.toStringAsFixed(2);

  void openStockHistory() => Get.toNamed(Routes.stockHistory);

  // Demo series for the Reports screen's Stock movement chart (Home no
  // longer shows it; ReportsController reads these).
  final List<double> stockInSeries = const [0.55, 0.68, 0.40, 0.72, 0.15, 0.92, 0.78];
  final List<double> stockOutSeries = const [0.62, 0.58, 0.75, 0.48, 0.65, 0.90, 0.60];
  final List<String> weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final int highlightedWeekdayIndex = 4;

  List<QuickActionData> get quickActions => [
    QuickActionData(icon: Icons.inventory_2_outlined, label: 'qa_manage'.tr, onTap: openManage),
    QuickActionData(icon: Icons.shopping_bag_outlined, label: 'qa_purchase'.tr, onTap: openPurchaseOrders),
    QuickActionData(icon: Icons.swap_horiz_rounded, label: 'qa_transfer'.tr, onTap: openTransfer),
    // Admin adjusts straight away; anyone who can make requests sends one for approval.
    if (can(Perm.stockAdjust) || can(Perm.requestCreate))
      QuickActionData(icon: Icons.tune_rounded, label: 'qa_adjust'.tr, onTap: openAdjust),
  ];

  void openManage() => Get.toNamed(Routes.manage);

  void openPurchaseOrders() => Get.toNamed(Routes.purchaseOrders);

  void openTransfer() => Get.toNamed(Routes.transfer);

  void openAdjust() => Get.toNamed(Routes.adjust);

  void stockIn() => Get.toNamed(Routes.stockIn, arguments: StockMovementDirection.stockIn);

  void stockOut() => Get.toNamed(Routes.stockOut, arguments: StockMovementDirection.stockOut);

  Future<void> openNotifications() async {
    await Get.toNamed(Routes.notifications);
    refreshNotifications();
  }

  /// Counts the orders waiting for review. A failure (offline, no access)
  /// just leaves the dot off — the Notifications screen shows the reason.
  Future<void> refreshNotifications() => OrderWatcher.instance.check();
}
