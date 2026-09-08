import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_token_storage.dart';

typedef SessionExpiredCallback = void Function();

class ApiClient {
  final AppConfig config;
  final ISecureTokenStorage storage;
  final http.Client _httpClient;
  final Duration timeout;
  SessionExpiredCallback? onSessionExpired;

  // Single-flight token refresh mutex to avoid concurrent rotation attempts
  Completer<bool>? _refreshCompleter;

  ApiClient({
    required this.config,
    required this.storage,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
    this.onSessionExpired,
  }) : _httpClient = httpClient ?? http.Client();

  String get baseUrl => config.apiBaseUrl;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _sendWithRetry({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    final response = await _rawRequest(
      method: method,
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      requiresAuth: requiresAuth,
    );

    // 401 Interception & Token Refresh
    if (response.statusCode == 401 && requiresAuth && !isRetry) {
      final refreshed = await _executeTokenRefresh();
      if (refreshed) {
        // Retry the original request once with rotated token
        return _sendWithRetry(
          method: method,
          endpoint: endpoint,
          headers: headers,
          queryParameters: queryParameters,
          body: body,
          requiresAuth: requiresAuth,
          isRetry: true,
        );
      } else {
        await storage.clearTokens();
        onSessionExpired?.call();
        throw const UnauthorizedException(
          message: 'Session has expired. Please log in again.',
        );
      }
    }

    return _processResponse(response);
  }

  Future<http.Response> _rawRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$baseUrl$cleanEndpoint');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParameters.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    }

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };

    if (requiresAuth) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final bodyString = body != null ? jsonEncode(body) : null;
      http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient.post(uri, headers: requestHeaders, body: bodyString).timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient.put(uri, headers: requestHeaders, body: bodyString).timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: requestHeaders).timeout(timeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      return response;
    } on TimeoutException {
      throw const TimeoutException();
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Unable to connect to server at $baseUrl (${e.message.isNotEmpty ? e.message : "Connection refused"}). Ensure Django backend is running on port 8000.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(message: 'Connection failed: ${e.toString()}');
    }
  }

  /// Single-flight mutex token refresh flow
  Future<bool> _executeTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final refreshUri = Uri.parse('$baseUrl/auth/refresh/');
      final response = await _httpClient
          .post(
            refreshUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final tokens = data['data'] ?? data;
        final newAccess = tokens['access_token']?.toString();
        final newRefresh = tokens['refresh_token']?.toString();
        final expiresAt = tokens['refresh_token_expires_at']?.toString();

        if (newAccess != null && newRefresh != null) {
          await storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
            expiresAt: expiresAt,
          );
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      // If refresh failed (401, replay, expired)
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    if (response.body.isNotEmpty) {
      try {
        jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        jsonBody = {'message': response.body};
      }
    } else {
      jsonBody = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    if (jsonBody is Map<String, dynamic>) {
      throw ApiException.fromJson(jsonBody, response.statusCode);
    }

    throw ApiException(
      message: 'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}
