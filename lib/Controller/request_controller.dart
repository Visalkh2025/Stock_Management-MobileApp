import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/request_service.dart';

/// The Requests tab. Product requests come from the server
/// (`GET /requests`); the flows that are not wired to the API yet
/// (transfer, adjustment, stock in/out, purchase order) still drop
/// local-only rows into [_local] so those screens keep working as demos.
class RequestController extends GetxController {
  final _service = RequestService();
  final _masterData = MasterDataService();

  // null = "All" — no status filter applied. Defaults to All.
  final Rx<RequestStatus?> activeFilter = Rx<RequestStatus?>(null);

  final _remote = <RequestItemData>[].obs;
  final _local = <RequestItemData>[].obs;

  final isLoading = false.obs;
  final errorMessage = RxnString();

  RequestLookups _lookups = const RequestLookups();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<RequestItemData> get _items => [..._local, ..._remote];

  int get totalCount => _items.length;

  /// Unlike [filteredItems], ignores [activeFilter] — for a screen with its
  /// own independent filter over the same underlying list (e.g. Purchase
  /// Orders, which shows only typeLabel == 'Purchase Order' rows and must
  /// not be affected by whatever status filter the Requests tab is on).
  List<RequestItemData> get allItems => _items;

  int countFor(RequestStatus status) => _items.where((item) => item.status == status).length;

  List<RequestItemData> get filteredItems {
    final filter = activeFilter.value;
    final items = _items;
    if (filter == null) return items;
    return items.where((item) => item.status == filter).toList();
  }

  void setFilter(RequestStatus? status) => activeFilter.value = status;

  /// Loads every request the server returns, plus the names for the codes
  /// (category, brand, ...) a request stores.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([_service.fetchAll(), _loadLookups()]);
      final rows = results[0] as List<Map<String, dynamic>>;
      _lookups = results[1] as RequestLookups;
      _remote.assignAll(rows.map((json) => RequestItemData.fromJson(json, _lookups)));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-reads one request (fresh approver chain / canAct) and swaps it into
  /// the list. Returns the fresh row, or null when it could not be loaded.
  Future<RequestItemData?> refreshOne(String id) async {
    try {
      final json = await _service.fetchOne(id);
      final fresh = RequestItemData.fromJson(json, _lookups);
      final index = _remote.indexWhere((item) => item.id == id);
      if (index == -1) {
        _remote.insert(0, fresh);
      } else {
        _remote[index] = fresh;
      }
      return fresh;
    } on ApiException {
      return null;
    }
  }

  Future<RequestLookups> _loadLookups() async {
    Future<Map<String, String>> names(Future<List<LookupOption>> request) async {
      try {
        final options = await request;
        return {for (final o in options) o.code: o.name};
      } on ApiException {
        return const {};
      }
    }

    final results = await Future.wait([
      names(_masterData.categories()),
      names(_masterData.brands()),
      names(_masterData.suppliers()),
      names(_masterData.warehouses()),
    ]);
    return RequestLookups(
      categories: results[0],
      brands: results[1],
      suppliers: results[2],
      warehouses: results[3],
    );
  }

  /// Inserted by the flows that are not wired to the API yet — newest first
  /// so it surfaces at the top of Pending. Never actionable.
  void addRequest(RequestItemData item) => _local.insert(0, item);

  /// Status change for a local-only row (server rows change via commit).
  void updateStatus(String requestId, RequestStatus status, {String? reason}) {
    final index = _local.indexWhere((item) => item.requestId == requestId);
    if (index == -1) return;
    _local[index] = _local[index].copyWith(status: status, rejectReason: reason);
  }

  void createRequest() => Get.toNamed(Routes.newRequest);

  void openRequest(RequestItemData item) => Get.toNamed(Routes.requestDetail, arguments: item);
}
