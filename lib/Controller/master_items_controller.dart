import 'package:get/get.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// Which Manage list a row was tapped in.
enum MasterKind { category, brand, supplier, warehouse }

/// What the "products in ..." screen is about (`Get.arguments`).
class MasterItemsArgs {
  const MasterItemsArgs({required this.kind, required this.code, required this.name});

  final MasterKind kind;

  /// Category / brand / supplier / warehouse code.
  final String code;
  final String name;
}

/// One chip under the header (the other way to slice the same products).
class MasterFacet {
  const MasterFacet({required this.key, required this.label, required this.count});

  final String key;
  final String label;
  final int count;
}

/// Products that belong to one category, brand, supplier or warehouse,
/// taken from the catalogue the Stock screen already loads. A second row of
/// chips narrows them further: a category by brand, anything else by category.
class MasterItemsController extends GetxController {
  late final MasterItemsArgs args;

  final searchQuery = ''.obs;

  /// Chip key (null = all).
  final selectedFacet = RxnString();

  /// Supplier view only: what was really bought from this supplier on its
  /// purchase orders, by product id. Empty when it cannot be loaded (no
  /// permission, offline): the default-supplier products still show.
  final purchased = Rx<Map<String, SupplierPurchase>>({});

  StockController get catalog {
    if (Get.isRegistered<StockController>()) return Get.find<StockController>();
    return Get.put(StockController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    // Read once: `Get.arguments` changes while a product detail is open on top.
    args = Get.arguments as MasterItemsArgs;
    if (catalog.allCount == 0) catalog.load();
    if (args.kind == MasterKind.supplier) _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      final rows = await PurchaseOrderService().fetchSupplierProducts(args.code);
      purchased.value = {for (final r in rows) r.productId: r};
    } catch (_) {
      // Keep the default-supplier list.
    }
  }

  /// How this product was bought from the supplier (supplier view only).
  SupplierPurchase? purchaseOf(StockItemData item) {
    if (args.kind != MasterKind.supplier) return null;
    final id = item.id;
    return id == null ? null : purchased.value[id];
  }

  bool get isLoading => catalog.isLoading.value;
  String? get errorMessage => catalog.errorMessage.value;

  Future<void> refresh() async {
    if (args.kind == MasterKind.supplier) _loadPurchases();
    await catalog.load();
  }

  /// The chips slice by brand inside a category, by category everywhere else.
  bool get facetsAreBrands => args.kind == MasterKind.category;

  bool _belongs(StockItemData item) {
    switch (args.kind) {
      case MasterKind.category:
        return item.categoryCode == args.code;
      case MasterKind.brand:
        return item.brandCode == args.code;
      case MasterKind.supplier:
        // Its default products, plus everything really bought from it.
        return item.supplierCode == args.code || (item.id != null && purchased.value.containsKey(item.id));
      case MasterKind.warehouse:
        return item.warehouseStocks.any((s) => s.warehouseCode == args.code);
    }
  }

  /// Every product of this category / brand / supplier / warehouse.
  List<StockItemData> get members => catalog.allItems.where(_belongs).toList();

  String? _facetKey(StockItemData i) => facetsAreBrands ? i.brandCode : i.categoryCode;
  String? _facetLabel(StockItemData i) => facetsAreBrands ? i.brand : i.category;

  List<MasterFacet> get facets {
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final item in members) {
      final key = _facetKey(item);
      if (key == null || key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      labels[key] = _facetLabel(item) ?? key;
    }
    final list = counts.entries
        .map((e) => MasterFacet(key: e.key, label: labels[e.key]!, count: e.value))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  /// Products after the chip and the search box.
  List<StockItemData> get items {
    final query = searchQuery.value.trim().toLowerCase();
    final facet = selectedFacet.value;
    return members.where((i) {
      if (facet != null && _facetKey(i) != facet) return false;
      if (query.isEmpty) return true;
      return i.name.toLowerCase().contains(query) ||
          i.sku.toLowerCase().contains(query) ||
          (i.barcode ?? '').toLowerCase().contains(query);
    }).toList();
  }

  /// Units of [item] that count here: the warehouse's own stock in a
  /// warehouse, the total everywhere else.
  int quantityOf(StockItemData item) {
    if (args.kind != MasterKind.warehouse) return item.quantity;
    return item.warehouseStocks
        .where((s) => s.warehouseCode == args.code)
        .fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Where in the warehouse the product sits (warehouse view only).
  String? locationOf(StockItemData item) {
    if (args.kind != MasterKind.warehouse) return null;
    for (final s in item.warehouseStocks) {
      if (s.warehouseCode == args.code && s.location != null) return s.location;
    }
    return null;
  }

  int get totalUnits => members.fold<int>(0, (sum, i) => sum + quantityOf(i));
  int get attentionCount =>
      members.where((i) => i.status != StockStatus.inStock).length;

  void select(String? key) => selectedFacet.value = key;
  void setSearch(String value) => searchQuery.value = value;

  void open(StockItemData item) => catalog.openItem(item);
}
