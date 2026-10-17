import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// More > Purchase Orders — the list of purchase orders from the API, with a
/// status filter. Opening one goes to its detail; "+" starts a new order.
class PurchaseOrdersController extends GetxController {
  final PurchaseOrderService _service = PurchaseOrderService();

  final orders = <PurchaseOrderSummary>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rx<PoStatus?> activeFilter = Rx<PoStatus?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      orders.assignAll(await _service.fetchAll());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  int get totalCount => orders.length;

  int countFor(PoStatus status) => orders.where((o) => o.status == status).length;

  List<PurchaseOrderSummary> get filteredItems {
    final filter = activeFilter.value;
    if (filter == null) return orders.toList();
    return orders.where((o) => o.status == filter).toList();
  }

  void setFilter(PoStatus? status) => activeFilter.value = status;

  Future<void> openOrder(PurchaseOrderSummary order) async {
    await Get.toNamed(Routes.purchaseOrderDetail, arguments: order.id);
    await load();
  }

  Future<void> createOrder() async {
    await Get.toNamed(Routes.purchaseOrderForm);
    await load();
  }
}
