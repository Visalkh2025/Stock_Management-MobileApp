import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// How a counted quantity compares with what was still to come.
enum ReceiveMatch { uncounted, match, short, over }

/// Goods receiving for one purchase order (`Get.arguments` is its
/// [PurchaseOrderDetail]). The fields start EMPTY on purpose: the person
/// counts what actually arrived and types it in (0 if none), and each line
/// shows at once whether it matches the order, is short, or is over. Confirm
/// once; the server then records the receipt and adds the stock.
class GoodsReceivingController extends GetxController {
  final _service = PurchaseOrderService();

  PurchaseOrderDetail get order => Get.arguments as PurchaseOrderDetail;

  /// Lines that still have something to receive, with the field for each.
  late final List<PurchaseOrderItemData> items =
      order.items.where((i) => i.remainingQuantity > 0).toList();
  late final Map<String, TextEditingController> fields = {
    for (final i in items) i.id: TextEditingController(),
  };

  /// The number typed in each field (null while empty / not a number).
  final Map<String, RxnDouble> entered = {};

  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    for (final item in items) {
      final value = RxnDouble();
      entered[item.id] = value;
      final field = fields[item.id]!;
      field.addListener(() => value.value = double.tryParse(field.text.trim().replaceAll(',', '')));
    }
  }

  ReceiveMatch matchOf(PurchaseOrderItemData item) {
    final value = entered[item.id]?.value;
    if (value == null) return ReceiveMatch.uncounted;
    final diff = value - item.remainingQuantity;
    if (diff.abs() < 0.0005) return ReceiveMatch.match;
    return diff < 0 ? ReceiveMatch.short : ReceiveMatch.over;
  }

  /// How far the count is from the order (positive = short, negative = over).
  double gapOf(PurchaseOrderItemData item) => item.remainingQuantity - (entered[item.id]?.value ?? 0);

  int countOf(ReceiveMatch kind) => items.where((i) => matchOf(i) == kind).length;

  /// Every line must be counted (0 is fine: it did not arrive); more than is
  /// still to come is not allowed.
  String? validator(PurchaseOrderItemData item, String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'validation_required'.tr;
    final n = double.tryParse(text.replaceAll(',', ''));
    if (n == null || n < 0) return 'validation_quantity_invalid'.tr;
    if (n > item.remainingQuantity) {
      return 'po_receive_too_many'.trParams({'max': formatQty(item.remainingQuantity)});
    }
    return null;
  }

  Future<void> confirm() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) {
      errorMessage.value = 'po_receive_count_all'.tr;
      return;
    }

    final rows = [
      for (final i in items)
        if ((entered[i.id]?.value ?? 0) > 0) {'itemId': i.id, 'quantity': entered[i.id]!.value},
    ];
    if (rows.isEmpty) {
      errorMessage.value = 'po_receive_nothing'.tr;
      return;
    }

    isSaving.value = true;
    try {
      await _service.receive(order.id, items: rows, note: noteController.text);
      Get.back();
      Get.snackbar(
        'po_receiving_title'.tr,
        'po_received_message'.tr,
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
    for (final c in fields.values) {
      c.dispose();
    }
    noteController.dispose();
    super.onClose();
  }
}
