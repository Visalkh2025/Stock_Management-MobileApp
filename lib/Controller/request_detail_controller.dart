import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/request_service.dart';

/// One request. Approve/Reject go to `POST /requests/:id/commit`; the
/// server only lets the assigned approver whose turn it is act, and tells
/// the app so through `canAct` — the buttons follow that flag.
class RequestDetailController extends GetxController {
  final _service = RequestService();

  late final Rx<RequestItemData> _request = Rx<RequestItemData>(Get.arguments as RequestItemData);

  RequestItemData get request => _request.value;

  final isBusy = false.obs;
  final errorMessage = RxnString();

  bool get isPending => request.status == RequestStatus.pending;

  /// True only when the server says it is the signed-in user's turn.
  bool get canAct => isPending && request.canAct;

  @override
  void onInit() {
    super.onInit();
    // The list row may be stale (someone else may have acted meanwhile).
    reload();
  }

  Future<void> reload() async {
    final id = request.id;
    if (id == null) return;
    final fresh = await _requests.refreshOne(id);
    if (fresh != null) _request.value = fresh;
  }

  RequestController get _requests {
    if (!Get.isRegistered<RequestController>()) {
      Get.put(RequestController(), permanent: true);
    }
    return Get.find<RequestController>();
  }

  Future<void> approve() => _decide(approve: true, message: 'snackbar_request_approved'.tr);

  Future<void> reject(String reason) => _decide(approve: false, message: 'snackbar_request_rejected'.tr, reason: reason);

  Future<void> _decide({required bool approve, required String message, String? reason}) async {
    final id = request.id;
    if (id == null || isBusy.value) return;
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await _service.commit(id, approve: approve, remark: reason);
      await _requests.load();
      // Approving a product request creates the product — refresh Stock.
      if (Get.isRegistered<StockController>()) {
        await Get.find<StockController>().load();
      }
      Get.back();
      Get.snackbar(
        message,
        '${request.requestId} • ${request.typeLabel}',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      await reload();
    } finally {
      isBusy.value = false;
    }
  }
}
