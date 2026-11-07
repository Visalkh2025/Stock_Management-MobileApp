import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_models.dart';

/// Shows the QR code of a product (and of each variant) so it can be scanned
/// from the Scan tab. The QR content is the SKU — the same value the scanner
/// looks up via `GET /products/by-code/:code`.
class ProductQrCard extends StatelessWidget {
  const ProductQrCard({super.key, required this.product});

  final StockItemData product;

  @override
  Widget build(BuildContext context) {
    final variants = product.variants.where((v) => v.sku.isNotEmpty).toList();
    if (product.sku.isEmpty && variants.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.brand700),
              const SizedBox(width: 8),
              Text(
                'product_qr_title'.tr,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
              ),
            ],
          ),
          if (product.sku.isNotEmpty) ...[
            const SizedBox(height: 12),
            _QrTile(code: product.sku, title: product.name, size: 120),
          ],
          if (variants.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              'product_qr_variant'.tr,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
            ),
            for (final v in variants) ...[
              const SizedBox(height: 12),
              _QrTile(code: v.sku, title: v.variantName, size: 96),
            ],
          ],
        ],
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  const _QrTile({required this.code, required this.title, required this.size});

  final String code;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showLarge(context),
      child: Row(
        children: [
          _qr(size),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(code, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.brand700)),
                const SizedBox(height: 4),
                Text('product_qr_hint'.tr, style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Always black-on-white (even in dark theme) so scanners can read it.
  Widget _qr(double s) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: QrImageView(
          data: code,
          size: s,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
        ),
      );

  void _showLarge(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qr(240),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand700)),
            ],
          ),
        ),
      ),
    );
  }
}
