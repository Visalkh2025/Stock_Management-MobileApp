import 'package:get/get.dart';
import 'package:stock_management/Controller/stock_history_controller.dart';

class StockHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockHistoryController>(() => StockHistoryController());
  }
}
