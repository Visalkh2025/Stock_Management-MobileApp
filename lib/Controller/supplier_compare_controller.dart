import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// Compare the suppliers a low / out-of-stock product was bought from, then
/// start a purchase order with the chosen one. `Get.arguments` is the
/// [ReorderItem].
class SupplierCompareController extends GetxController {
  final _service = PurchaseOrderService();

  // Read once: `Get.arguments` changes while the order form is open on top.
  late final ReorderItem item = Get.arguments as ReorderItem;

  final history = Rxn<SupplierHistory>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final quantityController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    quantityController.text = '${item.suggestedQuantity > 0 ? item.suggestedQuantity : 1}';
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      history.value = await _service.fetchSupplierHistory(item.productId);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  List<SupplierOffer> get offers => history.value?.suppliers ?? const [];

  // A tag only means something when there is someone to compare with.
  List<SupplierOffer> get _withHistory => offers.where((o) => o.hasHistory).toList();

  String? get bestPriceCode {
    final list = _withHistory;
    if (list.length < 2) return null;
    final best = list.reduce((a, b) => b.lastPrice < a.lastPrice ? b : a);
    return list.where((o) => o.lastPrice == best.lastPrice).length == 1 ? best.code : null;
  }

  String? get fastestCode {
    final list = _withHistory.where((o) => o.averageLeadDays != null).toList();
    if (list.length < 2) return null;
    final best = list.reduce((a, b) => b.averageLeadDays! < a.averageLeadDays! ? b : a);
    return list.where((o) => o.averageLeadDays == best.averageLeadDays).length == 1 ? best.code : null;
  }

  String? get mostOrderedCode {
    final list = _withHistory;
    if (list.length < 2) return null;
    final best = list.reduce((a, b) => b.timesOrdered > a.timesOrdered ? b : a);
    return list.where((o) => o.timesOrdered == best.timesOrdered).length == 1 ? best.code : null;
  }

  /// Opens the new-order form with this product (and [offer]'s supplier and
  /// last price) filled in. [offer] null = choose the supplier in the form.
  Future<void> createOrder(SupplierOffer? offer) async {
    final quantity = int.tryParse(quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      errorMessage.value = 'validation_quantity_min'.tr;
      return;
    }
    errorMessage.value = null;
    await Get.toNamed(
      Routes.purchaseOrderForm,
      arguments: PoPrefill(
        supplierCode: offer?.code,
        lines: [PoPrefillLine(productCode: item.code, quantity: quantity, price: offer?.lastPrice)],
      ),
    );
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}
