import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';

/// Square product photo, or a box icon when the product has none.
class ReorderThumb extends StatelessWidget {
  const ReorderThumb(this.url, {super.key, this.size = 46});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.inventory_2_outlined, size: 22, color: AppColors.brand700);
    final image = url;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
      child: image == null
          ? fallback
          : Image.network(image, fit: BoxFit.cover, errorBuilder: (context, error, stack) => fallback),
    );
  }
}

/// "Out of Stock" (red) / "Low Stock" (amber) pill.
class ReorderStatusBadge extends StatelessWidget {
  const ReorderStatusBadge({super.key, required this.isOut});

  final bool isOut;

  @override
  Widget build(BuildContext context) {
    final color = isOut ? AppColors.danger : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isOut ? AppColors.dangerBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOut ? Icons.cancel_outlined : Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            (isOut ? 'stock_status_out_of_stock' : 'stock_status_low_stock').tr,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Stock / minimum / on-order / suggested lines shared by the reorder list,
/// the supplier comparison and the low-stock picker.
class ReorderFacts extends StatelessWidget {
  const ReorderFacts(this.item, {super.key});

  final ReorderItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'po_reorder_stock'.trParams({'stock': formatQty(item.stock), 'min': formatQty(item.minimumStock)}),
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (item.onOrder > 0) ...[
          const SizedBox(height: 2),
          Text(
            'po_reorder_on_order'.trParams({'qty': formatQty(item.onOrder), 'pos': item.onOrderPoNumbers.join(', ')}),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.brand700),
          ),
        ],
        const SizedBox(height: 2),
        item.covered
            ? Text(
                'po_reorder_covered'.tr,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.success),
              )
            : Text(
                'po_reorder_suggested'.trParams({'qty': '${item.suggestedQuantity}'}),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
      ],
    );
  }
}
