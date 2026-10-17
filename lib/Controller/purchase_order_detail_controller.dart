import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';
import 'package:stock_management/View/PurchaseOrders/po_approver_dialog.dart';
import 'package:stock_management/View/PurchaseOrders/po_reject_dialog.dart';

/// One purchase order and the actions its status allows. `Get.arguments` is
/// the order's id.
class PurchaseOrderDetailController extends GetxController {
  final _service = PurchaseOrderService();

  String get orderId => Get.arguments as String;

  final order = Rxn<PurchaseOrderDetail>();
  final isLoading = false.obs;
  final isBusy = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      order.value = await _service.fetchOne(orderId);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // What the signed-in person may do right now (the API still enforces it).
  bool get canEdit => (order.value?.status.isEditable ?? false) && can(Perm.poCreate);
  /// An order sent to one person is decided by that person (or a Super Admin).
  bool get canDecide {
    final o = order.value;
    if (o == null || o.status != PoStatus.submitted || !can(Perm.poApprove)) return false;
    if (o.approverId == null) return true;
    final me = Get.find<ProfileController>();
    return o.approverId == me.userId || me.isSuperAdmin;
  }
  bool get canReceive => (order.value?.status.canReceive ?? false) && can(Perm.poReceive);

  bool get hasPendingCatalog => (order.value?.pendingCatalogCount ?? 0) > 0;
  /// Lines already marked as added: the manager can still re-export them.
  bool get hasAddedCatalog => !hasPendingCatalog && (order.value?.items.any((i) => i.catalogAdded) ?? false);
  bool get canExport => (hasPendingCatalog || hasAddedCatalog) && can(Perm.poView);
  bool get canMarkCatalogAdded => hasPendingCatalog && can(Perm.poCreate);

  /// Saves the Add Product import Excel (received new products) to the phone.
  Future<void> exportPending() async {
    final current = order.value;
    if (current == null) return;
    errorMessage.value = null;
    isBusy.value = true;
    try {
      final bytes = await _service.exportPendingProducts(orderId);
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'po_action_export_products'.tr,
        fileName: '${current.poNumber}_new_products.xlsx',
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (saved != null) {
        Get.snackbar('po_action_export_products'.tr, 'po_export_saved'.tr, snackPosition: SnackPosition.BOTTOM);
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> markCatalogAdded() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('po_action_mark_added'.tr),
        content: Text('po_mark_added_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('action_cancel'.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text('po_action_mark_added'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => _service.markCatalogAdded(orderId));
  }

  Future<void> _run(Future<void> Function() action) async {
    errorMessage.value = null;
    isBusy.value = true;
    try {
      await action();
      order.value = await _service.fetchOne(orderId);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isBusy.value = false;
    }
  }

  /// A Manager picks who approves; an Admin / Super Admin's order is approved
  /// straight away, so nobody needs to be picked.
  Future<void> submit() async {
    String? approverId;
    if (!can(Perm.poApprove)) {
      approverId = await Get.dialog<String>(const PoApproverDialog());
      if (approverId == null) return;
    }
    await _run(() => _service.submit(orderId, approverId: approverId));
  }

  Future<void> approve() => _run(() => _service.approve(orderId));

  Future<void> reject() async {
    final reason = await _askReason();
    if (reason == null) return;
    await _run(() => _service.reject(orderId, reason));
  }

  Future<void> edit() async {
    final current = order.value;
    if (current == null) return;
    await Get.toNamed(Routes.purchaseOrderForm, arguments: current);
    await load();
  }

  Future<void> receive() async {
    final current = order.value;
    if (current == null) return;
    await Get.toNamed(Routes.goodsReceiving, arguments: current);
    await load();
  }

  Future<String?> _askReason() => Get.dialog<String>(const PoRejectDialog());
}
