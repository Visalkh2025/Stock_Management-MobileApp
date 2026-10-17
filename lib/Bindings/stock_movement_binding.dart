import 'package:get/get.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';

/// Home's "Stock In" header button routes here (Routes.stockIn) — same
/// [StockMovementScreen] as Stock Out; HomeController.stockIn() passes the
/// direction via Get.arguments, so this binding no longer needs to (that
/// also means it and StockOutBinding aren't registering the same
/// GetxController type two different, conflicting ways).
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
