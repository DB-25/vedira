import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/logger.dart';
import 'utils/theme_manager.dart';
import 'services/push_notification_service.dart';

void main() async {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  Logger.setLevel(Logger.info);
  Logger.i('App', 'Starting Vedira app');

  // Initialize Firebase
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    Logger.i('App', 'Firebase initialized');
  } catch (e) {
    Logger.e('App', 'Firebase initialization failed', error: e);
  }

  // Register background message handler only if Firebase is ready
  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize SharedPreferences
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    Logger.i('App', 'SharedPreferences initialized successfully');
  } catch (e) {
    Logger.e('App', 'Failed to initialize SharedPreferences', error: e);
    prefs = await SharedPreferences.getInstance();
  }

  // Create theme manager instance with pre-initialized preferences
  final themeManager = ThemeManager(prefs: prefs);

  // Initialize FCM and register device token (fire-and-forget)
  // Any failures are logged to console; token will be printed when available.
  // Not awaited to avoid blocking app start.
  if (firebaseReady) {
    // ignore: unawaited_futures
    PushNotificationService.initializeAndRegister();
  } else {
    Logger.e('App', 'Skipping FCM init because Firebase is not ready');
  }

  runApp(
    ChangeNotifierProvider<ThemeManager>.value(
      value: themeManager,
      child: const VediraApp(),
    ),
  );
}

class VediraApp extends StatelessWidget {
  const VediraApp({super.key});

  // Global navigator key for authentication navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AuthWrapper(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Vedira',
        theme: themeManager.lightTheme,
        darkTheme: themeManager.darkTheme,
        themeMode: themeManager.themeMode,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService.instance;
  StreamSubscription<AuthEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authEvents.listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case AuthEventType.loginRequired:
        case AuthEventType.loggedOut:
          Logger.i(
            'AuthWrapper',
            'Authentication required, navigating to login',
          );

          // Use global navigator key to navigate from anywhere in the app
          final navigator = VediraApp.navigatorKey.currentState;
          if (navigator != null) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          } else {
            Logger.e(
              'AuthWrapper',
              'Navigator not available for auth navigation',
            );
          }
          break;
        case AuthEventType.tokenRefreshed:
          Logger.i('AuthWrapper', 'Token refreshed successfully');
          break;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Global function to show snackbar from anywhere in the app
void showGlobalSnackBar(String message, {bool isError = false}) {
  final navigator = VediraApp.navigatorKey.currentState;
  if (navigator != null) {
    final context = navigator.overlay?.context;
    if (context != null) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? theme.colorScheme.error : null,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
