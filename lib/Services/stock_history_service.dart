import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Model/stock_history_models.dart';
import 'package:stock_management/Services/api_client.dart';

/// Stock history (needs ADJUSTMENT_VIEW).
class StockHistoryService {
  StockHistoryService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// [kind] is IN / OUT / TRANSFER / ADJUSTMENT (null = all); [productId]
  /// limits it to one product.
  /// [from] / [to] are ISO timestamps (see DateFilter): from <= time < to.
  Future<StockHistoryPage> fetch({String? kind, String? productId, String? from, String? to, int page = 1, int limit = 20}) async {
    final json = await _apiClient.get(
      // Everyone's history needs ADJUSTMENT_VIEW; otherwise only the person's own.
      can(Perm.adjustmentView) ? ApiConfig.stockHistory : ApiConfig.stockHistoryMine,
      query: {
        'page': page,
        'limit': limit,
        if (kind != null) 'kind': kind,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    ) as Map<String, dynamic>;
    return StockHistoryPage.fromJson(json);
  }
}
