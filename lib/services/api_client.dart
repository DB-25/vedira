import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/logger.dart';

class ApiClient {
  static const String _tag = 'ApiClient';
  final AuthService _authService = AuthService.instance;

  // Singleton pattern
  static ApiClient? _instance;
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal();

  /// Make an authenticated GET request
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _makeRequest('GET', url, headers: headers);
  }

  /// Make an authenticated POST request
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _makeRequest('POST', url, headers: headers, body: body);
  }

  /// Make an authenticated PUT request
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _makeRequest('PUT', url, headers: headers, body: body);
  }

  /// Make an authenticated DELETE request
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    return _makeRequest('DELETE', url, headers: headers);
  }

  /// Core method that handles authentication and token refresh
  Future<http.Response> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // Prepare headers
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Add authorization header if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final accessToken = await _authService.getAccessToken();
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
        Logger.d(_tag, 'Added Authorization header to $method request');
      }
    }

    // Make the initial request
    http.Response response = await _executeRequest(
      method,
      url,
      headers: requestHeaders,
      body: body,
    );

    // Handle 401 Unauthorized - try token refresh
    if (response.statusCode == 401 && isLoggedIn) {
      Logger.i(_tag, 'Received 401, attempting token refresh');

      final refreshSuccess = await _authService.refreshToken();
      if (refreshSuccess) {
        Logger.i(_tag, 'Token refresh successful, retrying original request');

        // Update authorization header with new token
        final newAccessToken = await _authService.getAccessToken();
        if (newAccessToken != null) {
          requestHeaders['Authorization'] = 'Bearer $newAccessToken';

          // Retry the original request
          response = await _executeRequest(
            method,
            url,
            headers: requestHeaders,
            body: body,
          );

          Logger.d(
            _tag,
            'Retried request after token refresh, status: ${response.statusCode}',
          );
        }
      } else {
        Logger.e(_tag, 'Token refresh failed, user needs to re-authenticate');
        // Token refresh failed, user needs to log in again
        await _authService.logout();
      }
    }

    return response;
  }

  /// Execute the actual HTTP request
  Future<http.Response> _executeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse(url);

    Logger.d(_tag, 'Making $method request to: $url');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body is String ? body : jsonEncode(body),
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body is String ? body : jsonEncode(body),
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw UnsupportedError('HTTP method $method is not supported');
    }
  }

  /// Make a request without authentication (for public endpoints)
  Future<http.Response> makePublicRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    return _executeRequest(method, url, headers: requestHeaders, body: body);
  }
}
