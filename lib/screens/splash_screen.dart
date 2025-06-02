import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Initializing splash screen');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    Logger.i(_tag, 'Waiting for theme to initialize');

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
    final isLoggedIn = await _authService.isLoggedIn();
    Logger.i(_tag, 'User logged in: $isLoggedIn');

    if (isLoggedIn) {
      // User is logged in, preload courses
      Logger.i(_tag, 'User is authenticated, preloading courses');
      _coursesFuture = _apiService.getCourseList();

      try {
        final courses = await _coursesFuture;
        Logger.i(_tag, 'Preloaded ${courses.length} courses successfully');
      } catch (e) {
        Logger.e(_tag, 'Error preloading courses', error: e);
        // Continue with empty courses list
        _coursesFuture = Future.value([]);
      }
    }

    if (!mounted) return;

    Logger.i(_tag, 'App initialization complete');
    setState(() {
      _initialized = true;
    });
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
              'Lesson Buddy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
