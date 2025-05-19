import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'logger.dart';
import 'constants.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  static const String _tag = 'ThemeManager';

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode
  bool _initialized = false;
  SharedPreferences? _prefs;
  final Completer<void> _initializedCompleter = Completer<void>();

  ThemeManager({SharedPreferences? prefs}) {
    _prefs = prefs;
    _initialize();
  }

  bool get isInitialized => _initialized;
  Future<void> get initialized => _initializedCompleter.future;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _initialize() async {
    Logger.i(_tag, 'Initializing ThemeManager');

    try {
      // Only initialize SharedPreferences if not provided in constructor
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
        Logger.i(_tag, 'SharedPreferences initialized successfully');
      } else {
        Logger.i(_tag, 'Using pre-initialized SharedPreferences');
      }

      // Load saved theme
      await _loadThemePreference();
    } catch (e) {
      Logger.e(_tag, 'Error initializing SharedPreferences', error: e);

      // Set defaults and mark as initialized even if there's an error
      _themeMode = ThemeMode.dark;
      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> _loadThemePreference() async {
    if (_prefs == null) {
      Logger.w(
        _tag,
        'Cannot load preferences - SharedPreferences not initialized',
      );
      _themeMode = ThemeMode.dark;
      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      notifyListeners();
      return;
    }

    try {
      final savedTheme = _prefs!.getString(_themePreferenceKey);
      Logger.d(_tag, 'Loading saved theme preference: $savedTheme');

      if (savedTheme != null) {
        if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.dark;
        }
      }

      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      Logger.i(
        _tag,
        'Theme initialized to: ${_themeMode == ThemeMode.dark ? "dark" : "light"}',
      );
      notifyListeners();
    } catch (e) {
      Logger.e(_tag, 'Error loading theme preference', error: e);
      _themeMode = ThemeMode.dark;
      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (!_initialized) {
      Logger.w(
        _tag,
        'Attempted to toggle theme before initialization completed',
      );
      return;
    }

    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final modeString = newMode == ThemeMode.dark ? 'dark' : 'light';

    Logger.i(
      _tag,
      'Toggling theme from ${_themeMode == ThemeMode.dark ? "dark" : "light"} to $modeString',
    );

    _themeMode = newMode;
    await _saveThemePreference(newMode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    Logger.i(
      _tag,
      'Setting theme to: ${mode == ThemeMode.dark ? "dark" : "light"}',
    );
    _themeMode = mode;
    await _saveThemePreference(mode);
    notifyListeners();
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    if (_prefs == null) {
      Logger.w(
        _tag,
        'Cannot save preferences - SharedPreferences not initialized',
      );
      return;
    }

    try {
      final value = mode == ThemeMode.dark ? 'dark' : 'light';
      Logger.d(_tag, 'Saving theme preference: $value');
      await _prefs!.setString(_themePreferenceKey, value);
    } catch (e) {
      Logger.e(_tag, 'Error saving theme preference', error: e);
    }
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
