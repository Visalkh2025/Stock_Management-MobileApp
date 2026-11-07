import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';

/// More > Purchase Orders — the list of purchase orders from the API, with a
/// status filter. Opening one goes to its detail; "+" starts a new order.
class PurchaseOrdersController extends GetxController {
  final PurchaseOrderService _service = PurchaseOrderService();

  final orders = <PurchaseOrderSummary>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rx<PoStatus?> activeFilter = Rx<PoStatus?>(null);

  /// Filters the list by the date the order was created.
  final dateFilter = const DateFilter().obs;

  /// Products out of stock / low on stock (shown as a banner for people who
  /// can create orders).
  final reorderOut = 0.obs;
  final reorderLow = 0.obs;
  bool get hasReorder => reorderOut.value + reorderLow.value > 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      orders.assignAll(await _service.fetchAll(from: dateFilter.value.fromParam, to: dateFilter.value.toParam));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
    await _loadReorder();
  }

  /// The banner is a convenience: a failure here must not break the list.
  Future<void> _loadReorder() async {
    if (!can(Perm.poCreate)) return;
    try {
      final summary = await _service.fetchReorder();
      reorderOut.value = summary.outCount;
      reorderLow.value = summary.lowCount;
    } catch (_) {
      reorderOut.value = 0;
      reorderLow.value = 0;
    }
  }

  Future<void> openReorder() async {
    await Get.toNamed(Routes.reorder);
    await load();
  }

  int get totalCount => orders.length;

  int countFor(PoStatus status) => orders.where((o) => o.status == status).length;

  List<PurchaseOrderSummary> get filteredItems {
    final filter = activeFilter.value;
    if (filter == null) return orders.toList();
    return orders.where((o) => o.status == filter).toList();
  }

  void setFilter(PoStatus? status) => activeFilter.value = status;

  void setDateFilter(DateFilter value) {
    dateFilter.value = value;
    load();
  }

  Future<void> openOrder(PurchaseOrderSummary order) async {
    await Get.toNamed(Routes.purchaseOrderDetail, arguments: order.id);
    await load();
  }

  Future<void> createOrder() async {
    await Get.toNamed(Routes.purchaseOrderForm);
    await load();
  }
}
