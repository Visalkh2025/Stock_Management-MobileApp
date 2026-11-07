import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// One existing variant being edited (matched on the server by its code).
class EditVariantDraft {
  EditVariantDraft(ProductVariantData v)
      : code = v.variantCode,
        id = v.id,
        imageUrl = v.imageUrl,
        nameController = TextEditingController(text: v.variantName),
        skuController = TextEditingController(text: v.sku),
        barcodeController = TextEditingController(text: v.barcode ?? ''),
        costController = TextEditingController(text: _money(v.costPrice)),
        sellController = TextEditingController(text: _money(v.sellingPrice));

  final String code;
  final String? id;

  /// The photo already saved on the server, if any.
  final String? imageUrl;

  /// A newly picked photo, uploaded on save.
  final newImage = Rxn<File>();

  bool get hasPhoto => newImage.value != null || (imageUrl != null && imageUrl!.trim().isNotEmpty);

  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController barcodeController;
  final TextEditingController costController;
  final TextEditingController sellController;

  void dispose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    costController.dispose();
    sellController.dispose();
  }
}

String _money(double? v) => v == null ? '' : v.toStringAsFixed(2);

String _qty(num? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// Edit Product (PRODUCT_EDIT: Manager, Admin, Super Admin). Sends the whole
/// form to `PATCH /products/:id`. Stock quantities are not part of it — those
/// change through Stock In / Adjust so the history stays correct.
class EditProductController extends GetxController {
  final _products = ProductService();
  final _masterData = MasterDataService();

  /// The product being edited, handed over by the detail screen.
  late final StockItemData product = Get.arguments as StockItemData;

  late final nameController = TextEditingController(text: product.name);
  late final skuController = TextEditingController(text: product.sku);
  late final barcodeController = TextEditingController(text: product.barcode ?? '');
  late final unitController = TextEditingController(text: product.unit);
  late final descriptionController = TextEditingController(text: product.description ?? '');
  late final costPriceController = TextEditingController(text: _money(product.costPrice));
  late final sellingPriceController = TextEditingController(text: _money(product.sellingPrice));
  late final minStockController = TextEditingController(text: _qty(product.minStock));
  late final maxStockController = TextEditingController(text: _qty(product.maxStock));

  final selectedCategory = Rxn<LookupOption>();
  final selectedBrand = Rxn<LookupOption>();
  final selectedSupplier = Rxn<LookupOption>();

  final categories = <LookupOption>[].obs;
  final brands = <LookupOption>[].obs;
  final suppliers = <LookupOption>[].obs;
  final isLoadingOptions = false.obs;

  late final variantDrafts = <EditVariantDraft>[for (final v in product.variants) EditVariantDraft(v)];

  final isSaving = false.obs;
  final errorMessage = RxnString();
  final formKey = GlobalKey<FormState>();

  bool get hasVariants => product.hasVariants;

  @override
  void onInit() {
    super.onInit();
    loadOptions();
  }

  Future<void> loadOptions() async {
    isLoadingOptions.value = true;
    try {
      final results = await Future.wait([
        _masterData.categories(),
        _masterData.brands(),
        _masterData.suppliers(),
      ]);
      categories.assignAll(results[0]);
      brands.assignAll(results[1]);
      suppliers.assignAll(results[2]);
      selectedCategory.value = _byCode(categories, product.categoryCode);
      selectedBrand.value = _byCode(brands, product.brandCode);
      selectedSupplier.value = _byCode(suppliers, product.supplierCode);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoadingOptions.value = false;
    }
  }

  LookupOption? _byCode(List<LookupOption> options, String? code) {
    if (code == null || code.isEmpty) return null;
    for (final o in options) {
      if (o.code == code) return o;
    }
    return null;
  }

  final _picker = ImagePicker();

  Future<void> pickVariantImage(EditVariantDraft draft, ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) draft.newImage.value = File(picked.path);
  }

  String? requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null;

  Future<void> save() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final id = product.id;
    if (id == null || id.isEmpty) return;
    if (hasVariants) {
      final missing = variantDrafts.indexWhere((d) => !d.hasPhoto);
      if (missing != -1) {
        errorMessage.value = 'variant_photo_required'.trParams({'index': '${missing + 1}'});
        return;
      }
    }

    double? number(TextEditingController c) => double.tryParse(c.text.trim());

    final body = <String, dynamic>{
      'name': nameController.text.trim(),
      'sku': skuController.text.trim(),
      'barcode': barcodeController.text.trim(),
      'unit': unitController.text.trim(),
      'description': descriptionController.text.trim(),
      'categoryCode': selectedCategory.value?.code,
      'brandCode': selectedBrand.value?.code ?? '',
      'supplierCode': selectedSupplier.value?.code ?? '',
      'minimumStock': number(minStockController) ?? 0,
      'maximumStock': number(maxStockController),
      if (!hasVariants) 'costPrice': number(costPriceController) ?? 0,
      if (!hasVariants) 'sellingPrice': number(sellingPriceController) ?? 0,
      if (hasVariants)
        'variants': [
          for (final v in variantDrafts)
            {
              'code': v.code,
              'name': v.nameController.text.trim(),
              'sku': v.skuController.text.trim(),
              'barcode': v.barcodeController.text.trim(),
              'costPrice': number(v.costController),
              'sellingPrice': number(v.sellController),
            },
        ],
    };

    isSaving.value = true;
    try {
      await _products.updateProduct(id, body);
      for (final v in variantDrafts) {
        final file = v.newImage.value;
        final variantId = v.id;
        if (file == null || variantId == null || variantId.isEmpty) continue;
        await _products.updateVariantImage(variantId, file);
      }
      Get.back(result: true);
      AppSnackbar.success('edit_product_title'.tr, 'product_updated'.tr);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    unitController.dispose();
    descriptionController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    minStockController.dispose();
    maxStockController.dispose();
    for (final v in variantDrafts) {
      v.dispose();
    }
    super.onClose();
  }
}
