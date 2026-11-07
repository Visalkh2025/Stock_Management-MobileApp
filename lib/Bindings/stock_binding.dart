import 'package:get/get.dart';
import 'package:stock_management/Controller/stock_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: Stock is a bottom-nav tab, not a one-off route.
    if (!Get.isRegistered<StockController>()) {
      Get.put<StockController>(StockController(), permanent: true);
    } else {
      // Coming back to the tab: pick up newly added products.
      Get.find<StockController>().load();
    }
  }
}
