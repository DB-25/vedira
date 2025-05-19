import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A utility class for logging various types of information throughout the app.
/// This logger supports different log levels and formatted output.
class Logger {
  // Log levels
  static const int VERBOSE = 0;
  static const int DEBUG = 1;
  static const int INFO = 2;
  static const int WARNING = 3;
  static const int ERROR = 4;

  // Current log level - adjust to filter logs
  static int _currentLevel = kDebugMode ? VERBOSE : INFO;

  // Enable or disable logging completely
  static bool _enabled = true;

  /// Sets the current logging level.
  /// Only logs with a level >= to this will be displayed.
  static void setLevel(int level) {
    _currentLevel = level;
  }

  /// Enables or disables logging completely.
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Logs a message at the VERBOSE level.
  static void v(String tag, String message, {Object? data}) {
    _log(VERBOSE, tag, message, data: data);
  }

  /// Logs a message at the DEBUG level.
  static void d(String tag, String message, {Object? data}) {
    _log(DEBUG, tag, message, data: data);
  }

  /// Logs a message at the INFO level.
  static void i(String tag, String message, {Object? data}) {
    _log(INFO, tag, message, data: data);
  }

  /// Logs a message at the WARNING level.
  static void w(
    String tag,
    String message, {
    Object? data,
    StackTrace? stackTrace,
  }) {
    _log(WARNING, tag, message, data: data, stackTrace: stackTrace);
  }

  /// Logs a message at the ERROR level.
  static void e(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(ERROR, tag, message, data: error, stackTrace: stackTrace);
  }

  /// Logs an API request/response with detailed formatting.
  static void api(
    String method,
    String endpoint, {
    dynamic requestBody,
    dynamic responseBody,
    int? statusCode,
    Object? error,
  }) {
    if (!_shouldLog(INFO)) return;

    final divider =
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    final timestamp = DateTime.now().toIso8601String();

    final buffer = StringBuffer();
    buffer.write('\n$divider\n');
    buffer.write('📡 API CALL: $method $endpoint\n');
    buffer.write('⏱️ TIMESTAMP: $timestamp\n');

    if (requestBody != null) {
      buffer.write('📦 REQUEST BODY:\n');
      if (requestBody is String) {
        buffer.write('$requestBody\n');
      } else {
        try {
          final prettyBody = const JsonEncoder.withIndent(
            '  ',
          ).convert(requestBody);
          buffer.write('$prettyBody\n');
        } catch (e) {
          buffer.write('${requestBody.toString()}\n');
        }
      }
    }

    if (statusCode != null) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      buffer.write('$emoji STATUS CODE: $statusCode\n');
    }

    if (responseBody != null) {
      buffer.write('📥 RESPONSE:\n');
      if (responseBody is String) {
        try {
          final json = jsonDecode(responseBody);
          final prettyResponse = const JsonEncoder.withIndent(
            '  ',
          ).convert(json);
          buffer.write('$prettyResponse\n');
        } catch (e) {
          buffer.write('$responseBody\n');
        }
      } else {
        try {
          final prettyResponse = const JsonEncoder.withIndent(
            '  ',
          ).convert(responseBody);
          buffer.write('$prettyResponse\n');
        } catch (e) {
          buffer.write('${responseBody.toString()}\n');
        }
      }
    }

    if (error != null) {
      buffer.write('⚠️ ERROR: $error\n');
    }

    buffer.write('$divider\n');

    print(buffer.toString());
  }

  // Internal logging implementation
  static void _log(
    int level,
    String tag,
    String message, {
    Object? data,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(level)) return;

    String emoji;
    switch (level) {
      case VERBOSE:
        emoji = '🔍';
        break;
      case DEBUG:
        emoji = '🐛';
        break;
      case INFO:
        emoji = 'ℹ️';
        break;
      case WARNING:
        emoji = '⚠️';
        break;
      case ERROR:
        emoji = '❌';
        break;
      default:
        emoji = '📝';
    }

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.write('$emoji [$tag] $message');

    if (data != null) {
      buffer.write('\n');
      if (data is Map || data is List) {
        try {
          final prettyData = const JsonEncoder.withIndent('  ').convert(data);
          buffer.write(prettyData);
        } catch (e) {
          buffer.write(data.toString());
        }
      } else {
        buffer.write(data.toString());
      }
    }

    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    print(buffer.toString());
  }

  // Check if we should log at this level
  static bool _shouldLog(int level) {
    return _enabled && level >= _currentLevel;
  }
}
