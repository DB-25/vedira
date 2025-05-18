import 'package:flutter/material.dart';
import 'constants.dart';

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
  primaryColor: AppConstants.primaryColorLight,
  scaffoldBackgroundColor: AppConstants.backgroundColorLight,
  cardColor: AppConstants.cardColorLight,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: AppConstants.textColorLight),
    bodyMedium: TextStyle(color: AppConstants.textColorSecondaryLight),
  ),
  colorScheme: ColorScheme.light(
    primary: AppConstants.primaryColorLight,
    secondary: AppConstants.accentColorLight,
    surface: AppConstants.cardColorLight,
    error: Color(0xFFE57373),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppConstants.textColorLight,
    onError: Colors.white,
  ),
);

// Dark Theme
final ThemeData lessonBuddyDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppConstants.primaryColorDark,
  scaffoldBackgroundColor: AppConstants.backgroundColorDark,
  cardColor: AppConstants.cardColorDark,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: AppConstants.textColorDark),
    bodyMedium: TextStyle(color: AppConstants.textColorSecondaryDark),
  ),
  colorScheme: ColorScheme.dark(
    primary: AppConstants.primaryColorDark,
    secondary: AppConstants.accentColorDark,
    surface: AppConstants.cardColorDark,
    error: Color(0xFFFF8A80),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: AppConstants.textColorDark,
    onError: Colors.black,
  ),
);
