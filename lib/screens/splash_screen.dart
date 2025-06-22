import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/theme_manager.dart';
import '../utils/logger.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _tag = 'SplashScreen';
  bool _initialized = false;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService.instance;
  final SecureStorageService _secureStorage = SecureStorageService();
  late Future<List<Course>> _coursesFuture;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Initializing splash screen');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    Logger.i(_tag, 'Waiting for theme to initialize');
    _updateStatus('Loading theme...');

    // Wait for theme initialization
    bool isThemeReady = false;
    try {
      await themeManager.initialized;
      isThemeReady = true;
      Logger.i(_tag, 'Theme initialized successfully');
    } catch (e) {
      Logger.e(_tag, 'Error during theme initialization', error: e);
      // Check if it's ready anyway
      isThemeReady = themeManager.isInitialized;
      if (isThemeReady) {
        Logger.i(_tag, 'Theme was already initialized');
      }
    }

    // If theme isn't ready yet, wait for it to be ready
    if (!isThemeReady) {
      Logger.i(_tag, 'Waiting for theme manager to complete initialization');
      while (!themeManager.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }
      Logger.i(_tag, 'Theme is now initialized');
    }

    // Check authentication status
    Logger.i(_tag, 'Checking authentication status');
    _updateStatus('Checking authentication...');

    bool isLoggedIn = await _authService.isLoggedIn();
    Logger.i(_tag, 'Current auth status: $isLoggedIn');

    // If not logged in, try auto-login with saved credentials
    if (!isLoggedIn) {
      Logger.i(_tag, 'Not logged in, checking for saved credentials');
      _updateStatus('Checking saved credentials...');

      try {
        final savedCredentials = await _secureStorage.getSavedCredentials();

        if (savedCredentials != null) {
          Logger.i(_tag, 'Found saved credentials, attempting auto-login');
          _updateStatus('Signing in automatically...');

          final result = await _authService.signIn(
            savedCredentials.email,
            savedCredentials.password,
          );

          if (result['success']) {
            Logger.i(_tag, 'Auto-login successful');
            isLoggedIn = true;
            _updateStatus('Login successful!');
          } else {
            Logger.w(_tag, 'Auto-login failed: ${result['message']}');
            _updateStatus('Auto-login failed, please sign in manually');
            // Clear invalid credentials
            await _secureStorage.clearCredentials();
            // Wait a moment to show the message
            await Future.delayed(const Duration(seconds: 1));
          }
        } else {
          Logger.i(_tag, 'No saved credentials found');
        }
      } catch (e) {
        Logger.e(_tag, 'Error during auto-login attempt', error: e);
        _updateStatus('Auto-login failed');
        // Clear potentially corrupted credentials
        await _secureStorage.clearCredentials();
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (isLoggedIn) {
      // User is logged in, preload courses
      Logger.i(_tag, 'User is authenticated, preloading courses');
      _updateStatus('Loading courses...');
      _coursesFuture = _apiService.getCourseList();

      try {
        final courses = await _coursesFuture;
        Logger.i(_tag, 'Preloaded ${courses.length} courses successfully');
        _updateStatus('Ready!');
      } catch (e) {
        Logger.e(_tag, 'Error preloading courses', error: e);
        // Continue with empty courses list
        _coursesFuture = Future.value([]);
        _updateStatus('Ready!');
      }
    }

    if (!mounted) return;

    Logger.i(_tag, 'App initialization complete');
    setState(() {
      _initialized = true;
    });
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Logger.i(_tag, 'Navigating to HomeScreen (authenticated)');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(preloadedCourses: _coursesFuture),
        ),
      );
    } else {
      Logger.i(_tag, 'Navigating to LoginScreen (not authenticated)');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Navigate based on authentication status once initialization is complete
    if (_initialized) {
      // Use a post-frame callback to navigate after the current frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNextScreen();
      });
    }

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? const Color(0xFF121212) // Dark mode background
              : const Color(0xFFFAFAFA), // Light mode background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(Icons.school, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Vedira',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
