import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/approval_chain.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/Services/request_service.dart';
import 'package:stock_management/View/AddProduct/product_import_sheet.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

class VariantDraft {
  VariantDraft()
      : nameController = TextEditingController(),
        skuController = TextEditingController(),
        barcodeController = TextEditingController(),
        quantityController = TextEditingController(),
        locationController = TextEditingController(),
        costController = TextEditingController(),
        sellController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final TextEditingController locationController;
  final TextEditingController costController;
  final TextEditingController sellController;
  final warehouse = Rxn<LookupOption>();

  /// Photo of this variant (required).
  final image = Rxn<File>();

  void dispose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
    locationController.dispose();
    costController.dispose();
    sellController.dispose();
  }
}

/// Add Product form.
class AddProductController extends GetxController {
  final _products = ProductService();
  final _masterData = MasterDataService();

  final nameController = TextEditingController();
  final skuController = TextEditingController();
  final unitController = TextEditingController(text: 'PCS');
  final descriptionController = TextEditingController();
  final barcodeController = TextEditingController();
  final productImage = Rxn<File>();
  final _picker = ImagePicker();
  final quantityController = TextEditingController();
  final locationController = TextEditingController();
  final minStockController = TextEditingController();
  final costPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();

  // Picker selections (the API takes the codes).
  final selectedCategory = Rxn<LookupOption>();
  final selectedBrand = Rxn<LookupOption>();
  final selectedSupplier = Rxn<LookupOption>();
  final selectedWarehouse = Rxn<LookupOption>();

  final categories = <LookupOption>[].obs;
  final brands = <LookupOption>[].obs;
  final suppliers = <LookupOption>[].obs;
  final warehouses = <LookupOption>[].obs;
  final isLoadingOptions = false.obs;

  final isSaving = false.obs;
  final isImporting = false.obs;
  final errorMessage = RxnString();

  /// Bulk Excel import creates products directly (PRODUCT_IMPORT: Admin and
  /// Manager). It is separate from PRODUCT_CREATE, which decides whether the
  /// form saves directly or sends a request.
  bool get canImport => can(Perm.productImport);

  Future<void> importExcel() async {
    errorMessage.value = null;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (file == null || path == null) return;

    // Step 1: dry run. Nothing is saved until the person confirms the review.
    isImporting.value = true;
    Map<String, dynamic> preview;
    try {
      preview = await _products.previewImport(path, file.name);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return;
    } finally {
      isImporting.value = false;
    }

    final rows = (preview['rows'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final errors = (preview['errors'] as List? ?? const []).map((e) => e.toString()).toList();
    final ok = await Get.bottomSheet<bool>(
      ProductImportSheet(fileName: file.name, rows: rows, errors: errors),
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );
    if (ok != true) return;

    // Step 2: the person confirmed: really import.
    isImporting.value = true;
    try {
      final result = await _products.importExcel(path, file.name);
      final count = (result['importedCount'] as num?)?.toInt() ?? 0;
      if (Get.isRegistered<StockController>()) {
        await Get.find<StockController>().load();
      }
      Get.back();
      AppSnackbar.success(
        'add_product_title'.tr,
        'import_products_done'.trParams({'count': '$count'}),
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isImporting.value = false;
    }
  }

  Future<void> downloadTemplate() async {
    errorMessage.value = null;
    try {
      final bytes = await _products.downloadImportTemplate();
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'import_products_template'.tr,
        fileName: 'products_import_template.xlsx',
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (saved != null) {
        AppSnackbar.success('import_products_template'.tr, 'import_products_template_saved'.tr);
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  final hasVariants = false.obs;
  final variantDrafts = <VariantDraft>[].obs;

  // ---- Approval chain (only for people who cannot create directly) ----
  final _requests = RequestService();
  /// Staff -> Manager / Admin / Super Admin, Manager -> Admin / Super Admin,
  /// Admin -> Super Admin. Super Admin saves directly (no chain).
  late final chain = ApprovalChain(approverRoles: _approverRolesForMe());

  static Set<String>? _approverRolesForMe() {
    final roles = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>().roles : const <String>[];
    if (roles.contains('SUPER_ADMIN')) return null;
    if (roles.contains('ADMIN')) return {'SUPER_ADMIN'};
    if (roles.contains('MANAGER')) return {'ADMIN', 'SUPER_ADMIN'};
    return {'MANAGER', 'ADMIN', 'SUPER_ADMIN'};
  }

  /// True when this person must send a request instead of saving directly.
  bool get needsApproval {
    final signedIn = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
    // Only a Super Admin skips the request.
    return !(signedIn?.isSuperAdmin ?? false);
  }

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Arriving from the Scan screen after an unrecognized code — prefill
    // Barcode so the person doesn't have to retype what was just scanned.
    final scannedCode = Get.arguments;
    if (scannedCode is String && scannedCode.trim().isNotEmpty) {
      barcodeController.text = scannedCode.trim();
    }
    loadOptions();
    if (needsApproval) {
      chain.start().then((_) => errorMessage.value ??= chain.loadError.value);
    }
  }

  Future<void> loadOptions() async {
    isLoadingOptions.value = true;
    try {
      final results = await Future.wait([
        _masterData.categories(),
        _masterData.brands(),
        _masterData.suppliers(),
        _masterData.warehouses(),
      ]);
      categories.assignAll(results[0]);
      brands.assignAll(results[1]);
      suppliers.assignAll(results[2]);
      warehouses.assignAll(results[3]);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoadingOptions.value = false;
    }
  }

  void toggleHasVariants(bool value) {
    hasVariants.value = value;
    if (value && variantDrafts.isEmpty) {
      addVariantRow();
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) {
      productImage.value = File(picked.path);
    }
  }

  void removeImage() => productImage.value = null;

  Future<void> pickVariantImage(int index, ImageSource source) async {
    if (index < 0 || index >= variantDrafts.length) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) {
      variantDrafts[index].image.value = File(picked.path);
    }
  }

  void removeVariantImage(int index) {
    if (index < 0 || index >= variantDrafts.length) return;
    variantDrafts[index].image.value = null;
  }

  /// Photos by variant code (`V1`, `V2`…), matching the codes in [_buildPayload].
  Map<String, File> _variantImages() {
    final images = <String, File>{};
    if (!hasVariants.value) return images;
    for (var i = 0; i < variantDrafts.length; i++) {
      final file = variantDrafts[i].image.value;
      if (file != null) images['V${i + 1}'] = file;
    }
    return images;
  }

  void addVariantRow() => variantDrafts.add(VariantDraft());

  void removeVariantRow(int index) {
    if (index < 0 || index >= variantDrafts.length) return;
    variantDrafts.removeAt(index).dispose();
  }

  // ---- Validators shared with the screen ----

  String? requiredText(String? v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null;

  /// Quantity must be a whole number of at least 1.
  String? quantityValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'validation_required'.tr;
    final qty = int.tryParse(text);
    if (qty == null || qty < 1) return 'validation_qty_min'.tr;
    return null;
  }

  double? _parsePrice(String text) => double.tryParse(text.trim());

  int _parseQty(String text) => int.tryParse(text.trim()) ?? 0;

  Future<void> save() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (hasVariants.value) {
      final missing = variantDrafts.indexWhere((d) => d.image.value == null);
      if (missing != -1) {
        errorMessage.value = 'variant_photo_required'.trParams({'index': '${missing + 1}'});
        return;
      }
    }
    if (needsApproval) {
      final chainError = chain.error;
      if (chainError != null) {
        errorMessage.value = chainError;
        return;
      }
      await _submitRequest();
    } else {
      await _saveToServer();
    }
  }

  // ---------------------------------------------------------------- direct

  /// The product / variants / stock the server expects, from the form.
  ({Map<String, dynamic> product, List<Map<String, dynamic>> variants, List<Map<String, dynamic>> stock}) _buildPayload() {
    final sku = skuController.text.trim();
    final barcode = barcodeController.text.trim();
    final description = descriptionController.text.trim();
    final unit = unitController.text.trim().isEmpty ? 'PCS' : unitController.text.trim();
    final minStock = int.tryParse(minStockController.text.trim());

    final product = <String, dynamic>{
      'productName': nameController.text.trim(),
      if (sku.isNotEmpty) 'productSku': sku,
      'categoryCode': selectedCategory.value!.code,
      if (selectedBrand.value != null) 'brandCode': selectedBrand.value!.code,
      if (selectedSupplier.value != null) 'supplierCode': selectedSupplier.value!.code,
      'unit': unit,
      if (barcode.isNotEmpty) 'productBarcode': barcode,
      if (description.isNotEmpty) 'description': description,
      'hasVariants': hasVariants.value,
      'minimumStock': ?minStock,
    };

    final variants = <Map<String, dynamic>>[];
    final stock = <Map<String, dynamic>>[];

    if (hasVariants.value) {
      for (var i = 0; i < variantDrafts.length; i++) {
        final d = variantDrafts[i];
        final code = 'V${i + 1}';
        final vSku = d.skuController.text.trim();
        final vBarcode = d.barcodeController.text.trim();
        final cost = _parsePrice(d.costController.text);
        final sell = _parsePrice(d.sellController.text);
        variants.add({
          'variantCode': code,
          'variantName': d.nameController.text.trim(),
          if (vSku.isNotEmpty) 'variantSku': vSku,
          if (vBarcode.isNotEmpty) 'variantBarcode': vBarcode,
          'variantCostPrice': ?cost,
          'variantSellingPrice': ?sell,
        });
        final loc = d.locationController.text.trim();
        stock.add({
          'variantCode': code,
          'warehouseCode': d.warehouse.value!.code,
          'quantity': _parseQty(d.quantityController.text),
          if (loc.isNotEmpty) 'location': loc,
        });
      }
    } else {
      final cost = _parsePrice(costPriceController.text);
      final sell = _parsePrice(sellingPriceController.text);
      if (cost != null) product['productCostPrice'] = cost;
      if (sell != null) product['productSellingPrice'] = sell;
      final loc = locationController.text.trim();
      stock.add({
        'warehouseCode': selectedWarehouse.value!.code,
        'quantity': _parseQty(quantityController.text),
        if (loc.isNotEmpty) 'location': loc,
      });
    }

    return (product: product, variants: variants, stock: stock);
  }

  Future<void> _saveToServer() async {
    final payload = _buildPayload();

    isSaving.value = true;
    try {
      await _products.createProduct(
        product: payload.product,
        variants: payload.variants,
        stock: payload.stock,
        image: productImage.value,
        variantImages: _variantImages(),
      );
      if (Get.isRegistered<StockController>()) {
        await Get.find<StockController>().load();
      }
      Get.back();
      AppSnackbar.success('add_product_title'.tr, 'product_added_message'.tr);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  // --------------------------------------------------------------- request

  Future<void> _submitRequest() async {
    final payload = _buildPayload();
    final approvers = chain.toPayload();

    isSaving.value = true;
    try {
      await _requests.createProductRequest(
        product: payload.product,
        variants: payload.variants,
        stock: payload.stock,
        approvers: approvers,
        image: productImage.value,
        variantImages: _variantImages(),
      );
      if (!Get.isRegistered<RequestController>()) {
        Get.put(RequestController(), permanent: true);
      } else {
        await Get.find<RequestController>().load();
      }
      Get.offNamed(Routes.requests);
      AppSnackbar.success('add_product_title'.tr, 'product_request_sent_message'.tr);
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
    unitController.dispose();
    descriptionController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
    locationController.dispose();
    minStockController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    for (final draft in variantDrafts) {
      draft.dispose();
    }
    super.onClose();
  }
}
