import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/home_controller.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/request_models.dart';

/// Reached from More > Reports. Read-only rollup over data the rest of the
/// app already tracks — no separate reports API, just another view of
/// Home/Stock/Requests' existing controllers (same guarded-singleton
/// pattern as everywhere else in the app).
class ReportsController extends GetxController {
  HomeController get _home {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }
    return Get.find<HomeController>();
  }

  StockController get _stock {
    if (!Get.isRegistered<StockController>()) {
      Get.put(StockController(), permanent: true);
    }
    return Get.find<StockController>();
  }

  RequestController get _requests {
    if (!Get.isRegistered<RequestController>()) {
      Get.put(RequestController(), permanent: true);
    }
    return Get.find<RequestController>();
  }

  String get totalStockValue => _home.totalStockValue.value;
  int get skuCount => _home.skuCount;
  int get lowStockCount => _stock.lowCount;
  int get outOfStockCount => _stock.outCount;

  int get pendingCount => _requests.countFor(RequestStatus.pending);
  int get approvedCount => _requests.countFor(RequestStatus.approved);
  int get rejectedCount => _requests.countFor(RequestStatus.rejected);

  List<double> get stockInSeries => _home.stockInSeries;
  List<double> get stockOutSeries => _home.stockOutSeries;
  List<String> get weekdayLabels => _home.weekdayLabels;
  int get highlightedWeekdayIndex => _home.highlightedWeekdayIndex;

  // Fixed display order for the breakdown list below the chart, rather
  // than however the underlying map happens to iterate.
  static const _typeOrder = [
    'Stock In',
    'Stock Out',
    'Stock Transfer',
    'Adjustment',
    'Purchase Order',
    'Product Create',
  ];

  /// Request counts grouped by type — the "breakdown" list under the
  /// chart (Dashboard/KPI pattern: stat cards + one chart + one list).
  List<MapEntry<String, int>> get requestsByType {
    final counts = <String, int>{};
    for (final item in _requests.allItems) {
      counts[item.typeLabel] = (counts[item.typeLabel] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final ai = _typeOrder.indexOf(a.key);
        final bi = _typeOrder.indexOf(b.key);
        return (ai == -1 ? _typeOrder.length : ai).compareTo(bi == -1 ? _typeOrder.length : bi);
      });
    return entries;
  }

  int get totalRequests => _requests.totalCount;

  void exportPdf() => _export('PDF');
  void exportExcel() => _export('Excel');

  // No backend/report-generation wired up yet — same "demo action,
  // confirm with a snackbar" shape as ProfileController.save.
  void _export(String format) {
    Get.snackbar(
      'export_started_title'.tr,
      'export_started_message'.trParams({'format': format}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
