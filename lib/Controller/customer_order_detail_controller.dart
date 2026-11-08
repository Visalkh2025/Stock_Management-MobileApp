import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/customer_order_service.dart';
import 'package:stock_management/Services/order_watcher.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';
import 'package:stock_management/View/CustomerOrders/co_dialogs.dart';

/// One customer order and the actions its status allows. `Get.arguments` is
/// the order's id.
class CustomerOrderDetailController extends GetxController {
  final _service = CustomerOrderService();

  String get orderId => Get.arguments as String;

  final order = Rxn<CustomerOrderDetail>();
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
      OrderWatcher.instance.markSeen([orderId]);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  // What can be done right now (the API still enforces the rules).
  CoStatus? get status => order.value?.status;
  bool get canDecide => status == CoStatus.pendingReview;
  bool get canMarkPaid {
    final o = order.value;
    if (o == null || o.isPaid) return false;
    return o.status == CoStatus.confirmed ||
        o.status == CoStatus.processing ||
        o.status == CoStatus.outForDelivery ||
        o.status == CoStatus.delivered;
  }

  bool get canProcess => status == CoStatus.confirmed;
  bool get canDeliver => status == CoStatus.processing;
  bool get canMarkDelivered => status == CoStatus.outForDelivery;

  /// Delivered and paid, but not closed yet.
  bool get canComplete {
    final o = order.value;
    return o != null && o.status == CoStatus.delivered && o.isPaid;
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

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('action_cancel'.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> accept() async {
    if (!await _confirm('co_accept_title'.tr, 'co_accept_message'.tr, 'co_action_accept'.tr)) return;
    await _run(() => _service.accept(orderId));
  }

  Future<void> reject() async {
    final reason = await Get.dialog<String>(const CoReasonDialog());
    if (reason == null) return;
    await _run(() => _service.reject(orderId, reason));
  }

  Future<void> markPaid() async {
    final current = order.value;
    if (current == null) return;
    final result = await Get.dialog<CoPaymentResult>(CoPaymentDialog(total: current.totalAmount));
    if (result == null) return;
    await _run(() => _service.recordPayment(orderId, result.amount, remark: result.remark, proof: result.proof));
  }

  Future<void> process() => _run(() => _service.process(orderId));

  Future<void> outForDelivery() async {
    if (!await _confirm('co_out_title'.tr, 'co_out_message'.tr, 'co_action_out'.tr)) return;
    await _run(() => _service.outForDelivery(orderId));
  }

  Future<void> delivered() async {
    if (!await _confirm('co_delivered_title'.tr, 'co_delivered_message'.tr, 'co_action_delivered'.tr)) return;
    await _run(() => _service.delivered(orderId));
  }

  Future<void> complete() => _run(() => _service.complete(orderId));

  /// No phone-call package in the app yet: copy the number so it can be pasted
  /// into the dialer.
  Future<void> copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    AppSnackbar.success('co_phone_copied'.tr, phone);
  }
}
