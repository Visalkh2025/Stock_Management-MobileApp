import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/product_service.dart';

class StockController extends GetxController {
  final searchQuery = ''.obs;
  final activeFilter = StockFilter.all.obs;
  final isSearchActive = false.obs;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  /// SKUs of the product cards currently expanded to show their variants.
  final expandedSkus = <String>{}.obs;

  final ProductService _service = ProductService();

  /// Products loaded from `GET /products` (see [load]).
  final _allItems = <StockItemData>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// (Re)loads the catalogue + stock levels from the server. Called on
  /// start and after anything that changes stock (add product, Stock In).
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      _allItems.assignAll(await _service.fetchProducts());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Every loaded product (for pickers).
  List<StockItemData> get allItems => _allItems.toList();

  int get allCount => _allItems.length;
  int get lowCount => _allItems.where((item) => item.status == StockStatus.lowStock).length;
  int get outCount => _allItems.where((item) => item.status == StockStatus.outOfStock).length;

  List<StockItemData> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    return _allItems.where((item) {
      final matchesFilter = switch (activeFilter.value) {
        StockFilter.all => true,
        StockFilter.low => item.status == StockStatus.lowStock,
        StockFilter.out => item.status == StockStatus.outOfStock,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final matchesProduct = item.name.toLowerCase().contains(query) || item.sku.toLowerCase().contains(query);
      if (matchesProduct) return true;
      // A search hit on a variant's name/SKU still surfaces the parent card.
      return item.variants.any(
        (v) => v.variantName.toLowerCase().contains(query) || v.sku.toLowerCase().contains(query),
      );
    }).toList();
  }

  void setFilter(StockFilter filter) => activeFilter.value = filter;

  /// Looks up a product by SKU or barcode (case/whitespace-insensitive) —
  /// used by the Scan screen to resolve a scanned code. Checks each
  /// product's own SKU/barcode first, then falls back to matching one of
  /// its variants, since a scanned variant should still open its parent
  /// product card.
  StockItemData? findByCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final item in _allItems) {
      final matchesSku = item.sku.toLowerCase() == normalized;
      final matchesBarcode = item.barcode?.toLowerCase() == normalized;
      final matchesCode = item.code?.toLowerCase() == normalized;
      if (matchesSku || matchesBarcode || matchesCode) return item;
      final variantMatch = item.variants.any(
        (v) => v.sku.toLowerCase() == normalized || v.variantCode.toLowerCase() == normalized,
      );
      if (variantMatch) return item;
    }
    return null;
  }

  void setSearchQuery(String value) => searchQuery.value = value;

  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (isSearchActive.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => searchFocusNode.requestFocus());
    } else {
      searchController.clear();
      searchQuery.value = '';
      searchFocusNode.unfocus();
    }
  }

  void toggleExpanded(String sku) {
    if (expandedSkus.contains(sku)) {
      expandedSkus.remove(sku);
    } else {
      expandedSkus.add(sku);
    }
  }

  void addStockItem() {
    Get.toNamed(Routes.addProduct);
  }

  void openItem(StockItemData item) {
    Get.toNamed(Routes.productDetail, arguments: item);
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
