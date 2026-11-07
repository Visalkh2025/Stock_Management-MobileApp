import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

class ProductDetailController extends GetxController {
  final _service = ProductService();
  final _picker = ImagePicker();

  /// True while a new photo is uploading.
  final isUploadingImage = false.obs;

  bool get canChangeImage => can(Perm.productImage) && (product.id?.isNotEmpty ?? false);

  final Rx<StockItemData> _product = Rx<StockItemData>(Get.arguments as StockItemData);

  /// Reactive: re-read after a Stock In so quantities update in place.
  StockItemData get product => _product.value;

  /// Opens the stock history of this product.
  void openHistory() => Get.toNamed(Routes.stockHistory, arguments: product);

  /// Opens the Edit Product form; reloads the product when it was saved.
  Future<void> openEdit() async {
    final saved = await Get.toNamed(Routes.editProduct, arguments: product);
    if (saved == true) await refreshProduct();
  }

  void openVariant(ProductVariantData variant) {
    // TODO: variant-level detail (per-warehouse breakdown) once available.
  }

  /// Re-fetches this product from the server (new quantities / locations)
  /// and refreshes the Stock list behind it.
  Future<void> refreshProduct() async {
    final code = product.code;
    if (code == null || code.isEmpty) return;
    try {
      _product.value = await _service.fetchByCode(code);
    } on ApiException {
      // Keep showing what we have; the list reload below still runs.
    }
    if (Get.isRegistered<StockController>()) {
      await Get.find<StockController>().load();
    }
  }

  /// Picks a photo, uploads it and shows the product with its new picture.
  Future<void> changeImage(ImageSource source) async {
    final id = product.id;
    if (id == null || id.isEmpty) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked == null) return;
    isUploadingImage.value = true;
    try {
      await _service.updateImage(id, File(picked.path));
      await refreshProduct();
      AppSnackbar.success('action_change_photo'.tr, 'photo_updated'.tr);
    } on ApiException catch (e) {
      AppSnackbar.error('action_change_photo'.tr, e.message);
    } finally {
      isUploadingImage.value = false;
    }
  }
}
