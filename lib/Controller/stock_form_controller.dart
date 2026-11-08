import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/approval_chain.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/Services/request_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// Shared behaviour of the stock-movement forms (Stock In / Stock Out,
abstract class StockFormController extends GetxController {
  final _masterData = MasterDataService();
  final _requests = RequestService();

  final reasonController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// The products being moved — always at least one.
  final lines = <StockLine>[StockLine()].obs;

  /// Every warehouse the person can choose from.
  final warehouses = <LookupOption>[].obs;
  final isLoadingWarehouses = false.obs;

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final chain = ApprovalChain();

  // ------------------------------------------------------------ subclass API

  /// `STOCK_IN`, `STOCK_OUT`, `STOCK_TRANSFER` or `STOCK_ADJUSTMENT`.
  String get requestType;

  /// True when this person must send a request instead of saving directly.
  bool get needsApproval;

  /// True when each line picks its own warehouse (Stock In/Out, Adjust: where
  /// the stock is; Transfer: where it is taken from).
  bool get warehousePerLine => true;

  /// Label of the per-line warehouse picker.
  String get warehouseLabel => 'field_warehouse'.tr;

  /// True when the product is picked BEFORE the warehouse (Stock In/Out,
  /// Adjust), so the warehouse list can follow the product: it shows where
  /// the product is stored now.
  bool get productFirst => false;

  /// The warehouses a line can choose from.
  List<LookupOption> warehouseOptionsFor(StockLine line) => warehouses;

  /// The warehouses (with their quantity) where the line's product is
  /// stored now, as picker options.
  List<(LookupOption, int)> storedWarehouses(StockLine line, {bool inStockOnly = false}) {
    final result = <(LookupOption, int)>[];
    for (final s in line.stocks) {
      if (inStockOnly && s.quantity <= 0) continue;
      for (final w in warehouses) {
        if (w.code == s.warehouseCode) {
          result.add((w, s.quantity));
          break;
        }
      }
    }
    return result;
  }

  /// Picks a product for [line] and keeps its warehouse in step.
  void pickProduct(StockLine line, StockItemData item) {
    line.selectProduct(item);
    syncWarehouse(line);
  }

  /// After the product or variant changes: drop a warehouse the product can't
  /// use, and fill it in when the product is stored in exactly one place.
  void syncWarehouse(StockLine line) {
    if (!productFirst) return;
    final options = warehouseOptionsFor(line);
    final current = line.warehouse.value;
    if (current != null && !options.contains(current)) line.warehouse.value = null;
    if (line.warehouse.value == null) {
      final stored = storedWarehouses(line);
      if (stored.length == 1 && options.contains(stored.first.$1)) line.warehouse.value = stored.first.$1;
    }
  }

  /// The warehouse this line's units go INTO (Stock In, Transfer destination,
  /// Adjust increase); null when the line only takes stock out.
  LookupOption? incomingWarehouseOf(StockLine line) => null;

  /// Units going into each warehouse (by code), summed over the lines.
  /// Reads the lines' fields, so a widget using it rebuilds as they change.
  Map<String, double> get incomingTotals {
    final totals = <String, double>{};
    for (final line in lines) {
      final warehouse = incomingWarehouseOf(line);
      final qty = line.enteredQty.value;
      if (warehouse == null || qty == null || qty <= 0) continue;
      totals[warehouse.code] = (totals[warehouse.code] ?? 0.0) + qty;
    }
    return totals;
  }

  final _capacityChecks = <String, Future<WarehouseCapacity?>>{};

  /// How full [code] gets with [quantity] more units (null if it can't be
  /// checked: the save is still checked by the server). Waits a moment so
  /// typing a number does not ask the server for every digit.
  Future<WarehouseCapacity?> capacityFor(String code, double quantity) {
    return _capacityChecks.putIfAbsent('$code|$quantity', () async {
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        return await _masterData.capacityCheck(code, quantity);
      } catch (_) {
        return null;
      }
    });
  }

  String warehouseNameOf(String code) {
    for (final w in warehouses) {
      if (w.code == code) return w.name;
    }
    return code;
  }

  /// The warehouse this line's stock is in (for Transfer: taken from).
  LookupOption? warehouseOf(StockLine line) => line.warehouse.value;

  /// True when this line takes stock out of its warehouse, so only products
  /// that are in stock there make sense to pick.
  bool requiresStock(StockLine line) => false;

  /// Adjust only: each line has its own Increase / Decrease toggle.
  bool get perLineDirection => false;

  /// `{'stock': [...]}` or `{'adjustments': [...]}` for `POST /requests`,
  /// one row per line. Use [StockLine.baseRow] for the product part of a row.
  Map<String, List<Map<String, dynamic>>> buildRequestBody();

  /// The direct save of ONE line, called only when [needsApproval] is false.
  Future<void> submitDirectLine(StockLine line);

  /// Extra rule a subclass wants checked on each line; null = fine.
  String? validateLine(StockLine line) => null;

  /// The stats shown under a line's quantity; null = nothing yet.
  LineImpact? impactOf(StockLine line) => null;

  /// Snackbar text after a direct save.
  String get savedMessage => 'stock_saved_message'.tr;

  // ----------------------------------------------------------------- lifecycle

  /// Set by the Scan screen right before it opens a stock form, so the first
  /// line starts with the scanned product already chosen. Consumed (and
  /// cleared) by the next form that opens.
  static StockItemData? pendingProduct;

  @override
  void onInit() {
    super.onInit();
    final preselected = pendingProduct;
    pendingProduct = null;
    loadWarehouses().then((_) {
      if (preselected != null && lines.isNotEmpty && lines.first.product.value == null) {
        pickProduct(lines.first, preselected);
      }
    });
    if (needsApproval) {
      chain.start().then((_) => errorMessage.value ??= chain.loadError.value);
    }
  }

  Future<void> loadWarehouses() async {
    isLoadingWarehouses.value = true;
    try {
      warehouses.assignAll(await _masterData.warehouses());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoadingWarehouses.value = false;
    }
  }

  StockController get catalog {
    if (Get.isRegistered<StockController>()) return Get.find<StockController>();
    return Get.put(StockController(), permanent: true);
  }

  // -------------------------------------------------------------------- lines

  /// A new line starts in the same warehouse as the last one — products are
  /// usually added in batches from one place.
  void addLine() {
    final line = StockLine();
    if (warehousePerLine && lines.isNotEmpty) line.warehouse.value = lines.last.warehouse.value;
    lines.add(line);
  }

  void removeLine(StockLine line) {
    if (lines.length <= 1) return;
    lines.remove(line);
    line.dispose();
  }

  // ---------------------------------------------------------------- validators

  String? requiredText(String? v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null;

  /// Quantity must be a whole number of at least 1.
  String? quantityValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'validation_required'.tr;
    final qty = int.tryParse(text);
    if (qty == null || qty < 1) return 'validation_qty_min'.tr;
    return null;
  }

  // ---------------------------------------------------------------------- save

  Future<void> save() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final seen = <String>{};
    for (final line in lines) {
      final product = line.product.value;
      if (product == null || (product.code ?? '').isEmpty) {
        errorMessage.value = 'validation_product_not_found'.tr;
        return;
      }
      if (warehouseOf(line) == null) {
        errorMessage.value = 'validation_select_required'.tr;
        return;
      }
      if (line.needsVariant && line.variant.value == null) {
        errorMessage.value = 'validation_variant_required'.tr;
        return;
      }
      if (!seen.add('${product.code}|${line.variant.value?.code ?? ''}')) {
        errorMessage.value = 'validation_duplicate_product'.trParams({'name': line.displayName});
        return;
      }
      final extra = validateLine(line);
      if (extra != null) {
        errorMessage.value = lines.length > 1 ? '${line.displayName}: $extra' : extra;
        return;
      }
    }
    if (needsApproval) {
      final chainError = chain.error;
      if (chainError != null) {
        errorMessage.value = chainError;
        return;
      }
    }

    isSaving.value = true;
    try {
      if (needsApproval) {
        final body = buildRequestBody();
        await _requests.createStockRequest(
          requestType: requestType,
          stock: body['stock'] ?? const [],
          adjustments: body['adjustments'] ?? const [],
          approvers: chain.toPayload(),
        );
        if (!Get.isRegistered<RequestController>()) {
          Get.put(RequestController(), permanent: true);
        } else {
          await Get.find<RequestController>().load();
        }
        Get.offNamed(Routes.requests);
        AppSnackbar.success('nav_requests'.tr, 'stock_request_sent_message'.tr);
      } else {
        await _saveDirectly();
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  /// The direct path saves one line at a time (the API takes one product per call), so it can stop half way.
  Future<void> _saveDirectly() async {
    final all = List<StockLine>.of(lines);
    final saved = <StockLine>[];
    String? failure;
    for (final line in all) {
      try {
        await submitDirectLine(line);
        saved.add(line);
      } on ApiException catch (e) {
        failure = all.length > 1 ? '${line.displayName}: ${e.message}' : e.message;
        break;
      }
    }

    if (saved.isNotEmpty) {
      await catalog.load();
    }

    if (failure == null) {
      Get.back();
      AppSnackbar.success('nav_stock'.tr, savedMessage);
      return;
    }

    for (final line in saved) {
      lines.remove(line);
      line.dispose();
    }
    errorMessage.value = saved.isEmpty
        ? failure
        : '${'stock_partial_saved'.trParams({'done': '${saved.length}', 'total': '${all.length}'})}\n$failure';
  }

  /// Shared by Stock In/Out and Adjust for the direct path.
  Future<void> adjustDirect(StockLine line, {required bool increase, required String reason, String? movementType}) {
    return ProductService().adjustStock(
      productCode: line.product.value!.code!,
      variantCode: line.variant.value?.code,
      warehouseCode: warehouseOf(line)!.code,
      quantity: line.enteredQty.value!,
      increase: increase,
      reason: reason,
      movementType: movementType,
    );
  }

  @override
  void onClose() {
    reasonController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.onClose();
  }
}
