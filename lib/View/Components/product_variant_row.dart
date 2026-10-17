import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';

/// One variant line shown inside an expanded [StockItemCard] — variant
/// name, its own SKU, quantity, and a compact status badge.
class ProductVariantRow extends StatelessWidget {
  const ProductVariantRow({super.key, required this.data, this.onTap});

  final ProductVariantData data;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (data.status) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  Color get _statusBg {
    switch (data.status) {
      case StockStatus.inStock:
        return AppColors.successBg;
      case StockStatus.lowStock:
        return AppColors.warningBg;
      case StockStatus.outOfStock:
        return AppColors.dangerBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(color: AppColors.brand300, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.variantName,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.variantCode.isNotEmpty ? '${data.sku} • ${data.variantCode}' : data.sku,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.quantity}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(7)),
                  child: Text(
                    data.status.label,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
