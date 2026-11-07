import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_history_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Model/stock_history_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// Stock history: Stock In, Stock Out, Transfer and Adjustment, newest first,
/// with a type filter. See [StockHistoryController].
class StockHistoryScreen extends GetView<StockHistoryController> {
  const StockHistoryScreen({super.key});

  static const _kinds = ['ALL', 'IN', 'OUT', 'TRANSFER', 'ADJUSTMENT'];

  @override
  Widget build(BuildContext context) {
    final product = controller.product;
    return Scaffold(
      body: Column(
        children: [
          PoHeader(
            title: product == null ? 'history_title'.tr : '${'history_title'.tr} • ${product.name}',
            below: _filters,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoading.value && controller.entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = controller.errorMessage.value;
                if (error != null && controller.entries.isEmpty) {
                  return _message(Icons.error_outline_rounded, error);
                }
                final entries = controller.entries;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: entries.isEmpty
                      ? ListView(children: [SizedBox(height: 320, child: _message(Icons.history_rounded, 'history_empty'.tr))])
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) controller.loadMore();
                            return false;
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                            itemCount: entries.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index == entries.length) {
                                return Obx(
                                  () => controller.isLoadingMore.value
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      : const SizedBox.shrink(),
                                );
                              }
                              return _HistoryCard(entries[index]);
                            },
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _filters {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final kind in _kinds) ...[
                  _chip(kind == 'ALL' ? 'filter_all'.tr : kindLabel(kind), kind),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          DateFilterBar(value: controller.dateFilter.value, onChanged: controller.setDateFilter),
        ],
      );
    });
  }

  Widget _chip(String label, String value) {
    final active = controller.filter.value == value;
    return Material(
      color: active ? Colors.white : AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => controller.setFilter(value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.brand700 : AppScreenHeader.onHeader,
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translated name of a history type.
String kindLabel(String kind) {
  switch (kind) {
    case 'IN':
      return 'history_kind_in'.tr;
    case 'OUT':
      return 'history_kind_out'.tr;
    case 'TRANSFER':
      return 'history_kind_transfer'.tr;
    default:
      return 'history_kind_adjustment'.tr;
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.entry);

  final StockHistoryEntry entry;

  (IconData, Color, Color) get _look {
    switch (entry.kind) {
      case 'IN':
        return (Icons.south_west_rounded, AppColors.success, AppColors.successBg);
      case 'OUT':
        return (Icons.north_east_rounded, AppColors.danger, AppColors.dangerBg);
      case 'TRANSFER':
        return (Icons.swap_horiz_rounded, AppColors.brand700, AppColors.brand50);
      default:
        return (Icons.tune_rounded, AppColors.warning, AppColors.warningBg);
    }
  }

  String get _quantityText {
    final qty = formatQty(entry.quantity);
    switch (entry.kind) {
      case 'IN':
        return '+$qty';
      case 'OUT':
        return '−$qty';
      case 'ADJUSTMENT':
        return entry.toWarehouse != null ? '+$qty' : '−$qty';
      default:
        return qty;
    }
  }

  String get _route {
    final from = entry.fromWarehouse;
    final to = entry.toWarehouse;
    if (from != null && to != null) return '$from → $to';
    if (to != null) return '→ $to';
    if (from != null) return '$from →';
    return '';
  }

  String get _when {
    final d = entry.at;
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${formatDate(d)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = _look;
    final name = entry.variantName == null ? entry.productName : '${entry.productName} • ${entry.variantName}';
    final meta = [
      if (_when.isNotEmpty) _when,
      if (entry.byStaff != null) 'history_by'.trParams({'staff': entry.byStaff!}),
      if (entry.requestNo != null) entry.requestNo!,
    ].join(' • ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  [kindLabel(entry.kind), if (_route.isNotEmpty) _route].join(' • '),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
                if (entry.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(entry.reason!, style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35)),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_quantityText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
