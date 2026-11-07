import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';

/// Shared with Product Detail and Request Detail so a price reads the same
/// way everywhere: '—' when unset, otherwise '$X.XX'.
String formatPrice(double? value) => value == null ? '—' : '\$${value.toStringAsFixed(2)}';

/// Warehouse + Cost/Sale pill shown under a variant row — used by both
/// Product Detail and Request Detail.
class VariantMetaRow extends StatelessWidget {
  const VariantMetaRow({super.key, required this.variant});

  final ProductVariantData variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 6, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              variant.warehouse,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _stat('Cost', formatPrice(variant.costPrice), AppColors.ink),
          const SizedBox(width: 16),
          _stat('Sale', formatPrice(variant.sellingPrice), AppColors.success),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.3),
        ),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// Right-aligned "Subtotal: $X" caption under a [VariantMetaRow] — empty
/// when the variant has no cost price to compute from.
class VariantSubtotalLine extends StatelessWidget {
  const VariantSubtotalLine({super.key, required this.variant});

  final ProductVariantData variant;

  @override
  Widget build(BuildContext context) {
    final cost = variant.costPrice;
    if (cost == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Subtotal: ${formatPrice(cost * variant.quantity)}',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}

/// Highlighted brand-tinted box for a labeled total (e.g. "Total cost
/// value") — used on Add Product, Product Detail, and Request Detail.
class TotalValueBox extends StatelessWidget {
  const TotalValueBox({super.key, required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand700)),
          ),
          Text(formatPrice(value), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand700)),
        ],
      ),
    );
  }
}
