import 'package:get/get.dart';
import 'package:stock_management/Controller/master_items_controller.dart';

class MasterItemsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterItemsController>(() => MasterItemsController());
  }
}
