import 'package:get/get.dart';
import 'package:stock_management/Controller/reorder_controller.dart';

class ReorderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReorderController>(() => ReorderController());
  }
}
