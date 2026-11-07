import 'dart:async';

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
import 'package:stock_management/View/Components/app_snackbar.dart';

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

  /// Optional brand of the new product.
  final brand = Rxn<LookupOption>();

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
          if (brand.value != null) 'brandCode': brand.value!.code,
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

/// A supplier that the products on this order were bought from before.
class SupplierSuggestion {
  SupplierSuggestion(this.code, this.name);

  final String code;
  final String name;

  /// How many of the order's products this supplier has supplied.
  int products = 0;
  DateTime? lastOrderedAt;

  /// The usual supplier set on one of the order's products.
  bool isDefault = false;
}

/// Create / edit a purchase order. `Get.arguments` is the
/// [PurchaseOrderDetail] being edited, or null for a new one.
class PurchaseOrderFormController extends GetxController {
  PurchaseOrderDetail? get original {
    final a = Get.arguments;
    return a is PurchaseOrderDetail ? a : null;
  }

  /// Set when the form is opened from the reorder flow (product + supplier
  /// already chosen) instead of editing an existing order.
  PoPrefill? get prefill {
    final a = Get.arguments;
    return a is PoPrefill ? a : null;
  }

  bool get isEditing => original != null;

  final _service = PurchaseOrderService();
  final _masterData = MasterDataService();

  final formKey = GlobalKey<FormState>();
  final noteController = TextEditingController();

  final suppliers = <LookupOption>[].obs;
  final warehouses = <LookupOption>[].obs;
  final categories = <LookupOption>[].obs;
  final brands = <LookupOption>[].obs;
  final supplier = Rxn<LookupOption>();
  final warehouse = Rxn<LookupOption>();
  final lines = <PoLine>[].obs;

  /// A Manager must pick who approves. Admin / Super Admin don't: their
  /// order is approved as soon as it is submitted.
  bool get needsApprover => !can(Perm.poApprove);
  final approvers = <LookupOption>[].obs;
  final approver = Rxn<LookupOption>();

  /// How full the chosen warehouse gets with this order (null until a
  /// warehouse is chosen). Refreshed shortly after the warehouse or any
  /// quantity changes.
  final capacityInfo = Rxn<WarehouseCapacity>();

  /// The form's scroll position and the capacity banner, so a tap on Submit
  /// while the warehouse is full can take the user to the banner explaining why.
  final scrollController = ScrollController();
  final capacityKey = GlobalKey();

  void showCapacityStatus() {
    final context = capacityKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
  Timer? _capacityTimer;
  int _capacityRequest = 0;
  final _watchedLines = <PoLine>{};
  final _lineWatchers = <StreamSubscription<dynamic>>[];

  /// Suppliers the order's products were bought from before (best first),
  /// and how many distinct catalogue products the order has.
  final supplierSuggestions = <SupplierSuggestion>[].obs;
  final suggestionProductCount = 0.obs;
  final _historyCache = <String, SupplierHistory>{};
  Timer? _suggestTimer;
  int _suggestRequest = 0;

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
    ever(lines, (_) => _watchLines());
    ever(warehouse, (_) => _scheduleCapacityCheck());
    _load();
  }

  void _watchLines() {
    for (final l in lines) {
      if (_watchedLines.add(l)) {
        _lineWatchers.add(l.line.enteredQty.listen((_) => _scheduleCapacityCheck()));
        _lineWatchers.add(l.line.product.listen((_) => _scheduleSuggestions()));
      }
    }
    _scheduleCapacityCheck();
    _scheduleSuggestions();
  }

  void _scheduleSuggestions() {
    _suggestTimer?.cancel();
    _suggestTimer = Timer(const Duration(milliseconds: 400), _loadSuggestions);
  }

  /// Looks up who each product on the order was bought from before and
  /// ranks the suppliers: most of the order's products first, then the most
  /// recent order.
  Future<void> _loadSuggestions() async {
    final ids = <String>{
      for (final l in lines)
        if (!l.isNew.value && l.line.product.value?.id != null) l.line.product.value!.id!,
    };
    final request = ++_suggestRequest;
    if (ids.isEmpty) {
      suggestionProductCount.value = 0;
      supplierSuggestions.clear();
      return;
    }
    try {
      for (final id in ids) {
        if (!_historyCache.containsKey(id)) {
          _historyCache[id] = await _service.fetchSupplierHistory(id);
        }
      }
    } on ApiException {
      return;
    }
    if (request != _suggestRequest) return;

    final byCode = <String, SupplierSuggestion>{};
    for (final id in ids) {
      for (final offer in _historyCache[id]!.suppliers) {
        if (!offer.hasHistory && !offer.isDefault) continue;
        final s = byCode.putIfAbsent(offer.code, () => SupplierSuggestion(offer.code, offer.name));
        if (offer.isDefault) s.isDefault = true;
        if (!offer.hasHistory) continue;
        s.products++;
        final at = offer.lastOrderedAt;
        if (at != null && (s.lastOrderedAt == null || at.isAfter(s.lastOrderedAt!))) s.lastOrderedAt = at;
      }
    }
    final list = byCode.values.toList()
      ..sort((a, b) {
        final byCount = b.products.compareTo(a.products);
        if (byCount != 0) return byCount;
        return (b.lastOrderedAt ?? DateTime(0)).compareTo(a.lastOrderedAt ?? DateTime(0));
      });
    suggestionProductCount.value = ids.length;
    supplierSuggestions.assignAll(list.take(3));
  }

  /// Picks a suggested supplier in the form.
  void useSupplier(SupplierSuggestion s) {
    final option = _byCode(suppliers, s.code);
    if (option != null) supplier.value = option;
  }

  void _scheduleCapacityCheck() {
    _capacityTimer?.cancel();
    _capacityTimer = Timer(const Duration(milliseconds: 500), _checkCapacity);
  }

  Future<void> _checkCapacity() async {
    final wh = warehouse.value;
    if (wh == null) {
      capacityInfo.value = null;
      return;
    }
    final quantity = lines.fold<double>(0, (sum, l) => sum + (l.line.enteredQty.value ?? 0));
    final request = ++_capacityRequest;
    try {
      final info = await _service.checkWarehouse(wh.code, quantity, excludeId: original?.id);
      if (request == _capacityRequest) capacityInfo.value = info;
    } on ApiException {
      if (request == _capacityRequest) capacityInfo.value = null;
    }
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _masterData.suppliers(),
        _masterData.warehouses(),
        _masterData.categories(),
        _masterData.brands(),
      ]);
      suppliers.assignAll(results[0]);
      warehouses.assignAll(results[1]);
      categories.assignAll(results[2]);
      brands.assignAll(results[3]);
      if (needsApprover) {
        final list = await _service.fetchApprovers();
        approvers.assignAll([
          for (final a in list) LookupOption(id: a.id, code: a.id, name: a.label),
        ]);
      }
      if (catalog.allItems.isEmpty) await catalog.load();
      _fillFromOriginal();
      _fillFromPrefill();
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
        line.brand.value = _byCode(brands, item.newBrandCode ?? '');
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

  void _fillFromPrefill() {
    final pre = prefill;
    if (pre == null) return;
    if (pre.supplierCode != null) supplier.value = _byCode(suppliers, pre.supplierCode!);
    for (final l in pre.lines) {
      StockItemData? product;
      for (final p in catalog.allItems) {
        if (p.code == l.productCode) product = p;
      }
      if (product == null) continue;
      final line = PoLine();
      line.line.selectProduct(product);
      line.line.quantityController.text = '${l.quantity}';
      if (l.price != null) line.priceController.text = l.price!.toStringAsFixed(2);
      lines.add(line);
    }
  }

  /// Product codes already in the order (existing products only).
  Set<String> get existingCodes => {
        for (final l in lines)
          if (!l.isNew.value && l.line.product.value?.code != null) l.line.product.value!.code!,
      };

  /// Adds the low / out-of-stock products picked in the sheet, each with its
  /// suggested quantity. Returns how many were added and how many were left
  /// out because the app does not have that product loaded.
  ({int added, int skipped}) addReorderItems(List<ReorderItem> picked) {
    final byCode = <String, StockItemData>{
      for (final p in catalog.allItems)
        if ((p.code ?? '').isNotEmpty) p.code!: p,
    };

    // The empty line a new form starts with is replaced by the added ones.
    lines.removeWhere((l) {
      final blank = !l.isNew.value &&
          l.line.product.value == null &&
          l.line.quantityController.text.trim().isEmpty;
      if (blank) l.dispose();
      return blank;
    });

    var added = 0;
    var skipped = 0;
    for (final r in picked) {
      final product = byCode[r.code];
      if (product == null) {
        skipped++;
        continue;
      }
      if (existingCodes.contains(r.code)) continue;
      final line = PoLine();
      line.line.selectProduct(product);
      line.line.quantityController.text = '${r.suggestedQuantity > 0 ? r.suggestedQuantity : 1}';
      lines.add(line);
      added++;
    }

    if (lines.isEmpty) addLine();
    _autoPickSupplier(picked);
    return (added: added, skipped: skipped);
  }

  /// Supplier still empty and every added product has the same usual
  /// supplier -> pick it.
  Future<void> _autoPickSupplier(List<ReorderItem> picked) async {
    if (supplier.value != null || picked.isEmpty) return;
    try {
      final codes = <String?>{};
      for (final r in picked) {
        final history = _historyCache[r.productId] ??= await _service.fetchSupplierHistory(r.productId);
        String? usual;
        for (final o in history.suppliers) {
          if (o.isDefault) usual = o.code;
        }
        codes.add(usual);
      }
      if (supplier.value != null || codes.length != 1 || codes.first == null) return;
      final option = _byCode(suppliers, codes.first!);
      if (option != null) supplier.value = option;
    } on ApiException {
      // Not important: the supplier can still be chosen by hand.
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

  /// Adds the good rows of [preview] as product lines (a product already in the list gets the file's quantity and price).
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
      AppSnackbar.success(
        'menu_purchase_orders'.tr,
        (submit ? (needsApprover ? 'po_submitted_message' : 'po_approved_message') : 'po_saved_message').tr,
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    _capacityTimer?.cancel();
    _suggestTimer?.cancel();
    for (final w in _lineWatchers) {
      w.cancel();
    }
    noteController.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.onClose();
  }
}
