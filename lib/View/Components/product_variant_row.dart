import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/product_image.dart';

/// One variant line shown inside an expanded [StockItemCard] — variant
/// name, its own SKU, quantity, and a compact status badge.
class ProductVariantRow extends StatelessWidget {
  const ProductVariantRow({super.key, required this.data, this.onTap, this.selected = false, this.viewablePhoto = false});

  final ProductVariantData data;
  final VoidCallback? onTap;

  /// Highlights the row (the Stock screen shows the selected variant's photo).
  final bool selected;

  /// Tapping the photo opens it full screen (Product Detail).
  final bool viewablePhoto;

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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand700.withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ProductImage(url: data.imageUrl, size: 36, radius: 9, iconSize: 18, viewable: viewablePhoto, title: data.variantName),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.variantName,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.variantCode.isNotEmpty ? '${data.sku} • ${data.variantCode}' : data.sku,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted),
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
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
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
