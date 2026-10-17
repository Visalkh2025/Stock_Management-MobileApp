import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/token_storage_service.dart';

class ApiClient {
  ApiClient({http.Client? client, TokenStorageService? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorageService();

  final http.Client _client;
  final TokenStorageService _tokenStorage;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(() => _client.get(_uri(path, query), headers: headers));
  }

  /// GET that returns the raw bytes (a file download such as an Excel export).
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final headers = await _headers(auth: true);
    headers.remove('Content-Type');
    try {
      final response = await _client.get(_uri(path, query), headers: headers).timeout(ApiConfig.uploadTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
      _decode(response); // non-2xx: throws the API's message
      throw const ApiException(statusCode: 0, message: 'Download failed.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: 'Request timed out. Please check your connection.');
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: ${e.message}');
    } on FormatException {
      throw const ApiException(statusCode: 0, message: 'Received an unexpected response from the server.');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(
      () => _client.post(_uri(path), headers: headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  /// Multipart POST (text [fields] + optional [files]) — used where the
  /// backend takes an image upload alongside JSON-encoded fields.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final token = await _tokenStorage.getAccessToken();
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..fields.addAll(fields)
        ..files.addAll(files);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: ApiConfig.uploadTimeout);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(
      () => _client.patch(_uri(path), headers: headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(
      () => _client.put(_uri(path), headers: headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(() => _client.delete(_uri(path), headers: headers));
  }

  Future<dynamic> _send(Future<http.Response> Function() request, {Duration? timeout}) async {
    try {
      final response = await request().timeout(timeout ?? ApiConfig.timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: 'Request timed out. Please check your connection.');
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: ${e.message}');
    } on FormatException {
      throw const ApiException(statusCode: 0, message: 'Received an unexpected response from the server.');
    }
  }

  dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;
    final decodedBody = response.body.isEmpty ? null : jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    var message = 'Something went wrong. Please try again.';
    if (decodedBody is Map && decodedBody['message'] != null) {
      final raw = decodedBody['message'];
      message = raw is List ? raw.join(', ') : raw.toString();
    }
    // Bulk imports answer with {message, errors: [row problems]}: show them.
    if (decodedBody is Map && decodedBody['errors'] is List) {
      final problems = (decodedBody['errors'] as List).map((e) => e.toString()).toList();
      if (problems.isNotEmpty) {
        message = '$message\n• ${problems.take(8).join('\n• ')}${problems.length > 8 ? '\n…' : ''}';
      }
    }

    throw ApiException(statusCode: statusCode, message: message);
  }
}
