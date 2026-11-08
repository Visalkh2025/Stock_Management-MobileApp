import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/customer_order_service.dart';
import 'package:stock_management/Services/order_watcher.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';

/// More > Customer Orders — every customer order with a status filter, a date
/// filter and a search box. Opening one goes to its detail.
class CustomerOrdersController extends GetxController {
  final CustomerOrderService _service = CustomerOrderService();

  final orders = <CustomerOrderSummary>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rx<CoStatus?> activeFilter = Rx<CoStatus?>(null);
  final searchText = ''.obs;

  /// Filters the list by the date the order was placed. Applied here (not by
  /// the API), so the status counts always match what is shown.
  final dateFilter = const DateFilter().obs;

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
      // The orders waiting for review are in front of you now: the bell number drops.
      OrderWatcher.instance.markSeen(orders.where((o) => o.status == CoStatus.pendingReview).map((o) => o.id));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      // An unexpected reply from the server: show it instead of an empty list.
      errorMessage.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  bool _matchesSearch(CustomerOrderSummary o) {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return o.orderNo.toLowerCase().contains(q) ||
        o.customer.title.toLowerCase().contains(q) ||
        (o.customer.company ?? '').toLowerCase().contains(q) ||
        (o.customer.phone ?? '').toLowerCase().contains(q);
  }

  /// Orders inside the date range and matching the search (before the status
  /// filter), so each chip's count reflects them.
  List<CustomerOrderSummary> get _scoped => orders.where((o) {
        final created = o.createdAt;
        final inDates = created == null ? !dateFilter.value.isActive : dateFilter.value.contains(created);
        return inDates && _matchesSearch(o);
      }).toList();

  int get totalCount => _scoped.length;

  int countFor(CoStatus status) => _scoped.where((o) => o.status == status).length;

  /// Orders waiting for a staff decision — the number to watch.
  int get pendingCount => orders.where((o) => o.status == CoStatus.pendingReview).length;

  List<CustomerOrderSummary> get filteredItems {
    final filter = activeFilter.value;
    final scoped = _scoped;
    if (filter == null) return scoped;
    return scoped.where((o) => o.status == filter).toList();
  }

  void setFilter(CoStatus? status) => activeFilter.value = status;

  void setDateFilter(DateFilter value) => dateFilter.value = value;

  void setSearch(String value) => searchText.value = value;

  Future<void> openOrder(CustomerOrderSummary order) async {
    await Get.toNamed(Routes.customerOrderDetail, arguments: order.id);
    await load();
  }
}
