class ApiConfig {
  ApiConfig._();
  //   - iOS Simulator                          -> http://localhost:3000
  //   - Android Emulator                       -> http://10.0.2.2:3000
  //   - physical phone (same Wi-Fi as your Mac) -> http://<your-Mac-LAN-IP>:3000
  // static const String baseUrl = 'http://192.168.1.11:3000';
  // static const String baseUrl = 'http://localhost:3000';

  static const String baseUrl = 'https://stock.theavin.xyz';
  // static const String baseUrl = 'http://54.151.147.75:3000';
  // static const String baseUrl = 'https://reliant-procreate-decade.ngrok-free.dev';
  static const Duration timeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 60);

  // ---- Auth ----
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // ---- Users ----
  static const String me = '/users/me';
  static const String users = '/users';
  static String userRole(String userId) => '/users/$userId/role';

  // ---- Roles ----
  static const String roles = '/roles';

  // ---- Products / stock ----
  static const String products = '/products';
  static String productImage(String id) => '/products/$id/image';
  static String productVariantImage(String id) => '/product-variants/$id/image';
  static String productById(String id) => '/products/$id';
  static String productByCode(String code) => '/products/by-code/${Uri.encodeComponent(code)}';
  static const String stockAdjustments = '/stock-adjustments';
  static const String stockTransfer = '/stock-adjustments/transfer';
  static const String stockHistory = '/stock-adjustments/history';
  static const String stockHistoryMine = '/stock-adjustments/history/mine';

  // ---- Requests (approval workflow) ----
  static const String requests = '/requests';
  static const String requestApproverCandidates = '/requests/approver-candidates';
  static String requestById(String id) => '/requests/$id';
  static String requestCommit(String id) => '/requests/$id/commit';

  // ---- Purchase orders / goods receiving ----
  static const String productImport = '/products/import';
  static const String productImportPreview = '/products/import/preview';
  static const String productImportTemplate = '/products/import/template';
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrderImport = '/purchase-orders/import';
  static const String purchaseOrderApprovers = '/purchase-orders/approvers';
  static const String purchaseOrderReorder = '/purchase-orders/reorder';
  static const String purchaseOrderWarehouseCheck = '/purchase-orders/warehouse-check';
  static String purchaseOrderSupplierHistory(String productId) => '/purchase-orders/supplier-history/$productId';
  static String purchaseOrderSupplierProducts(String code) => '/purchase-orders/supplier-products/$code';
  static String purchaseOrderById(String id) => '/purchase-orders/$id';
  static String purchaseOrderAction(String id, String action) => '/purchase-orders/$id/$action';
  static const String customerOrders = '/customer-orders';
  static const String devices = '/devices';
  static const String devicesUnregister = '/devices/unregister';
  static String customerOrderById(String id) => '/customer-orders/$id';
  static const String customers = '/customer-orders/customers';
  static String customerById(String id) => '/customer-orders/customers/$id';
  static String customerOrderAction(String id, String action) => '/customer-orders/$id/$action';

  // ---- Master data (pickers) ----
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String suppliers = '/suppliers';
  static const String warehouses = '/warehouses';
  static const String warehouseCapacityCheck = '/warehouses/capacity-check';
}
