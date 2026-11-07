import 'package:get/get.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';

/// Home's "Stock In" header button routes here (Routes.stockIn) — same
class StockInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockMovementController>(() => StockMovementController());
  }
}

/// Home's "Stock Out" header button routes here (Routes.stockOut) — see
/// [StockInBinding].
class StockOutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockMovementController>(() => StockMovementController());
  }
}
