import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_client.dart';

/// Lists behind the Add Product pickers (category, brand, supplier,
/// warehouse). Each endpoint is paginated (max 100/page) — walk every page.
class MasterDataService {
  MasterDataService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<LookupOption>> categories() => _fetchAll(ApiConfig.categories);
  Future<List<LookupOption>> brands() => _fetchAll(ApiConfig.brands);
  Future<List<LookupOption>> suppliers() => _fetchAll(ApiConfig.suppliers);
  Future<List<LookupOption>> warehouses() => _fetchAll(ApiConfig.warehouses);

  /// How full [warehouseCode] gets if [quantity] more units go in now.
  Future<WarehouseCapacity> capacityCheck(String warehouseCode, double quantity) async {
    final json = await _apiClient.get(
      ApiConfig.warehouseCapacityCheck,
      query: {'warehouseCode': warehouseCode, 'quantity': quantity},
    );
    return WarehouseCapacity.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<LookupOption>> _fetchAll(String path) async {
    final options = <LookupOption>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(path, query: {'page': page, 'limit': 100});
      final List data;
      var hasNext = false;
      if (json is List) {
        data = json;
      } else {
        final map = json as Map<String, dynamic>;
        data = map['data'] as List? ?? const [];
        hasNext = (map['meta'] as Map?)?['hasNextPage'] == true;
      }
      for (final e in data) {
        final row = Map<String, dynamic>.from(e as Map);
        // Inactive rows can't be used when creating a product.
        if (row['isActive'] == false) continue;
        options.add(LookupOption.fromJson(row));
      }
      if (!hasNext) break;
      page++;
    }
    return options;
  }
}
