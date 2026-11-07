import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/product_image.dart';

/// One product tile of the Stock screen's grid view: photo with a status
/// badge in its corner, name, SKU, and the quantity (with the minimum).
/// Tapping always opens Product Detail (variants are listed there).
class StockItemGridCard extends StatelessWidget {
  const StockItemGridCard({
    super.key,
    required this.data,
    required this.imageSize,
    this.onTap,
  });

  final StockItemData data;

  /// Side of the square photo (the card width minus its padding).
  final double imageSize;
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
    final subtitle = data.hasVariants
        ? 'stock_variants_short'.trParams({'n': '${data.variants.length}'})
        : data.sku;
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brand700.withAlpha(30)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ProductImage(
                    url: data.imageUrl ?? data.variants.map((v) => v.imageUrl).whereType<String>().firstOrNull,
                    size: imageSize,
                    radius: 12,
                    iconSize: 34,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        data.status.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: Text(
                  data.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.quantity}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
                  ),
                  const Spacer(),
                  if (data.minStock != null)
                    Text(
                      'stock_min_short'.trParams({'min': '${data.minStock}'}),
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
