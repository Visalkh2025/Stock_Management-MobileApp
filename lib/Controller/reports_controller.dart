import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/home_controller.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/Model/stock_history_models.dart';
import 'package:stock_management/Services/stock_history_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';

/// Reached from More > Reports.
class ReportsController extends GetxController {
  final StockHistoryService _history = StockHistoryService();

  /// Period of the chart and the request breakdown (never "all dates").
  final dateFilter = const DateFilter(DatePreset.last7).obs;

  final stockInSeries = <double>[].obs;
  final stockOutSeries = <double>[].obs;
  final chartLabels = <String>[].obs;
  final chartLoading = false.obs;

  /// Total quantity moved in / out in the period (0 = nothing to draw).
  final totalIn = 0.0.obs;
  final totalOut = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadChart();
  }

  void setDateFilter(DateFilter value) {
    dateFilter.value = value;
    loadChart();
  }

  /// The chosen range as concrete dates (start inclusive, end exclusive).
  (DateTime, DateTime) get _range {
    final filter = dateFilter.value;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final start = filter.from ?? DateTime(now.year, now.month, now.day - 6);
    final end = filter.to ?? tomorrow;
    return (start, end.isAfter(start) ? end : tomorrow);
  }

  Future<void> loadChart() async {
    final filter = dateFilter.value;
    final (start, end) = _range;
    chartLoading.value = true;
    try {
      final entries = <StockHistoryEntry>[];
      for (var page = 1; page <= 5; page++) {
        final result = await _history.fetch(
          from: start.toUtc().toIso8601String(),
          to: end.toUtc().toIso8601String(),
          page: page,
          limit: 100,
        );
        entries.addAll(result.entries);
        if (!result.hasNextPage) break;
      }
      // The user may have changed the range while this was loading.
      if (!identical(filter, dateFilter.value)) return;
      _bucket(entries, start, end);
    } catch (_) {
      _bucket(const [], start, end);
    } finally {
      if (identical(filter, dateFilter.value)) chartLoading.value = false;
    }
  }

  /// Groups IN / OUT movements into at most 7 buckets: 4-hour slices for one
  /// day, one bucket per day up to a week, otherwise equal runs of days.
  void _bucket(List<StockHistoryEntry> entries, DateTime start, DateTime end) {
    final days = end.difference(start).inHours / 24;
    final oneDay = days <= 1.01;
    final stepDays = oneDay ? 0 : (days / 7).ceil();
    final count = oneDay ? 6 : (days / stepDays).ceil();

    DateTime bucketStart(int i) =>
        oneDay ? start.add(Duration(hours: 4 * i)) : DateTime(start.year, start.month, start.day + stepDays * i);

    final ins = List<double>.filled(count, 0);
    final outs = List<double>.filled(count, 0);
    for (final e in entries) {
      final at = e.at;
      if (at == null || (e.kind != 'IN' && e.kind != 'OUT')) continue;
      var index = count - 1;
      for (var i = 0; i < count; i++) {
        if (i == count - 1 || at.isBefore(bucketStart(i + 1))) {
          index = i;
          break;
        }
      }
      if (e.kind == 'IN') {
        ins[index] += e.quantity.abs();
      } else {
        outs[index] += e.quantity.abs();
      }
    }

    String two(int n) => n.toString().padLeft(2, '0');
    chartLabels.assignAll([
      for (var i = 0; i < count; i++)
        oneDay ? '${two(bucketStart(i).hour)}:00' : '${bucketStart(i).day}/${bucketStart(i).month}',
    ]);

    var peak = 0.0;
    for (var i = 0; i < count; i++) {
      if (ins[i] > peak) peak = ins[i];
      if (outs[i] > peak) peak = outs[i];
    }
    totalIn.value = ins.fold(0.0, (a, b) => a + b);
    totalOut.value = outs.fold(0.0, (a, b) => a + b);
    stockInSeries.assignAll(peak == 0 ? ins : [for (final v in ins) v / peak]);
    stockOutSeries.assignAll(peak == 0 ? outs : [for (final v in outs) v / peak]);
  }

  bool get chartEmpty => totalIn.value == 0 && totalOut.value == 0;

  /// The bucket that holds right now (the last one).
  int get highlightedIndex => chartLabels.length - 1;

  bool _inPeriod(RequestItemData item) {
    final at = item.createdAt;
    return at == null || dateFilter.value.contains(at);
  }

  List<RequestItemData> get _periodRequests => _requests.allItems.where(_inPeriod).toList();

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

  String get totalStockValue => _home.totalStockValue;
  int get skuCount => _home.skuCount;
  int get lowStockCount => _stock.lowCount;
  int get outOfStockCount => _stock.outCount;

  int _countStatus(RequestStatus status) => _periodRequests.where((item) => item.status == status).length;

  int get pendingCount => _countStatus(RequestStatus.pending);
  int get approvedCount => _countStatus(RequestStatus.approved);
  int get rejectedCount => _countStatus(RequestStatus.rejected);

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
    for (final item in _periodRequests) {
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

  int get totalRequests => _periodRequests.length;

  void exportPdf() => _export('PDF');
  void exportExcel() => _export('Excel');

  // No backend/report-generation wired up yet — same "demo action,
  // confirm with a snackbar" shape as ProfileController.save.
  void _export(String format) {
    AppSnackbar.info(
      'export_started_title'.tr,
      'export_started_message'.trParams({'format': format}),
    );
  }
}
