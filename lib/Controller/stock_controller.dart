import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/product_service.dart';

/// One chip in the Category / Brand rows of the Stock screen.
class StockFacet {
  const StockFacet({required this.key, required this.label, required this.count});

  /// Category/brand code (or [StockController.noBrandKey]).
  final String key;
  final String label;
  final int count;
}

class StockController extends GetxController {
  /// Brand-row key for products that have no brand.
  static const noBrandKey = '__none__';
  static const _gridPrefKey = 'stock_view_grid';

  /// Category → Brand drill-down (null = all). Picking a category resets the brand.
  final selectedCategory = RxnString();
  final selectedBrand = RxnString();

  /// List (false) or grid (true) layout; remembered between launches.
  final isGridView = false.obs;

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
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isGridView.value = prefs.getBool(_gridPrefKey) ?? false;
    } catch (_) {}
  }

  Future<void> setGridView(bool grid) async {
    isGridView.value = grid;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gridPrefKey, grid);
    } catch (_) {}
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

  /// Status chip + search, without the Category/Brand drill-down — what the
  /// chip counts are based on.
  bool _matchesStatusAndSearch(StockItemData item) {
    final query = searchQuery.value.trim().toLowerCase();
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
  }

  bool _matchesCategory(StockItemData item) {
    final cat = selectedCategory.value;
    return cat == null || item.categoryCode == cat;
  }

  List<StockItemData> get filteredItems {
    final brand = selectedBrand.value;
    return _allItems.where((item) {
      if (!_matchesStatusAndSearch(item) || !_matchesCategory(item)) return false;
      if (brand == null) return true;
      return brand == noBrandKey ? item.brandCode == null : item.brandCode == brand;
    }).toList();
  }

  /// "All" chip of the category row.
  int get categoryAllCount => _allItems.where(_matchesStatusAndSearch).length;

  /// "All brands" chip: products of the chosen category.
  int get brandAllCount => _allItems.where((i) => _matchesStatusAndSearch(i) && _matchesCategory(i)).length;

  /// Category chips (every category that has products, with its count under
  /// the current status/search).
  List<StockFacet> get categoryFacets {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final item in _allItems) {
      final code = item.categoryCode;
      if (code == null) continue;
      names[code] = item.category ?? code;
      if (_matchesStatusAndSearch(item)) counts[code] = (counts[code] ?? 0) + 1;
    }
    final list = [
      for (final e in names.entries) StockFacet(key: e.key, label: e.value, count: counts[e.key] ?? 0),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  /// Brand chips for the chosen category (empty until one is chosen, or when
  /// none of its products has a brand).
  List<StockFacet> get brandFacets {
    if (selectedCategory.value == null) return const [];
    final names = <String, String>{};
    final counts = <String, int>{};
    var noBrandTotal = 0;
    var noBrandCount = 0;
    for (final item in _allItems) {
      if (!_matchesCategory(item)) continue;
      final matches = _matchesStatusAndSearch(item);
      final code = item.brandCode;
      if (code == null) {
        noBrandTotal++;
        if (matches) noBrandCount++;
        continue;
      }
      names[code] = item.brand ?? code;
      if (matches) counts[code] = (counts[code] ?? 0) + 1;
    }
    if (names.isEmpty) return const [];
    final list = [
      for (final e in names.entries) StockFacet(key: e.key, label: e.value, count: counts[e.key] ?? 0),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    if (noBrandTotal > 0) {
      list.add(StockFacet(key: noBrandKey, label: 'stock_no_brand'.tr, count: noBrandCount));
    }
    return list;
  }

  void setCategory(String? code) {
    selectedCategory.value = code;
    selectedBrand.value = null;
  }

  void setBrand(String? key) => selectedBrand.value = key;

  void setFilter(StockFilter filter) => activeFilter.value = filter;

  /// Looks up a product by SKU or barcode (case/whitespace-insensitive).
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
