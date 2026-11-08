import 'dart:io';

import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/customer_models.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/api_client.dart';
import 'package:stock_management/Services/image_upload.dart';

/// Customer orders (from the Mini App or placed by staff) against the NestJS
/// API. Only the staff side: the Mini App's own routes are not used here.
class CustomerOrderService {
  CustomerOrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /customer-orders` is paginated (max 100 per page) — walk every page.
  /// Also accepts a plain list, in case a server returns one.
  Future<List<CustomerOrderSummary>> fetchAll() async {
    final rows = <CustomerOrderSummary>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(ApiConfig.customerOrders, query: {'page': page, 'limit': 100});
      final List data;
      var hasNext = false;
      if (json is List) {
        data = json;
      } else if (json is Map) {
        data = (json['data'] ?? json['items'] ?? const []) as List;
        final meta = json['meta'];
        hasNext = meta is Map && meta['hasNextPage'] == true;
      } else {
        data = const [];
      }
      rows.addAll(data.map((e) => CustomerOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))));
      if (!hasNext) break;
      page++;
    }
    return rows;
  }

  /// Orders still waiting for a staff decision (the bell on Home).
  /// Filtered by the API, so it stays one small request.
  Future<List<CustomerOrderSummary>> fetchPending() async {
    final json = await _apiClient.get(
      ApiConfig.customerOrders,
      query: {'status': CoStatus.pendingReview.apiValue, 'page': 1, 'limit': 100},
    );
    final List data = json is List ? json : ((json is Map ? (json['data'] ?? json['items']) : null) as List? ?? const []);
    return data.map((e) => CustomerOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  /// `GET /customer-orders/customers` is paginated (max 100 per page) — walk every page.
  Future<List<CustomerRow>> fetchCustomers() async {
    final rows = <CustomerRow>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(ApiConfig.customers, query: {'page': page, 'limit': 100});
      final List data;
      var totalPages = 1;
      if (json is List) {
        data = json;
      } else if (json is Map) {
        data = (json['items'] ?? json['data'] ?? const []) as List;
        final meta = json['meta'];
        if (meta is Map) totalPages = int.tryParse('${meta['totalPages'] ?? 1}') ?? 1;
      } else {
        data = const [];
      }
      rows.addAll(data.map((e) => CustomerRow.fromJson(Map<String, dynamic>.from(e as Map))));
      if (json is List || page >= totalPages) break;
      page++;
    }
    return rows;
  }

  Future<CustomerRow> fetchCustomer(String id) async {
    final json = await _apiClient.get(ApiConfig.customerById(id));
    return CustomerRow.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Every order of one customer, newest first (the API already sorts them).
  Future<List<CustomerOrderSummary>> fetchOrdersOfCustomer(String customerId) async {
    final rows = <CustomerOrderSummary>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(
        ApiConfig.customerOrders,
        query: {'page': page, 'limit': 100, 'customerId': customerId},
      );
      final List data;
      var hasNext = false;
      if (json is List) {
        data = json;
      } else if (json is Map) {
        data = (json['data'] ?? json['items'] ?? const []) as List;
        final meta = json['meta'];
        hasNext = meta is Map && meta['hasNextPage'] == true;
      } else {
        data = const [];
      }
      rows.addAll(data.map((e) => CustomerOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))));
      if (!hasNext) break;
      page++;
    }
    return rows;
  }

  Future<CustomerOrderDetail> fetchOne(String id) async {
    final json = await _apiClient.get(ApiConfig.customerOrderById(id));
    return CustomerOrderDetail.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Takes the order in full: the stock is set aside for it.
  Future<void> accept(String id) => _apiClient.post(ApiConfig.customerOrderAction(id, 'accept'));

  Future<void> reject(String id, String reason) =>
      _apiClient.post(ApiConfig.customerOrderAction(id, 'reject'), body: {'reason': reason});

  Future<void> process(String id) => _apiClient.post(ApiConfig.customerOrderAction(id, 'process'));

  Future<void> outForDelivery(String id) => _apiClient.post(ApiConfig.customerOrderAction(id, 'out-for-delivery'));

  Future<void> delivered(String id) => _apiClient.post(ApiConfig.customerOrderAction(id, 'delivered'));

  /// [proof]: photo of the transaction. Sent as multipart only when there is
  /// one, so a plain payment still uses the original JSON request.
  Future<void> recordPayment(String id, double amount, {String? remark, File? proof}) async {
    final path = ApiConfig.customerOrderAction(id, 'payment');
    final note = (remark != null && remark.isNotEmpty) ? remark : null;
    if (proof == null) {
      await _apiClient.post(path, body: {'amount': amount, if (note != null) 'remark': note});
      return;
    }
    await _apiClient.postMultipart(
      path,
      fields: {'amount': '$amount', if (note != null) 'remark': note},
      files: [await imageMultipart('proof', proof)],
    );
  }

  Future<void> complete(String id) => _apiClient.post(ApiConfig.customerOrderAction(id, 'complete'));
}
