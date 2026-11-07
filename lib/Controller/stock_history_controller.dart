import 'package:get/get.dart';
import 'package:stock_management/Model/stock_history_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/stock_history_service.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';

/// Stock history — every Stock In, Stock Out, Transfer and Adjustment, newest
/// first. Opened from More (all products) or from a product (that product
/// only: the product arrives as the route argument).
class StockHistoryController extends GetxController {
  final _service = StockHistoryService();

  static const _pageSize = 20;

  /// Set when opened from a product's detail screen.
  late final StockItemData? product = Get.arguments is StockItemData ? Get.arguments as StockItemData : null;

  final entries = <StockHistoryEntry>[].obs;
  final total = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();

  /// 'ALL' | 'IN' | 'OUT' | 'TRANSFER' | 'ADJUSTMENT'
  final filter = 'ALL'.obs;

  /// All dates / today / last 7 or 30 days / a picked range.
  final dateFilter = const DateFilter().obs;

  int _page = 1;
  bool _hasNext = false;

  String? get _kind => filter.value == 'ALL' ? null : filter.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _service.fetch(kind: _kind, productId: product?.id, from: dateFilter.value.fromParam, to: dateFilter.value.toParam, page: 1, limit: _pageSize);
      entries.assignAll(result.entries);
      total.value = result.total;
      _hasNext = result.hasNextPage;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasNext || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.fetch(kind: _kind, productId: product?.id, from: dateFilter.value.fromParam, to: dateFilter.value.toParam, page: _page + 1, limit: _pageSize);
      _page += 1;
      entries.addAll(result.entries);
      total.value = result.total;
      _hasNext = result.hasNextPage;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    load();
  }

  void setDateFilter(DateFilter value) {
    dateFilter.value = value;
    load();
  }
}
