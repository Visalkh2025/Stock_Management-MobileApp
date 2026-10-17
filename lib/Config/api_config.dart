class ApiConfig {
  ApiConfig._();
  //   - iOS Simulator                          -> http://localhost:3000
  //   - Android Emulator                       -> http://10.0.2.2:3000
  //   - physical phone (same Wi-Fi as your Mac) -> http://<your-Mac-LAN-IP>:3000
  // static const String baseUrl = 'http://172.16.112.95:3000';
  static const String baseUrl = 'http://172.16.112.30:3000';

  // static const String baseUrl = 'http://localhost:3000';
  static const Duration timeout = Duration(seconds: 15);
  // Image uploads go phone -> API -> Cloudinary, so they need more time.
  static const Duration uploadTimeout = Duration(seconds: 60);

  // ---- Auth ----
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';

  // ---- Users ----
  static const String me = '/users/me';
  static const String users = '/users';
  static String userRole(String userId) => '/users/$userId/role';

  // ---- Roles ----
  static const String roles = '/roles';

  // ---- Products / stock ----
  static const String products = '/products';
  static String productImage(String id) => '/products/$id/image';
  static String productByCode(String code) => '/products/by-code/${Uri.encodeComponent(code)}';
  static const String stockAdjustments = '/stock-adjustments';

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
  static String purchaseOrderById(String id) => '/purchase-orders/$id';
  static String purchaseOrderAction(String id, String action) => '/purchase-orders/$id/$action';

  // ---- Master data (pickers) ----
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String suppliers = '/suppliers';
  static const String warehouses = '/warehouses';
}
