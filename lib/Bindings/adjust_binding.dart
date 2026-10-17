import 'package:get/get.dart';
import 'package:stock_management/Controller/adjust_controller.dart';

/// Home's "Adjust" quick action routes here (Routes.adjust).
class AdjustBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdjustController>(() => AdjustController());
  }
}
