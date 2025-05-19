import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import '../utils/logger.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _tag = 'SplashScreen';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Initializing splash screen');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    // Wait for a minimum display time
    final minSplashTime = Future.delayed(const Duration(milliseconds: 1500));

    Logger.i(_tag, 'Waiting for theme to initialize');

    // First try using the Future-based initialization
    bool isThemeReady = false;
    try {
      await themeManager.initialized.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          Logger.w(_tag, 'Theme initialization timed out, will check manually');
          return;
        },
      );
      isThemeReady = true;
      Logger.i(_tag, 'Theme initialized successfully via Future');
    } catch (e) {
      Logger.e(_tag, 'Error during theme initialization via Future', error: e);
      // Continue below with property check
    }

    // If the Future-based approach failed, use polling with the property
    if (!isThemeReady) {
      Logger.i(_tag, 'Falling back to polling isInitialized property');
      int attempts = 0;
      const maxAttempts = 30;

      while (!themeManager.isInitialized && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (themeManager.isInitialized) {
        Logger.i(
          _tag,
          'Theme initialized after $attempts polls (${attempts * 100}ms)',
        );
        isThemeReady = true;
      } else {
        Logger.w(
          _tag,
          'Theme initialization timed out after $attempts polls, proceeding anyway',
        );
      }
    }

    // Make sure the minimum splash time has elapsed
    await minSplashTime;

    if (!mounted) return;

    Logger.i(_tag, 'App initialization complete, navigating to HomeScreen');
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Navigate to HomeScreen once initialization is complete
    if (_initialized) {
      // Use a post-frame callback to navigate after the current frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
