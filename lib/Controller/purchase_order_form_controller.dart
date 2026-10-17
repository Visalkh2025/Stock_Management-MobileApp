import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// One product row of a purchase order: product (+ variant), quantity and the
/// price per unit. Reuses [StockLine] for the product / variant / quantity.
class PoLine {
  PoLine() {
    priceController.addListener(() => enteredPrice.value = double.tryParse(priceController.text.trim()));
  }

  final line = StockLine();
  final priceController = TextEditingController();
  final enteredPrice = RxnDouble();

  /// True for a product that is not in the catalogue yet: the person types
  /// its name / category instead of picking one. The product is created when
  /// its goods are received (SKU can be left for the business team).
  final isNew = false.obs;
  final nameController = TextEditingController();
  final skuController = TextEditingController();
  final unitController = TextEditingController(text: 'PCS');
  final category = Rxn<LookupOption>();

  void setNew(bool value) {
    if (isNew.value == value) return;
    isNew.value = value;
    line.selectProduct(null);
    priceController.clear();
  }

  /// Identity used to spot the same product listed twice.
  String get key => isNew.value
      ? 'new|${nameController.text.trim().toLowerCase()}|${category.value?.code}'
      : '${line.product.value?.code}|${line.variant.value?.code ?? ''}';

  /// Name for messages.
  String get label => isNew.value ? nameController.text.trim() : line.displayName;

  /// The product part of the request row, plus quantity and price.
  Map<String, dynamic> toRow() {
    final sku = skuController.text.trim();
    return {
      if (isNew.value)
        'newProduct': {
          'name': nameController.text.trim(),
          'categoryCode': category.value!.code,
          'unit': unitController.text.trim().isEmpty ? 'PCS' : unitController.text.trim(),
          if (sku.isNotEmpty) 'sku': sku,
        }
      else
        ...line.baseRow(),
      'quantity': int.parse(line.quantityController.text.trim()),
      'unitPrice': double.parse(priceController.text.trim()),
    };
  }

  /// Picks the product and fills the price with its cost price.
  void selectProduct(StockItemData? item) {
    line.selectProduct(item);
    _fillPrice();
  }

  void selectVariant(LookupOption? option) {
    line.variant.value = option;
    _fillPrice();
  }

  void _fillPrice() {
    final cost = line.variantData?.costPrice ?? line.product.value?.costPrice;
    priceController.text = cost == null ? '' : cost.toStringAsFixed(2);
  }

  double get total => (line.enteredQty.value ?? 0) * (enteredPrice.value ?? 0);

  void dispose() {
    line.dispose();
    priceController.dispose();
    nameController.dispose();
    skuController.dispose();
    unitController.dispose();
  }
}

/// Create / edit a purchase order. `Get.arguments` is the
/// [PurchaseOrderDetail] being edited, or null for a new one.
class PurchaseOrderFormController extends GetxController {
  PurchaseOrderDetail? get original => Get.arguments as PurchaseOrderDetail?;
  bool get isEditing => original != null;

  final _service = PurchaseOrderService();
  final _masterData = MasterDataService();

  final formKey = GlobalKey<FormState>();
  final noteController = TextEditingController();

  final suppliers = <LookupOption>[].obs;
  final warehouses = <LookupOption>[].obs;
  final categories = <LookupOption>[].obs;
  final supplier = Rxn<LookupOption>();
  final warehouse = Rxn<LookupOption>();
  final lines = <PoLine>[].obs;

  /// A Manager must pick who approves. Admin / Super Admin don't: their
  /// order is approved as soon as it is submitted.
  bool get needsApprover => !can(Perm.poApprove);
  final approvers = <LookupOption>[].obs;
  final approver = Rxn<LookupOption>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isImporting = false.obs;
  final errorMessage = RxnString();

  StockController get catalog {
    if (Get.isRegistered<StockController>()) return Get.find<StockController>();
    return Get.put(StockController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _masterData.suppliers(),
        _masterData.warehouses(),
        _masterData.categories(),
      ]);
      suppliers.assignAll(results[0]);
      warehouses.assignAll(results[1]);
      categories.assignAll(results[2]);
      if (needsApprover) {
        final list = await _service.fetchApprovers();
        approvers.assignAll([
          for (final a in list) LookupOption(id: a.id, code: a.id, name: a.label),
        ]);
      }
      if (catalog.allItems.isEmpty) await catalog.load();
      _fillFromOriginal();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
    if (lines.isEmpty) addLine();
  }

  void _fillFromOriginal() {
    final po = original;
    if (po == null) return;
    noteController.text = po.note ?? '';
    supplier.value = _byCode(suppliers, po.supplierCode);
    warehouse.value = _byCode(warehouses, po.warehouseCode);
    if (po.approverId != null) approver.value = _byCode(approvers, po.approverId!);
    for (final item in po.items) {
      final line = PoLine();
      if (item.isNew) {
        line.isNew.value = true;
        line.nameController.text = item.productName;
        line.skuController.text = item.newSku ?? '';
        line.unitController.text = item.newUnit ?? 'PCS';
        line.category.value = _byCode(categories, item.newCategoryCode ?? '');
        line.line.quantityController.text = formatQty(item.quantity);
        line.priceController.text = item.unitPrice.toStringAsFixed(2);
        lines.add(line);
        continue;
      }
      StockItemData? product;
      for (final p in catalog.allItems) {
        if (p.code == item.productCode) product = p;
      }
      line.line.selectProduct(product);
      if (item.variantCode != null) {
        for (final v in line.line.variantOptions) {
          if (v.code == item.variantCode) line.line.variant.value = v;
        }
      }
      line.line.quantityController.text = formatQty(item.quantity);
      line.priceController.text = item.unitPrice.toStringAsFixed(2);
      lines.add(line);
    }
  }

  LookupOption? _byCode(List<LookupOption> options, String code) {
    for (final o in options) {
      if (o.code == code) return o;
    }
    return null;
  }

  void addLine() => lines.add(PoLine());

  void removeLine(PoLine line) {
    if (lines.length <= 1) return;
    lines.remove(line);
    line.dispose();
  }

  double get total => lines.fold(0.0, (sum, l) => sum + l.total);

  String? quantityValidator(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 1) return 'validation_quantity_min'.tr;
    return null;
  }

  String? priceValidator(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null || n < 0) return 'validation_price_invalid'.tr;
    return null;
  }

  /// Lets the person pick an Excel / CSV file and returns the server's
  /// row-by-row check of it (null if they cancelled or it failed — the reason
  /// is in [errorMessage]).
  Future<PoImportPreview?> pickAndPreview() async {
    errorMessage.value = null;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (file == null || path == null) return null;

    isImporting.value = true;
    try {
      if (catalog.allItems.isEmpty) await catalog.load();
      return await _service.previewImport(path, file.name);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } finally {
      isImporting.value = false;
    }
  }

  /// Adds the good rows of [preview] as product lines (a product already in
  /// the list gets the file's quantity and price). Returns how many rows
  /// were added and how many had to be skipped because the app does not have
  /// that product loaded.
  ({int added, int skipped}) applyImport(PoImportPreview preview) {
    final byCode = <String, StockItemData>{
      for (final p in catalog.allItems)
        if ((p.code ?? '').isNotEmpty) p.code!: p,
    };

    // The empty line a new form starts with is replaced by the imported ones.
    lines.removeWhere((l) {
      final blank = !l.isNew.value &&
          l.line.product.value == null &&
          l.line.quantityController.text.trim().isEmpty;
      if (blank) l.dispose();
      return blank;
    });

    var added = 0;
    var skipped = 0;
    for (final row in preview.validRows) {
      PoLine? target;

      if (row.isNew) {
        final category = _byCode(categories, row.categoryCode ?? '');
        final key = 'new|${(row.productName ?? '').toLowerCase()}|${category?.code}';
        for (final l in lines) {
          if (l.key == key) target = l;
        }
        if (target == null) {
          final created = PoLine();
          created.isNew.value = true;
          created.nameController.text = row.productName ?? '';
          created.category.value = category;
          created.unitController.text = row.unit ?? 'PCS';
          created.skuController.text = row.sku ?? '';
          lines.add(created);
          target = created;
        }
      } else {
        final product = byCode[row.productCode];
        if (product == null) {
          skipped++;
          continue;
        }
        for (final l in lines) {
          if (!l.isNew.value &&
              l.line.product.value?.code == row.productCode &&
              l.line.variant.value?.code == row.variantCode) {
            target = l;
          }
        }
        if (target == null) {
          final created = PoLine();
          created.line.selectProduct(product);
          if (row.variantCode != null) {
            for (final v in created.line.variantOptions) {
              if (v.code == row.variantCode) created.line.variant.value = v;
            }
          }
          lines.add(created);
          target = created;
        }
      }

      target.line.quantityController.text = formatQty(row.quantity ?? 0);
      target.priceController.text = (row.unitPrice ?? 0).toStringAsFixed(2);
      added++;
    }

    if (lines.isEmpty) addLine();
    return (added: added, skipped: skipped);
  }

  /// [submit] false keeps it as a draft; true sends it for approval.
  Future<void> save({required bool submit}) async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final seen = <String>{};
    for (final l in lines) {
      if (!seen.add(l.key)) {
        errorMessage.value = '${'validation_duplicate_product'.tr}: ${l.label}';
        return;
      }
    }

    if (submit && needsApprover && approver.value == null) {
      errorMessage.value = 'po_approver_required'.tr;
      return;
    }

    final body = <String, dynamic>{
      'supplierCode': supplier.value!.code,
      'warehouseCode': warehouse.value!.code,
      'submit': submit,
      if (submit && needsApprover) 'approverId': approver.value!.id,
      if (noteController.text.trim().isNotEmpty) 'note': noteController.text.trim(),
      'items': [
        for (final l in lines) l.toRow(),
      ],
    };

    isSaving.value = true;
    try {
      final po = original;
      if (po == null) {
        await _service.create(body);
      } else {
        await _service.update(po.id, body);
      }
      Get.back();
      Get.snackbar(
        'menu_purchase_orders'.tr,
        (submit ? (needsApprover ? 'po_submitted_message' : 'po_approved_message') : 'po_saved_message').tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.onClose();
  }
}
