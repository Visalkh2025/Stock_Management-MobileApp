/// Thrown by [ApiClient] for every non-2xx response and every network-level
/// failure (timeout, no connection, etc.). Catch this one type anywhere a
/// Service call can fail instead of guessing at http/dio internals.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  /// The HTTP status code, or 0 for a network/timeout failure that never
  /// got a response at all.
  final int statusCode;
  final String message;

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  /// The single, reusable place every status code gets turned into an
  /// [ApiException]. [ApiClient] calls this for every non-2xx response so
  /// the status-code -> message mapping lives in exactly one spot instead
  /// of being re-decided at each call site (or, worse, in each screen).
  ///
  /// Priority order: use the server's own `message` first — NestJS sends
  /// one on almost every error (validation errors, ConflictException,
  /// UnauthorizedException, ...) — and only fall back to a generic,
  /// status-specific message when there isn't one, e.g. a proxy/gateway
  /// error that never reaches NestJS at all, or a network failure.
  factory ApiException.fromResponse(int statusCode, dynamic decodedBody) {
    final serverMessage = _extractServerMessage(decodedBody);
    return ApiException(
      statusCode: statusCode,
      message: serverMessage ?? _fallbackMessage(statusCode),
    );
  }

  static String? _extractServerMessage(dynamic decodedBody) {
    if (decodedBody is! Map || decodedBody['message'] == null) return null;
    // class-validator errors come back as a List<String>; everything else
    // (ConflictException, UnauthorizedException, ...) as a single String.
    final raw = decodedBody['message'];
    return raw is List ? raw.join(', ') : raw.toString();
  }

  static String _fallbackMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'The request was invalid. Please check your input.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return "You don't have permission to do that.";
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This already exists.';
      case 422:
        return 'Some fields are invalid.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'The server ran into a problem. Please try again shortly.';
      case 502:
      case 503:
      case 504:
        return 'The server is temporarily unavailable. Please try again shortly.';
      default:
        return 'Something went wrong (status $statusCode). Please try again.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
