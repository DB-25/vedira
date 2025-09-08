import 'dart:convert';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles Firebase Cloud Messaging initialization and token registration.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static String? _cachedFcmToken;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<String?> initializeAndRegister() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions only on Apple platforms (Android handled separately)
    if (Platform.isIOS || Platform.isMacOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    // Retrieve FCM token
    final String? token = await messaging.getToken();
    _cachedFcmToken = token;
    // Print to console for developer to copy
    // ignore: avoid_print
    print('FCM Token: $token');

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('Notification received in foreground!');
      // ignore: avoid_print
      print('Message data: ${message.data}');
    });

    // iOS: show notifications when app is in foreground
    if (Platform.isIOS || Platform.isMacOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Send token to backend if available
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _cachedFcmToken = newToken;
      // ignore: avoid_print
      print('FCM Token refreshed: $newToken');
      await _sendTokenToBackend(newToken);
    });

    return token;
  }

  /// Ask the OS notification permission on both platforms.
  /// On Android 13+, explicitly requests runtime POST_NOTIFICATIONS.
  static Future<void> requestOsNotificationPermission() async {
    // iOS will show the system prompt via Firebase requestPermission; here we ensure Android 13+ is covered
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Request notification permissions during splash for both platforms.
  static Future<void> requestStartupPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+
      await requestOsNotificationPermission();
    } else {
      // iOS/macOS: request via Firebase
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Returns the cached FCM token if available, otherwise fetches it.
  static Future<String?> getTokenOrFetch() async {
    if (_cachedFcmToken != null) return _cachedFcmToken;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _cachedFcmToken = token;
      return token;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching FCM token: $e');
      return null;
    }
  }

  static Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://our-aws-api.com/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('Device registered successfully!');
      } else {
        // ignore: avoid_print
        print('Device registration failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error registering device: $e');
    }
  }
}

/// Top-level background message handler. Must be a global function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in background isolate
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or not required
  }
  // ignore: avoid_print
  print('BG Notification: id=${message.messageId}, data=${message.data}');
}


