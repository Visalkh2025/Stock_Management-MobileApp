import 'package:get/get.dart';
import 'package:stock_management/Controller/customer_order_detail_controller.dart';

class CustomerOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerOrderDetailController>(() => CustomerOrderDetailController());
  }
}
