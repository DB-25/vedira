import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'utils/logger.dart';
import 'utils/theme_manager.dart';

void main() async {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  Logger.setLevel(Logger.INFO);
  Logger.i('App', 'Starting LessonBuddy app');

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

  runApp(
    ChangeNotifierProvider<ThemeManager>.value(
      value: themeManager,
      child: const LessonBuddyApp(),
    ),
  );
}

class LessonBuddyApp extends StatelessWidget {
  const LessonBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'Lesson Buddy',
      theme: lessonBuddyLightTheme,
      darkTheme: lessonBuddyDarkTheme,
      themeMode: themeManager.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
