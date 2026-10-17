import 'package:get/get.dart';
import 'package:stock_management/Controller/request_controller.dart';

class RequestBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: Requests is a bottom-nav tab — see StockBinding for why tab
    // controllers must survive tab switches instead of being disposed.
    if (!Get.isRegistered<RequestController>()) {
      Get.put<RequestController>(RequestController(), permanent: true);
    }
  }
}
