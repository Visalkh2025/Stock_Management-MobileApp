import 'package:get/get.dart';
import 'package:stock_management/Controller/customer_detail_controller.dart';
import 'package:stock_management/Controller/customers_controller.dart';

class CustomersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomersController>(() => CustomersController());
  }
}

class CustomerDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerDetailController>(() => CustomerDetailController());
  }
}
