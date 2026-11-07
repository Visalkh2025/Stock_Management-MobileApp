import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// Purchase Orders > Needs reorder — products that are out of stock or at /
/// below their minimum. Opening one goes to the supplier comparison.
class ReorderController extends GetxController {
  final _service = PurchaseOrderService();

  final summary = Rxn<ReorderSummary>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  /// 'all' | 'out' | 'low'
  final filter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      summary.value = await _service.fetchReorder();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  List<ReorderItem> get items {
    final all = summary.value?.items ?? const <ReorderItem>[];
    switch (filter.value) {
      case 'out':
        return all.where((i) => i.isOut).toList();
      case 'low':
        return all.where((i) => !i.isOut).toList();
      default:
        return all.toList();
    }
  }

  void setFilter(String value) => filter.value = value;

  Future<void> openItem(ReorderItem item) async {
    await Get.toNamed(Routes.supplierCompare, arguments: item);
    await load();
  }
}
