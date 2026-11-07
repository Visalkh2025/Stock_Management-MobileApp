import 'package:get/get.dart';
import 'package:stock_management/Controller/customer_orders_controller.dart';

class CustomerOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerOrdersController>(() => CustomerOrdersController());
  }
}
