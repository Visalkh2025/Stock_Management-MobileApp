import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/customer_order_service.dart';
import 'package:stock_management/Services/order_watcher.dart';

/// Home > bell — customer orders (Mini App or staff) waiting for a decision.
/// Newest first. Opening one goes to its detail, where it is accepted/rejected.
class NotificationsController extends GetxController {
  final CustomerOrderService _service = CustomerOrderService();

  final orders = <CustomerOrderSummary>[].obs;
  final isLoading = false.obs;
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
      orders.assignAll(await _service.fetchPending());
      // Having them in front of you counts as seeing them: the bell number drops.
      OrderWatcher.instance.markSeen(orders.map((o) => o.id));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openOrder(CustomerOrderSummary order) async {
    await Get.toNamed(Routes.customerOrderDetail, arguments: order.id);
    await load();
  }

  void openAllOrders() => Get.toNamed(Routes.customerOrders);
}
