import 'package:get/get.dart';
import 'package:stock_management/Controller/more_controller.dart';

class MoreBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: More is a bottom-nav tab — see StockBinding for why tab
    // controllers must survive tab switches instead of being disposed.
    if (!Get.isRegistered<MoreController>()) {
      Get.put<MoreController>(MoreController(), permanent: true);
    }
  }
}
