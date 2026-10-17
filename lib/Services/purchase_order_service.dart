import 'package:http/http.dart' as http;
import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_client.dart';

/// Purchase orders + goods receiving against the NestJS API.
class PurchaseOrderService {
  PurchaseOrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /purchase-orders` is paginated (max 100 per page) — walk every page.
  Future<List<PurchaseOrderSummary>> fetchAll() async {
    final rows = <PurchaseOrderSummary>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(ApiConfig.purchaseOrders, query: {'page': page, 'limit': 100}) as Map<String, dynamic>;
      final data = json['data'] as List? ?? const [];
      rows.addAll(data.map((e) => PurchaseOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))));
      final meta = json['meta'] as Map<String, dynamic>? ?? const {};
      if (meta['hasNextPage'] != true) break;
      page++;
    }
    return rows;
  }

  Future<PurchaseOrderDetail> fetchOne(String id) async {
    final json = await _apiClient.get(ApiConfig.purchaseOrderById(id));
    return PurchaseOrderDetail.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// [body]: `{supplierCode, warehouseCode, note?, submit, items: [{productCode,
  /// variantCode?, quantity, unitPrice}]}`.
  Future<void> create(Map<String, dynamic> body) => _apiClient.post(ApiConfig.purchaseOrders, body: body);

  Future<void> update(String id, Map<String, dynamic> body) =>
      _apiClient.patch(ApiConfig.purchaseOrderById(id), body: body);

  /// [approverId]: the Admin / Super Admin to ask. Not needed for an Admin /
  /// Super Admin (their order is approved straight away).
  Future<void> submit(String id, {String? approverId}) => _apiClient.post(
        ApiConfig.purchaseOrderAction(id, 'submit'),
        body: {if (approverId != null) 'approverId': approverId},
      );

  Future<List<PoApprover>> fetchApprovers() async {
    final json = await _apiClient.get(ApiConfig.purchaseOrderApprovers);
    return (json as List? ?? const [])
        .map((e) => PoApprover.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> approve(String id) => _apiClient.post(ApiConfig.purchaseOrderAction(id, 'approve'));

  Future<void> reject(String id, String reason) =>
      _apiClient.post(ApiConfig.purchaseOrderAction(id, 'reject'), body: {'reason': reason});

  /// [items]: `[{itemId, quantity}]` — only the lines that arrived.
  Future<void> receive(String id, {required List<Map<String, dynamic>> items, String? note}) =>
      _apiClient.post(
        ApiConfig.purchaseOrderAction(id, 'receive'),
        body: {'items': items, if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      );

  /// Excel (Add Product import format) of the received new products that are
  /// not in the catalogue yet.
  Future<List<int>> exportPendingProducts(String id) =>
      _apiClient.getBytes(ApiConfig.purchaseOrderAction(id, 'export-products'));

  /// The manager added the received new products to the catalogue.
  Future<void> markCatalogAdded(String id) => _apiClient.post(ApiConfig.purchaseOrderAction(id, 'catalog-added'));

  /// Uploads an Excel / CSV file of products. The server only checks it and
  /// reports each row; nothing is saved.
  Future<PoImportPreview> previewImport(String path, String fileName) async {
    final file = await http.MultipartFile.fromPath('file', path, filename: fileName);
    final json = await _apiClient.postMultipart(ApiConfig.purchaseOrderImport, fields: const {}, files: [file]);
    return PoImportPreview.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
