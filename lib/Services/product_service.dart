import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_client.dart';
import 'package:stock_management/Services/image_upload.dart';

/// Products + stock against the NestJS API.
class ProductService {
  ProductService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /products` is paginated (max 100 per page) — walk every page so
  /// the Stock screen's local search/filters see the whole catalogue.
  Future<List<StockItemData>> fetchProducts() async {
    final items = <StockItemData>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(ApiConfig.products, query: {'page': page, 'limit': 100}) as Map<String, dynamic>;
      final data = json['data'] as List? ?? const [];
      items.addAll(data.map((e) => StockItemData.fromJson(Map<String, dynamic>.from(e as Map))));
      final meta = json['meta'] as Map<String, dynamic>? ?? const {};
      if (meta['hasNextPage'] != true) break;
      page++;
    }
    return items;
  }

  /// Exact lookup for the scanner. Returns null when the code is unknown
  /// (the API answers 404 — surfaced by the caller as [ApiException]).
  Future<StockItemData> fetchByCode(String code) async {
    final json = await _apiClient.get(ApiConfig.productByCode(code)) as Map<String, dynamic>;
    return StockItemData.fromJson(json);
  }

  /// `POST /products` (needs PRODUCT_CREATE). [stock] rows are
  /// `{warehouseCode, quantity, variantCode?, location?}`. Product code and
  /// SKU may be omitted — the server generates them.
  Future<void> createProduct({
    required Map<String, dynamic> product,
    List<Map<String, dynamic>> variants = const [],
    required List<Map<String, dynamic>> stock,
    File? image,
  }) async {
    final fields = <String, String>{
      'product': jsonEncode(product),
      'variants': jsonEncode(variants),
      'stock': jsonEncode(stock),
    };
    final files = <http.MultipartFile>[];
    if (image != null) {
      files.add(await imageMultipart('image', image));
    }
    await _apiClient.postMultipart(ApiConfig.products, fields: fields, files: files);
  }

  /// `POST /products/:id/image` (needs PRODUCT_UPDATE): replaces the photo.
  Future<void> updateImage(String productId, File image) async {
    final file = await imageMultipart('image', image);
    await _apiClient.postMultipart(ApiConfig.productImage(productId), fields: const {}, files: [file]);
  }

  /// `POST /products/import` (needs PRODUCT_CREATE): creates every product in
  /// the Excel / CSV file, with its initial stock, or none if a row is wrong.
  Future<Map<String, dynamic>> importExcel(String path, String fileName) async {
    final file = await http.MultipartFile.fromPath('file', path, filename: fileName);
    final json = await _apiClient.postMultipart(ApiConfig.productImport, fields: const {}, files: [file]);
    return Map<String, dynamic>.from(json as Map? ?? const {});
  }

  /// Dry run of [importExcel]: nothing is saved. Returns `{ok, rows}` or
  /// `{ok: false, errors}`.
  Future<Map<String, dynamic>> previewImport(String path, String fileName) async {
    final file = await http.MultipartFile.fromPath('file', path, filename: fileName);
    final json = await _apiClient.postMultipart(ApiConfig.productImportPreview, fields: const {}, files: [file]);
    return Map<String, dynamic>.from(json as Map? ?? const {});
  }

  /// The empty Excel template for [importExcel].
  Future<List<int>> downloadImportTemplate() => _apiClient.getBytes(ApiConfig.productImportTemplate);

  /// `POST /stock-adjustments` (needs STOCK_ADJUST). Positive = INCREASE
  /// (Stock In), negative handled by [increase] = false.
  Future<void> adjustStock({
    required String productCode,
    String? variantCode,
    required String warehouseCode,
    required int quantity,
    required bool increase,
    required String reason,
    String? location,
  }) async {
    await _apiClient.post(
      ApiConfig.stockAdjustments,
      body: {
        'productCode': productCode,
        if (variantCode != null && variantCode.isNotEmpty) 'variantCode': variantCode,
        'warehouseCode': warehouseCode,
        'adjustmentType': increase ? 'INCREASE' : 'DECREASE',
        'quantity': quantity,
        'reason': reason,
        if (location != null && location.trim().isNotEmpty) 'location': location.trim(),
      },
    );
  }
}
