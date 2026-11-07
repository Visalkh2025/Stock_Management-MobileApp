import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/reorder_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';
import 'package:stock_management/View/PurchaseOrders/reorder_parts.dart';

/// Purchase Orders > Needs reorder — out-of-stock and low-stock products.
/// See [ReorderController].
class ReorderScreen extends GetView<ReorderController> {
  const ReorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'po_reorder_title'.tr, below: _filters),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoading.value && controller.summary.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = controller.errorMessage.value;
                if (error != null && controller.summary.value == null) return _message(Icons.error_outline_rounded, error);
                final items = controller.items;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: items.isEmpty
                      ? ListView(children: [SizedBox(height: 320, child: _message(Icons.check_circle_outline_rounded, 'po_reorder_empty'.tr))])
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _ReorderCard(
                            item: items[index],
                            onTap: () => controller.openItem(items[index]),
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
      final summary = controller.summary.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip('filter_all'.tr, summary?.total ?? 0, 'all'),
            const SizedBox(width: 10),
            _chip('stock_status_out_of_stock'.tr, summary?.outCount ?? 0, 'out'),
            const SizedBox(width: 10),
            _chip('stock_status_low_stock'.tr, summary?.lowCount ?? 0, 'low'),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, int count, String value) {
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
            '$label  $count',
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

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({required this.item, required this.onTap});

  final ReorderItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderThumb(item.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ReorderStatusBadge(isOut: item.isOut),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.code, style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                    const SizedBox(height: 6),
                    ReorderFacts(item),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
