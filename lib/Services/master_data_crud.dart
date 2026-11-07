import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/api_client.dart';

/// List / create / update / deactivate for one master-data endpoint (`/categories`, `/brands`, `/suppliers`, `/warehouses`).
class MasterDataCrud<T extends MasterRecord> {
  MasterDataCrud({required this.path, required this.fromJson, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  final ApiClient _apiClient;

  /// Every active record (the endpoint is paginated, max 100 per page).
  Future<List<T>> list() async {
    final items = <T>[];
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
      items.addAll(data.map((e) => fromJson(Map<String, dynamic>.from(e as Map))));
      if (!hasNext) break;
      page++;
    }
    return items;
  }

  Future<void> create(Map<String, dynamic> body) => _apiClient.post(path, body: body);

  Future<void> update(String id, Map<String, dynamic> body) => _apiClient.patch('$path/$id', body: body);

  Future<void> deactivate(String id) => _apiClient.patch('$path/$id/deactivate');
}
