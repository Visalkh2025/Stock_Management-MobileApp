import 'package:get/get.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_crud.dart';

/// Backs one Manage > `<thing>` list (Categories, Brands, Suppliers,
/// Warehouses): loads from the API, filters by the search box, and
/// "deletes" (= deactivates) a row. Add/Edit happens on the matching
/// [MasterFormController] screen, which calls [load] again when it saves.
abstract class MasterListController<T extends MasterRecord> extends GetxController {
  /// The API endpoint this list reads and writes.
  MasterDataCrud<T> get crud;

  /// Route of the Add/Edit form (the edited record travels as `arguments`).
  String get formRoute;

  final _items = <T>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  int get count => _items.length;

  List<T> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _items.toList();
    return _items
        .where((item) => item.name.toLowerCase().contains(query) || item.code.toLowerCase().contains(query))
        .toList();
  }

  void setSearch(String value) => searchQuery.value = value;

  void openAdd() => Get.toNamed(formRoute);

  void openEdit(T item) => Get.toNamed(formRoute, arguments: item);

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      _items.assignAll(await crud.list());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// "Delete" = deactivate on the server, then refresh.
  Future<void> delete(T item) async {
    try {
      await crud.deactivate(item.id);
      await load();
    } on ApiException catch (e) {
      Get.snackbar('error_title'.tr, e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
