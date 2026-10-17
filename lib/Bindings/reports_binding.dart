import 'package:get/get.dart';
import 'package:stock_management/Controller/reports_controller.dart';

/// More > Reports routes here (Routes.reports).
class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportsController>(() => ReportsController());
  }
}
