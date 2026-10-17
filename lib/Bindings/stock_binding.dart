import 'package:get/get.dart';
import 'package:stock_management/Controller/stock_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: Stock is a bottom-nav tab, not a one-off route. Switching
    // tabs must never dispose it — StockController owns a TextEditingController
    // + FocusNode for the search field, and disposing them mid-navigation
    // (while the field could still be receiving input) is what was crashing
    // with "A TextEditingController was used after being disposed."
    if (!Get.isRegistered<StockController>()) {
      Get.put<StockController>(StockController(), permanent: true);
    }
  }
}
