import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

// Authentication event types
enum AuthEventType { loginRequired, tokenRefreshed, loggedOut }

class AuthEvent {
  final AuthEventType type;
  final String? message;

  AuthEvent(this.type, {this.message});
}

class AuthService {
  static const String _tag = 'AuthService';
  static const String _baseUrl =
      'https://i7cicaxvzf.execute-api.us-east-1.amazonaws.com';

  // Token keys for SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static AuthService? _instance;
  SharedPreferences? _prefs;

  // Stream controller for authentication state changes
  final StreamController<AuthEvent> _authEventController =
      StreamController<AuthEvent>.broadcast();

  // Stream for UI to listen to auth events
  Stream<AuthEvent> get authEvents => _authEventController.stream;

  AuthService._internal();

  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Store tokens in SharedPreferences
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required String idToken,
  }) async {
    await _initPrefs();
    final expiry = DateTime.now().add(const Duration(seconds: 3600));

    await _prefs!.setString(_accessTokenKey, accessToken);
    await _prefs!.setString(_refreshTokenKey, refreshToken);
    await _prefs!.setString(_idTokenKey, idToken);
    await _prefs!.setString(_tokenExpiryKey, expiry.toIso8601String());

    Logger.i(_tag, 'Tokens stored successfully');
  }

  // Get access token from SharedPreferences
  Future<String?> getAccessToken() async {
    await _initPrefs();
    return _prefs!.getString(_accessTokenKey);
  }

  // Get refresh token from SharedPreferences
  Future<String?> getRefreshToken() async {
    await _initPrefs();
    return _prefs!.getString(_refreshTokenKey);
  }

  // Get ID token from SharedPreferences
  Future<String?> getIdToken() async {
    await _initPrefs();
    return _prefs!.getString(_idTokenKey);
  }

  // Check if user is logged in (has valid access token)
  Future<bool> isLoggedIn() async {
    await _initPrefs();
    final accessToken = _prefs!.getString(_accessTokenKey);
    final expiryString = _prefs!.getString(_tokenExpiryKey);

    if (accessToken == null || expiryString == null) {
      return false;
    }

    try {
      final expiry = DateTime.parse(expiryString);
      final isExpired = DateTime.now().isAfter(expiry);

      if (isExpired) {
        Logger.d(_tag, 'Access token has expired');
        return false;
      }

      return true;
    } catch (e) {
      Logger.e(_tag, 'Error parsing token expiry', error: e);
      return false;
    }
  }

  // Sign up a new user
  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String phoneNumber,
  ) async {
    const endpoint = '/prod/auth/signup';
    final url = '$_baseUrl$endpoint';

    Logger.i(_tag, 'Attempting signup for email: $email');

    final requestBody = {
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        Logger.i(_tag, 'Signup successful for email: $email');

        final username = responseData['userSub'] ?? responseData['username'];
        Logger.d(
          _tag,
          'Extracted username/userSub for verification: $username',
        );

        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Account created successfully. Please check your email for verification code.',
          'username': username,
        };
      } else {
        final errorMessage =
            responseData['message'] ?? responseData['error'] ?? 'Signup failed';
        Logger.e(_tag, 'Signup failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      Logger.e(_tag, 'Signup error', error: e);
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Verify email code after signup
  Future<Map<String, dynamic>> verifyCode(String username, String code) async {
    const endpoint = '/prod/auth/verify-code';
    final url = '$_baseUrl$endpoint';

    Logger.i(_tag, 'Attempting code verification for username: $username');

    final requestBody = {'username': username, 'confirmation_code': code};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        Logger.i(_tag, 'Code verification successful for username: $username');
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Email verified successfully. You can now sign in.',
        };
      } else {
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Verification failed';
        Logger.e(_tag, 'Code verification failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      Logger.e(_tag, 'Code verification error', error: e);
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Resend verification code
  Future<Map<String, dynamic>> resendCode(String username) async {
    const endpoint = '/prod/auth/resend-verification-code';
    final url = '$_baseUrl$endpoint';

    Logger.i(_tag, 'Attempting to resend code for username: $username');

    final requestBody = {'username': username};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        Logger.i(_tag, 'Code resent successfully for username: $username');
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Verification code resent successfully.',
        };
      } else {
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Failed to resend code';
        Logger.e(_tag, 'Resend code failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      Logger.e(_tag, 'Resend code error', error: e);
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Sign in user
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    const endpoint = '/prod/auth/signin';
    final url = '$_baseUrl$endpoint';

    Logger.i(_tag, 'Attempting signin for email: $email');

    final requestBody = {'email': email, 'password': password};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Extract tokens from response
        final authResult =
            responseData['authenticationResult'] as Map<String, dynamic>?;

        if (authResult != null) {
          final accessToken = authResult['AccessToken'] as String?;
          final refreshToken = authResult['RefreshToken'] as String?;
          final idToken = authResult['IdToken'] as String?;

          if (accessToken != null && refreshToken != null && idToken != null) {
            await _storeTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
              idToken: idToken,
            );

            Logger.i(_tag, 'Signin successful for email: $email');
            return {'success': true, 'message': 'Login successful'};
          }
        }

        Logger.e(_tag, 'Invalid response format: missing tokens');
        Logger.e(_tag, 'Full response structure: $responseData');
        return {
          'success': false,
          'message': 'Login failed: Invalid response from server',
        };
      } else {
        final errorMessage =
            responseData['message'] ?? responseData['error'] ?? 'Login failed';
        Logger.e(_tag, 'Signin failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      Logger.e(_tag, 'Signin error', error: e);
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Refresh access token
  Future<bool> refreshToken() async {
    const endpoint = '/prod/auth/refresh-token';
    final url = '$_baseUrl$endpoint';

    Logger.i(_tag, 'Attempting to refresh token');

    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        Logger.e(_tag, 'No refresh token available');
        return false;
      }

      final requestBody = {'refresh_token': refreshTokenValue};

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final authResult =
            responseData['authenticationResult'] as Map<String, dynamic>?;

        if (authResult != null) {
          final accessToken = authResult['AccessToken'] as String?;
          final idToken = authResult['IdToken'] as String?;

          if (accessToken != null && idToken != null) {
            // Store new tokens (keep existing refresh token)
            await _initPrefs();
            final expiry = DateTime.now().add(const Duration(seconds: 3600));

            await _prefs!.setString(_accessTokenKey, accessToken);
            await _prefs!.setString(_idTokenKey, idToken);
            await _prefs!.setString(_tokenExpiryKey, expiry.toIso8601String());

            Logger.i(_tag, 'Token refresh successful');
            _authEventController.add(AuthEvent(AuthEventType.tokenRefreshed));
            return true;
          }
        }

        Logger.e(_tag, 'Invalid refresh response format: missing tokens');
        Logger.e(_tag, 'Full refresh response structure: $responseData');
        return false;
      } else {
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Token refresh failed';
        Logger.e(_tag, 'Token refresh failed: $errorMessage');
        return false;
      }
    } catch (e) {
      Logger.e(_tag, 'Token refresh error', error: e);
      return false;
    }
  }

  // Logout user (clear all tokens)
  Future<void> logout() async {
    await _initPrefs();

    await _prefs!.remove(_accessTokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_idTokenKey);
    await _prefs!.remove(_tokenExpiryKey);

    Logger.i(_tag, 'User logged out successfully');

    // Notify UI about logout
    _authEventController.add(AuthEvent(AuthEventType.loggedOut));
  }

  // Notify UI that login is required
  void notifyLoginRequired(String reason) {
    Logger.i(_tag, 'Login required: $reason');
    _authEventController.add(
      AuthEvent(AuthEventType.loginRequired, message: reason),
    );
  }

  // Dispose resources
  void dispose() {
    _authEventController.close();
  }
}
