import 'package:get/get.dart';
import 'package:stock_management/Controller/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: Home is a bottom-nav tab — see StockBinding for why tab
    // controllers must survive tab switches instead of being disposed.
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(HomeController(), permanent: true);
    }
  }
}
