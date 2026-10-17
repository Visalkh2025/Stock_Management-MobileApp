import 'package:get/get.dart';
import 'package:stock_management/Controller/transfer_controller.dart';

/// Home's "Transfer" quick action routes here (Routes.transfer).
class TransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransferController>(() => TransferController());
  }
}
