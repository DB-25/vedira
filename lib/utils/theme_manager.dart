import 'package:flutter/material.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Light Theme
final ThemeData lessonBuddyLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.teal,
  scaffoldBackgroundColor: Color(0xFFFAFAFA),
  cardColor: Color(0xFFF5F5F5),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF212121)),
    bodyMedium: TextStyle(color: Color(0xFF616161)),
  ),
  colorScheme: ColorScheme.light(
    primary: Colors.teal,
    secondary: Color(0xFF7E57C2),
    surface: Color(0xFFF5F5F5),
    error: Color(0xFFE57373),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF212121),
    onError: Colors.white,
  ),
);

// Dark Theme
final ThemeData lessonBuddyDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF26D7AE),
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFECECEC)),
    bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
  ),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF26D7AE),
    secondary: Color(0xFFB388FF),
    surface: Color(0xFF1E1E1E),
    error: Color(0xFFFF8A80),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Color(0xFFECECEC),
    onError: Colors.black,
  ),
);
