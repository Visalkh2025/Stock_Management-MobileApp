import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/customer_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/customer_order_service.dart';

/// More > Customers — everyone registered through the Mini App, with a status
/// filter and a search box. Opening one goes to their profile and orders.
class CustomersController extends GetxController {
  final CustomerOrderService _service = CustomerOrderService();

  final customers = <CustomerRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rx<CustomerStatus?> activeFilter = Rx<CustomerStatus?>(null);
  final searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      customers.assignAll(await _service.fetchCustomers());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  bool _matchesSearch(CustomerRow c) {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.title.toLowerCase().contains(q) ||
        (c.company ?? '').toLowerCase().contains(q) ||
        (c.phone ?? '').toLowerCase().contains(q) ||
        c.telegramAccounts.any((t) => t.toLowerCase().contains(q)) ||
        (c.address ?? '').toLowerCase().contains(q);
  }

  /// Customers matching the search (before the status filter), so each chip's count reflects it.
  List<CustomerRow> get _scoped => customers.where(_matchesSearch).toList();

  int get totalCount => _scoped.length;

  int countFor(CustomerStatus status) => _scoped.where((c) => c.status == status).length;

  List<CustomerRow> get filteredItems {
    final filter = activeFilter.value;
    final scoped = _scoped;
    if (filter == null) return scoped;
    return scoped.where((c) => c.status == filter).toList();
  }

  void setFilter(CustomerStatus? status) => activeFilter.value = status;

  void setSearch(String value) => searchText.value = value;

  Future<void> openCustomer(CustomerRow customer) => Get.toNamed(Routes.customerDetail, arguments: customer.id);
}
