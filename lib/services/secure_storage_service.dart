import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class SecureStorageService {
  static const SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  const SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _tag = 'SecureStorageService';

  /// Save user credentials securely
  Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      if (rememberMe) {
        await _storage.write(key: _emailKey, value: email);
        await _storage.write(key: _passwordKey, value: password);
        await _storage.write(key: _rememberMeKey, value: 'true');
        Logger.i(_tag, 'Credentials saved securely');
      } else {
        // If remember me is false, clear any existing credentials
        await clearCredentials();
      }
    } catch (e) {
      Logger.e(_tag, 'Error saving credentials', error: e);
      rethrow;
    }
  }

  /// Get saved credentials
  Future<SavedCredentials?> getSavedCredentials() async {
    try {
      final rememberMe = await _storage.read(key: _rememberMeKey);

      if (rememberMe != 'true') {
        return null;
      }

      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);

      if (email != null && password != null) {
        // Safe email logging - handle edge cases
        final emailDisplay =
            email.contains('@')
                ? '${email.substring(0, email.indexOf('@'))}***'
                : 'user***';
        Logger.i(_tag, 'Retrieved saved credentials for: $emailDisplay');
        return SavedCredentials(
          email: email,
          password: password,
          rememberMe: true,
        );
      }

      return null;
    } catch (e) {
      Logger.e(_tag, 'Error retrieving credentials', error: e);
      return null;
    }
  }

  /// Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final rememberMe = await _storage.read(key: _rememberMeKey);
      return rememberMe == 'true';
    } catch (e) {
      Logger.e(_tag, 'Error checking remember me status', error: e);
      return false;
    }
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      await _storage.delete(key: _rememberMeKey);
      Logger.i(_tag, 'Credentials cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing credentials', error: e);
      rethrow;
    }
  }

  /// Clear all stored data (for logout or app reset)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      Logger.i(_tag, 'All secure storage cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing all storage', error: e);
      rethrow;
    }
  }
}

class SavedCredentials {
  final String email;
  final String password;
  final bool rememberMe;

  const SavedCredentials({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  String toString() {
    final emailDisplay =
        email.contains('@')
            ? '${email.substring(0, email.indexOf('@'))}***'
            : 'user***';
    return 'SavedCredentials(email: $emailDisplay, rememberMe: $rememberMe)';
  }
}
