import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/customer_models.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/customer_order_service.dart';

/// One customer: profile, order totals and every order they placed.
/// `Get.arguments` is the customer's id.
class CustomerDetailController extends GetxController {
  final _service = CustomerOrderService();

  // Read once: `Get.arguments` changes while an order is open on top.
  late final String customerId = Get.arguments as String;

  final customer = Rxn<CustomerRow>();
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
      customer.value = await _service.fetchCustomer(customerId);
      orders.assignAll(await _service.fetchOrdersOfCustomer(customerId));
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
}
