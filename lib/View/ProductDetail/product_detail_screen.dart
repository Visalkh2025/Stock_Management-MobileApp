import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/product_detail_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/product_image.dart';
import 'package:stock_management/View/Components/product_variant_row.dart';
import 'package:stock_management/View/Components/variant_price_summary.dart';
import 'package:stock_management/View/ProductDetail/stock_in_sheet.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  StockItemData get _product => controller.product;

  void _openStockIn(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StockInSheet(product: _product, onDone: controller.refreshProduct),
    );
  }

  void _pickPhotoSource(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.brand700),
              title: Text('action_take_photo'.tr),
              onTap: () {
                Get.back();
                controller.changeImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.brand700),
              title: Text('action_choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                controller.changeImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  Color _statusBg(StockStatus status) {
    switch (status) {
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
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _infoCard,
                    const SizedBox(height: 18),
                    _product.hasVariants ? _variantsCard : _simpleStockCard,
                    if (_product.warehouseStocks.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _warehouseStockCard,
                    ],
                    if (controller.canChangeImage) ...[
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'action_change_photo'.tr,
                        icon: Icons.photo_camera_outlined,
                        variant: AppButtonVariant.secondary,
                        isLoading: controller.isUploadingImage.value,
                        onPressed: controller.isUploadingImage.value ? null : () => _pickPhotoSource(context),
                      ),
                    ],
                    if (can(Perm.stockAdjust)) ...[
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'action_stock_in_title'.tr,
                        icon: Icons.add_box_outlined,
                        onPressed: () => _openStockIn(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _product.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'sku_prefix'.trParams({'sku': _product.sku}),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppScreenHeader.onHeaderMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _infoCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProductImage(url: _product.imageUrl, size: 56, radius: 16, viewable: true, title: _product.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [_product.brand, _product.category].where((v) => v != null && v.isNotEmpty).join(' • '),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          if (_product.code != null && _product.code!.isNotEmpty) _infoRow('field_product_code'.tr, _product.code!),
          _infoRow('field_sku'.tr, _product.sku),
          _infoRow('field_unit'.tr, _product.unit),
          if (_product.supplier != null && _product.supplier!.isNotEmpty) _infoRow('field_supplier'.tr, _product.supplier!),
          if (!_product.hasVariants) ...[
            _infoRow('field_warehouse'.tr, _product.warehouse),
            if (_product.costPrice != null) _infoRow('field_cost_price'.tr, formatPrice(_product.costPrice)),
            if (_product.sellingPrice != null) _infoRow('field_sale_price'.tr, formatPrice(_product.sellingPrice)),
          ],
          if (_product.description != null && _product.description!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: AppColors.border),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _product.description!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget get _warehouseStockCard {
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
          Text(
            'label_stock_by_warehouse'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 6),
          for (final w in _product.warehouseStocks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined, size: 18, color: AppColors.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.warehouseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        if (w.location != null)
                          Text(w.location!, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text('${w.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget get _variantsCard {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              'label_variants_count'.trParams({'count': '${_product.variants.length}'}),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
            ),
          ),
          for (final variant in _product.variants)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductVariantRow(data: variant, onTap: () => controller.openVariant(variant)),
                  VariantMetaRow(variant: variant),
                  VariantSubtotalLine(variant: variant),
                ],
              ),
            ),
          if (_product.variants.any((v) => v.costPrice != null)) ...[
            const SizedBox(height: 4),
            TotalValueBox(
              label: 'total_cost_value_all_variants'.tr,
              value: _product.variants.fold<double>(0, (sum, v) => sum + (v.costPrice ?? 0) * v.quantity),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget get _simpleStockCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('field_quantity'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text('${_product.quantity}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _statusBg(_product.status), borderRadius: BorderRadius.circular(9)),
                child: Text(
                  _product.status.label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _statusColor(_product.status)),
                ),
              ),
            ],
          ),
          if (_product.costPrice != null || _product.sellingPrice != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1, color: AppColors.border),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('field_cost_price'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(formatPrice(_product.costPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('field_sale_price'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(formatPrice(_product.sellingPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            if (_product.costPrice != null) ...[
              const SizedBox(height: 14),
              TotalValueBox(label: 'total_cost_value'.tr, value: _product.costPrice! * _product.quantity),
            ],
          ],
        ],
      ),
    );
  }
}
