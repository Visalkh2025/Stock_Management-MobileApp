import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/product_image.dart';
import 'package:stock_management/View/Components/product_variant_row.dart';

/// One product/SKU row on the Stock screen. For a product with variants,
/// tapping a variant in the expanded list shows that variant's photo.
class StockItemCard extends StatefulWidget {
  const StockItemCard({
    super.key,
    required this.data,
    this.onTap,
    this.expanded = false,
    this.onToggleExpand,
  });

  final StockItemData data;
  final VoidCallback? onTap;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  @override
  State<StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends State<StockItemCard> {
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
    ProductVariantData? selected;
    for (final v in widget.data.variants) {
      if (v.variantCode == _selectedCode) selected = v;
    }
    return _StockItemCardView(
      data: widget.data,
      onTap: widget.onTap,
      expanded: widget.expanded,
      onToggleExpand: widget.onToggleExpand,
      selectedVariant: selected,
      onSelectVariant: (v) => setState(() => _selectedCode = _selectedCode == v.variantCode ? null : v.variantCode),
    );
  }
}

class _StockItemCardView extends StatelessWidget {
  const _StockItemCardView({
    required this.data,
    this.onTap,
    this.expanded = false,
    this.onToggleExpand,
    this.selectedVariant,
    this.onSelectVariant,
  });

  final StockItemData data;
  final VoidCallback? onTap;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final ProductVariantData? selectedVariant;
  final ValueChanged<ProductVariantData>? onSelectVariant;

  /// The photo shown on the card: the selected variant's, else the product's,
  /// else the first variant that has one.
  String? get _photo {
    final own = selectedVariant?.imageUrl;
    if (own != null && own.trim().isNotEmpty) return own;
    final product = data.imageUrl;
    if (product != null && product.trim().isNotEmpty) return product;
    for (final v in data.variants) {
      final url = v.imageUrl;
      if (url != null && url.trim().isNotEmpty) return url;
    }
    return null;
  }

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
    final hasVariants = data.hasVariants;
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: hasVariants ? onToggleExpand : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brand700.withAlpha(30)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProductImage(url: _photo, size: 46, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasVariants
                              ? '${data.sku} • ${data.variants.length} variants'
                              : '${data.sku} • ${data.warehouse}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          data.status.label,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor),
                        ),
                      ),
                    ],
                  ),
                  if (hasVariants) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
              if (hasVariants)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, thickness: 1, color: AppColors.border),
                            ),
                            for (final variant in data.variants)
                              ProductVariantRow(
                                data: variant,
                                selected: variant.variantCode == selectedVariant?.variantCode,
                                onTap: onSelectVariant == null ? null : () => onSelectVariant!(variant),
                              ),
                            InkWell(
                              onTap: onTap,
                              child: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'View full details',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
