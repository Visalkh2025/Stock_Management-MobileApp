import 'package:get/get.dart';
import 'package:stock_management/Controller/profile_controller.dart';

/// Permission codes granted by the backend (the same strings the API's `@RequirePermission(...)` guards check, and `permissions` on `POST /auth/login`).
class Perm {
  const Perm._();

  static const userView = 'USER_VIEW';
  static const userCreate = 'USER_CREATE';
  static const roleView = 'ROLE_VIEW';
  static const productView = 'PRODUCT_VIEW';
  static const productCreate = 'PRODUCT_CREATE';
  static const productImport = 'PRODUCT_IMPORT';
  static const productImage = 'PRODUCT_IMAGE';
  static const productEdit = 'PRODUCT_EDIT';
  static const adjustmentView = 'ADJUSTMENT_VIEW';
  static const categoryManage = 'CATEGORY_MANAGE';
  static const supplierManage = 'SUPPLIER_MANAGE';
  static const warehouseManage = 'WAREHOUSE_MANAGE';
  static const brandManage = 'BRAND_MANAGE';
  static const stockAdjust = 'STOCK_ADJUST';
  static const stockTransfer = 'STOCK_TRANSFER';
  static const requestCreate = 'REQUEST_CREATE';
  static const requestApprove = 'REQUEST_APPROVE';
  static const reportView = 'REPORT_VIEW';
  static const poView = 'PO_VIEW';
  static const poCreate = 'PO_CREATE';
  static const poApprove = 'PO_APPROVE';
  static const poReceive = 'PO_RECEIVE';
}

/// True when the signed-in user holds [code]. Safe to call from any widget
/// or controller; returns false when nobody is signed in.
bool can(String code) {
  if (!Get.isRegistered<ProfileController>()) return false;
  return Get.find<ProfileController>().can(code);
}
