import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/brand_controller.dart';
import 'package:stock_management/Controller/category_controller.dart';
import 'package:stock_management/Controller/supplier_controller.dart';
import 'package:stock_management/Controller/warehouse_controller.dart';

/// Hub screen behind More > Manage (renamed from "Master Data") and Home's
/// "Manage" quick action — a menu of the four master-data lists (Category /
/// Supplier / Warehouse), each with its own list + Add/Edit form screen.
/// Holds no state of its own beyond reading the other controllers'
/// counts, via the same guarded-singleton pattern used throughout the app
/// (StockController, RequestController, ProfileController).
class ManageController extends GetxController {
  CategoryController get _category {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController(), permanent: true);
    }
    return Get.find<CategoryController>();
  }

  BrandController get _brand {
    if (!Get.isRegistered<BrandController>()) {
      Get.put(BrandController(), permanent: true);
    }
    return Get.find<BrandController>();
  }

  SupplierController get _supplier {
    if (!Get.isRegistered<SupplierController>()) {
      Get.put(SupplierController(), permanent: true);
    }
    return Get.find<SupplierController>();
  }

  WarehouseController get _warehouse {
    if (!Get.isRegistered<WarehouseController>()) {
      Get.put(WarehouseController(), permanent: true);
    }
    return Get.find<WarehouseController>();
  }

  int get categoryCount => _category.count;
  int get brandCount => _brand.count;
  int get supplierCount => _supplier.count;
  int get warehouseCount => _warehouse.count;

  void openCategories() => Get.toNamed(Routes.categories);
  void openBrands() => Get.toNamed(Routes.brands);
  void openSuppliers() => Get.toNamed(Routes.suppliers);
  void openWarehouses() => Get.toNamed(Routes.warehouses);
}
