import 'package:get/get.dart';
import 'package:stock_management/Controller/request_detail_controller.dart';

class RequestDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RequestDetailController>(() => RequestDetailController());
  }
}
