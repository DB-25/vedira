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

    // Add authorization header if we have an ID token
    final idToken = await _authService.getIdToken();
    if (idToken != null) {
      requestHeaders['Authorization'] = 'Bearer $idToken';
      Logger.d(
        _tag,
        'Added Authorization header (ID token) to $method request',
      );
    }

    // Make the initial request
    http.Response response = await _executeRequest(
      method,
      url,
      headers: requestHeaders,
      body: body,
    );

    // Handle 401 Unauthorized - try token refresh if we have tokens
    if (response.statusCode == 401) {
      Logger.i(_tag, 'Received 401 Unauthorized, attempting token refresh');

      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken != null) {
        Logger.d(_tag, 'Refresh token available, attempting refresh');
        final refreshSuccess = await _authService.refreshToken();
        if (refreshSuccess) {
          Logger.i(_tag, 'Token refresh successful, retrying original request');

          // Update authorization header with new token
          final newIdToken = await _authService.getIdToken();
          if (newIdToken != null) {
            requestHeaders['Authorization'] = 'Bearer $newIdToken';

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
          } else {
            Logger.e(_tag, 'No new ID token available after refresh');
            await _handleAuthFailure();
          }
        } else {
          Logger.e(_tag, 'Token refresh failed, logging out user');
          await _handleAuthFailure();
        }
      } else {
        Logger.e(_tag, 'No refresh token available, logging out user');
        await _handleAuthFailure();
      }
    }

    return response;
  }

  /// Handle authentication failure by logging out and notifying the user
  Future<void> _handleAuthFailure() async {
    Logger.i(_tag, 'Handling authentication failure');
    await _authService.logout();

    // Small delay to ensure logout cleanup is complete
    await Future.delayed(const Duration(milliseconds: 100));

    _authService.notifyLoginRequired('Authentication token expired');
    Logger.i(_tag, 'User logged out due to authentication failure');

    // Note: Navigation should be handled by the UI layer listening to auth state
    // We can't navigate directly from a service class
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
