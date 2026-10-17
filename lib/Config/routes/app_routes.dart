import 'package:get/get.dart';
import 'package:stock_management/View/Auth/login_screen.dart';
import 'package:stock_management/View/Auth/new_password_screen.dart';
import 'package:stock_management/View/Home/home_screen.dart';
import 'package:stock_management/View/Stock/stock_screen.dart';
import 'package:stock_management/View/Requests/requests_screen.dart';
import 'package:stock_management/View/Requests/request_detail_screen.dart';
import 'package:stock_management/View/Requests/new_request_screen.dart';
import 'package:stock_management/View/StockMovement/stock_movement_screen.dart';
import 'package:stock_management/View/Transfer/transfer_screen.dart';
import 'package:stock_management/View/Adjust/adjust_screen.dart';
import 'package:stock_management/View/Manage/manage_screen.dart';
import 'package:stock_management/View/Manage/categories_screen.dart';
import 'package:stock_management/View/Manage/brands_screen.dart';
import 'package:stock_management/View/Manage/brand_form_screen.dart';
import 'package:stock_management/View/Manage/category_form_screen.dart';
import 'package:stock_management/View/Manage/suppliers_screen.dart';
import 'package:stock_management/View/Manage/supplier_form_screen.dart';
import 'package:stock_management/View/Manage/warehouses_screen.dart';
import 'package:stock_management/View/Manage/warehouse_form_screen.dart';
import 'package:stock_management/View/PurchaseOrders/purchase_orders_screen.dart';
import 'package:stock_management/View/PurchaseOrders/purchase_order_form_screen.dart';
import 'package:stock_management/View/PurchaseOrders/purchase_order_detail_screen.dart';
import 'package:stock_management/View/PurchaseOrders/goods_receiving_screen.dart';
import 'package:stock_management/View/Reports/reports_screen.dart';
import 'package:stock_management/View/TeamMembers/team_members_screen.dart';
import 'package:stock_management/View/TeamMembers/team_member_form_screen.dart';
import 'package:stock_management/View/Settings/settings_screen.dart';
import 'package:stock_management/View/HelpSupport/help_support_screen.dart';
import 'package:stock_management/View/Roles/rbac_hub_screen.dart';
import 'package:stock_management/View/Roles/role_form_screen.dart';
import 'package:stock_management/View/Roles/role_permissions_screen.dart';
import 'package:stock_management/View/Roles/permission_form_screen.dart';
import 'package:stock_management/View/More/more_screen.dart';
import 'package:stock_management/View/ProductDetail/product_detail_screen.dart';
import 'package:stock_management/View/AddProduct/add_product_screen.dart';
import 'package:stock_management/View/ScanQr/scan_qr_screen.dart';
import 'package:stock_management/View/Profile/profile_screen.dart';
import 'package:stock_management/Bindings/auth_binding.dart';
import 'package:stock_management/Bindings/home_binding.dart';
import 'package:stock_management/Bindings/stock_binding.dart';
import 'package:stock_management/Bindings/request_binding.dart';
import 'package:stock_management/Bindings/request_detail_binding.dart';
import 'package:stock_management/Bindings/new_request_binding.dart';
import 'package:stock_management/Bindings/stock_movement_binding.dart';
import 'package:stock_management/Bindings/transfer_binding.dart';
import 'package:stock_management/Bindings/adjust_binding.dart';
import 'package:stock_management/Bindings/manage_binding.dart';
import 'package:stock_management/Bindings/category_binding.dart';
import 'package:stock_management/Bindings/brand_binding.dart';
import 'package:stock_management/Bindings/brand_form_binding.dart';
import 'package:stock_management/Bindings/category_form_binding.dart';
import 'package:stock_management/Bindings/supplier_binding.dart';
import 'package:stock_management/Bindings/supplier_form_binding.dart';
import 'package:stock_management/Bindings/warehouse_binding.dart';
import 'package:stock_management/Bindings/warehouse_form_binding.dart';
import 'package:stock_management/Bindings/purchase_orders_binding.dart';
import 'package:stock_management/Bindings/purchase_order_form_binding.dart';
import 'package:stock_management/Bindings/purchase_order_detail_binding.dart';
import 'package:stock_management/Bindings/goods_receiving_binding.dart';
import 'package:stock_management/Bindings/reports_binding.dart';
import 'package:stock_management/Bindings/team_members_binding.dart';
import 'package:stock_management/Bindings/team_member_form_binding.dart';
import 'package:stock_management/Bindings/settings_binding.dart';
import 'package:stock_management/Bindings/help_support_binding.dart';
import 'package:stock_management/Bindings/rbac_hub_binding.dart';
import 'package:stock_management/Bindings/role_form_binding.dart';
import 'package:stock_management/Bindings/role_permissions_binding.dart';
import 'package:stock_management/Bindings/permission_form_binding.dart';
import 'package:stock_management/Bindings/more_binding.dart';
import 'package:stock_management/Bindings/product_detail_binding.dart';
import 'package:stock_management/Bindings/add_product_binding.dart';
import 'package:stock_management/Bindings/scan_qr_binding.dart';
import 'package:stock_management/Bindings/profile_binding.dart';

class Routes {
  Routes._();

  static const login = '/login';
  static const newPassword = '/new_password';
  static const forgotPassword = '/forgot_password';
  static const verifyOtp = '/verify_otp';
  static const home = '/home';
  static const stock = '/stock';
  static const requests = '/requests';
  static const requestDetail = '/request_detail';
  static const newRequest = '/new_request';
  static const stockIn = '/stock_in';
  static const stockOut = '/stock_out';
  static const transfer = '/transfer';
  static const adjust = '/adjust';
  static const manage = '/manage';
  static const categories = '/categories';
  static const categoryForm = '/category_form';
  static const brands = '/brands';
  static const brandForm = '/brand_form';
  static const suppliers = '/suppliers';
  static const supplierForm = '/supplier_form';
  static const warehouses = '/warehouses';
  static const warehouseForm = '/warehouse_form';
  static const purchaseOrders = '/purchase_orders';
  static const purchaseOrderForm = '/purchase_order_form';
  static const purchaseOrderDetail = '/purchase_order_detail';
  static const goodsReceiving = '/goods_receiving';
  static const reports = '/reports';
  static const teamMembers = '/team_members';
  static const teamMemberForm = '/team_member_form';
  static const settings = '/settings';
  static const helpSupport = '/help_support';
  static const rolesPermissions = '/roles_permissions';
  static const roleForm = '/role_form';
  static const rolePermissions = '/role_permissions';
  static const permissionForm = '/permission_form';
  static const more = '/more';
  static const productDetail = '/product_detail';
  static const addProduct = '/add_product';
  static const scanQr = '/scan_qr';
  static const profile = '/profile';

  static final pages = <GetPage>[
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: newPassword,
      page: () => const NewPasswordScreen(),
      binding: AuthBinding(),
    ),
    // Home & Stock are bottom-nav destinations — switch between them with a
    // quick fade instead of the default push-style slide.
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: stock,
      page: () => const StockScreen(),
      binding: StockBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: requests,
      page: () => const RequestsScreen(),
      binding: RequestBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: requestDetail,
      page: () => const RequestDetailScreen(),
      binding: RequestDetailBinding(),
    ),
    GetPage(
      name: newRequest,
      page: () => const NewRequestScreen(),
      binding: NewRequestBinding(),
    ),
    GetPage(
      name: stockIn,
      page: () => const StockMovementScreen(),
      binding: StockInBinding(),
    ),
    GetPage(
      name: stockOut,
      page: () => const StockMovementScreen(),
      binding: StockOutBinding(),
    ),
    GetPage(
      name: transfer,
      page: () => const TransferScreen(),
      binding: TransferBinding(),
    ),
    GetPage(
      name: adjust,
      page: () => const AdjustScreen(),
      binding: AdjustBinding(),
    ),
    GetPage(
      name: manage,
      page: () => const ManageScreen(),
      binding: ManageBinding(),
    ),
    GetPage(
      name: categories,
      page: () => const CategoriesScreen(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: categoryForm,
      page: () => const CategoryFormScreen(),
      binding: CategoryFormBinding(),
    ),
    GetPage(
      name: brands,
      page: () => const BrandsScreen(),
      binding: BrandBinding(),
    ),
    GetPage(
      name: brandForm,
      page: () => const BrandFormScreen(),
      binding: BrandFormBinding(),
    ),
    GetPage(
      name: suppliers,
      page: () => const SuppliersScreen(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: supplierForm,
      page: () => const SupplierFormScreen(),
      binding: SupplierFormBinding(),
    ),
    GetPage(
      name: warehouses,
      page: () => const WarehousesScreen(),
      binding: WarehouseBinding(),
    ),
    GetPage(
      name: warehouseForm,
      page: () => const WarehouseFormScreen(),
      binding: WarehouseFormBinding(),
    ),
    GetPage(
      name: purchaseOrders,
      page: () => const PurchaseOrdersScreen(),
      binding: PurchaseOrdersBinding(),
    ),
    GetPage(
      name: purchaseOrderForm,
      page: () => const PurchaseOrderFormScreen(),
      binding: PurchaseOrderFormBinding(),
    ),
    GetPage(
      name: purchaseOrderDetail,
      page: () => const PurchaseOrderDetailScreen(),
      binding: PurchaseOrderDetailBinding(),
    ),
    GetPage(
      name: goodsReceiving,
      page: () => const GoodsReceivingScreen(),
      binding: GoodsReceivingBinding(),
    ),
    GetPage(
      name: reports,
      page: () => const ReportsScreen(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: teamMembers,
      page: () => const TeamMembersScreen(),
      binding: TeamMembersBinding(),
    ),
    GetPage(
      name: teamMemberForm,
      page: () => const TeamMemberFormScreen(),
      binding: TeamMemberFormBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: helpSupport,
      page: () => const HelpSupportScreen(),
      binding: HelpSupportBinding(),
    ),
    GetPage(
      name: rolesPermissions,
      page: () => const RbacHubScreen(),
      binding: RbacHubBinding(),
    ),
    GetPage(
      name: roleForm,
      page: () => const RoleFormScreen(),
      binding: RoleFormBinding(),
    ),
    GetPage(
      name: rolePermissions,
      page: () => const RolePermissionsScreen(),
      binding: RolePermissionsBinding(),
    ),
    GetPage(
      name: permissionForm,
      page: () => const PermissionFormScreen(),
      binding: PermissionFormBinding(),
    ),
    GetPage(
      name: more,
      page: () => const MoreScreen(),
      binding: MoreBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: productDetail,
      page: () => const ProductDetailScreen(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: addProduct,
      page: () => const AddProductScreen(),
      binding: AddProductBinding(),
    ),
    GetPage(
      name: scanQr,
      page: () => const ScanQrScreen(),
      binding: ScanQrBinding(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    // forgotPassword, verifyOtp screens land here once built.
  ];
}
