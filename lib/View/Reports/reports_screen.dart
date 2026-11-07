import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/reports_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';
import 'package:stock_management/View/Components/stock_movement_chart.dart';

/// More > Reports — a Dashboard/KPI screen (design system pattern #4): a stat-card grid, one chart, one breakdown list below.
class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _sectionLabel('section_overview'.tr),
                    const SizedBox(height: 10),
                    _kpiGrid,
                    const SizedBox(height: 18),
                    DateFilterBar(
                      value: controller.dateFilter.value,
                      onChanged: controller.setDateFilter,
                      showAll: false,
                    ),
                    const SizedBox(height: 12),
                    _chartCard,
                    const SizedBox(height: 18),
                    _sectionLabel('section_requests_by_type'.tr),
                    const SizedBox(height: 10),
                    _breakdownCard,
                    const SizedBox(height: 18),
                    _sectionLabel('section_export'.tr),
                    const SizedBox(height: 10),
                    _exportRow,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _header {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppScreenHeader.onHeader),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'menu_reports'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget get _kpiGrid {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.payments_outlined,
                iconColor: AppColors.brand700,
                iconBg: AppColors.brand50,
                label: 'kpi_stock_value'.tr,
                value: controller.totalStockValue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.brand700,
                iconBg: AppColors.brand50,
                label: 'kpi_total_skus'.tr,
                value: '${controller.skuCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                iconBg: AppColors.warningBg,
                label: 'filter_low_stock'.tr,
                value: '${controller.lowStockCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.success,
                iconBg: AppColors.successBg,
                label: 'kpi_pending_requests'.tr,
                value: '${controller.pendingCount}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget get _chartCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('stock_movement'.tr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(controller.dateFilter.value.rangeLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(AppColors.brand600, 'legend_in'.tr),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFF9CA3AF), 'legend_out'.tr),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.chartLoading.value)
            const SizedBox(height: 86, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (controller.chartEmpty)
            SizedBox(
              height: 86,
              child: Center(
                child: Text('chart_empty'.tr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
              ),
            )
          else ...[
            StockMovementChart(inSeries: controller.stockInSeries.toList(), outSeries: controller.stockOutSeries.toList()),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < controller.chartLabels.length; i++)
                  Text(
                    controller.chartLabels[i],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: i == controller.highlightedIndex ? FontWeight.w700 : FontWeight.w600,
                      color: i == controller.highlightedIndex ? AppColors.brand700 : AppColors.muted,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
      ],
    );
  }

  // Maps the RequestItemData.typeLabel values (matched by string equality
  // elsewhere in the app, e.g. MoreController.purchaseOrderCount — never
  // translate the underlying value) to a display-only translation key.
  static const _typeLabelKeys = {
    'Stock In': 'type_stock_in',
    'Stock Out': 'type_stock_out',
    'Stock Transfer': 'type_stock_transfer',
    'Adjustment': 'type_adjustment',
    'Purchase Order': 'type_purchase_order',
    'Product Create': 'type_product_create',
  };

  String _typeDisplayLabel(String raw) => (_typeLabelKeys[raw] ?? raw).tr;

  Widget get _breakdownCard {
    final entries = controller.requestsByType;
    final total = controller.totalRequests == 0 ? 1 : controller.totalRequests;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _breakdownRow(_typeDisplayLabel(entries[i].key), entries[i].value, entries[i].value / total),
            if (i != entries.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int count, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text('$count', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.brand700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.pageBg,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand600),
          ),
        ),
      ],
    );
  }

  Widget get _exportRow {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'export_pdf'.tr,
            icon: Icons.picture_as_pdf_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: controller.exportPdf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: 'export_excel'.tr,
            icon: Icons.table_chart_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: controller.exportExcel,
          ),
        ),
      ],
    );
  }
}
