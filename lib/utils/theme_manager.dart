import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'logger.dart';
import 'constants.dart';

// =========================
// THEME MODE ENUM
// =========================
enum AppThemeMode {
  light,
  dark,
}

// =========================
// COLOR SCHEME EXTENSIONS
// =========================
extension AppColorScheme on ColorScheme {
  Color get success => brightness == Brightness.dark
      ? AppConstants.paletteSuccessDark
      : AppConstants.paletteSuccessLight;
  
  Color get warning => brightness == Brightness.dark
      ? AppConstants.paletteWarningDark
      : AppConstants.paletteWarningLight;
  
  Color get error => brightness == Brightness.dark
      ? AppConstants.paletteErrorDark
      : AppConstants.paletteErrorLight;

  // Action color for stars, start learning buttons
  Color get action => AppConstants.paletteAction;

  // App bar background with primary tint
  Color get appBarBackground => brightness == Brightness.light
      ? Color.alphaBlend(primary.withValues(alpha: 0.5), surface)
      : Color.alphaBlend(primary.withValues(alpha: 0.5), surface);

  // Body background with subtle primary tint
  Color get bodyBackground => brightness == Brightness.light
      ? Color.alphaBlend(primary.withValues(alpha: 0.1), surface)
      : Color.alphaBlend(surface.withValues(alpha: 0.9), surface);

  // Consistent card color with glass-morphism effect
  Color get cardColor => brightness == Brightness.light
      ? Color.alphaBlend(surface.withValues(alpha: 0.85), const Color(0xFFFFFFFF))
      : Color.alphaBlend( const Color(0xFFFFFFFF).withValues(alpha: 0.1), surface);
}

// =========================
// THEME MANAGER CLASS
// =========================
class ThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme_mode';
  static const String _tag = 'ThemeManager';

  AppThemeMode _currentTheme = AppThemeMode.light; // Default: Light mode
  bool _initialized = false;
  SharedPreferences? _prefs;
  final Completer<void> _initializedCompleter = Completer<void>();

  ThemeManager({SharedPreferences? prefs}) {
    _prefs = prefs;
    _initialize();
  }

  bool get isInitialized => _initialized;
  Future<void> get initialized => _initializedCompleter.future;
  AppThemeMode get currentTheme => _currentTheme;
  bool get isDarkMode => _currentTheme == AppThemeMode.dark;

  String get currentThemeName {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _initialize() async {
    Logger.i(_tag, 'Initializing ThemeManager');

    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
        Logger.i(_tag, 'SharedPreferences initialized successfully');
      } else {
        Logger.i(_tag, 'Using pre-initialized SharedPreferences');
      }

      await _loadThemePreference();
    } catch (e) {
      Logger.e(_tag, 'Error initializing SharedPreferences', error: e);
      _currentTheme = AppThemeMode.light;
      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> _loadThemePreference() async {
    if (_prefs == null) {
      Logger.w(_tag, 'Cannot load preferences - SharedPreferences not initialized');
      _currentTheme = AppThemeMode.light;
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
        _currentTheme = AppThemeMode.values.firstWhere(
          (theme) => theme.toString() == savedTheme,
          orElse: () => AppThemeMode.light,
        );
      }

      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      Logger.i(_tag, 'Theme initialized to: ${_currentTheme.toString()}');
      notifyListeners();
    } catch (e) {
      Logger.e(_tag, 'Error loading theme preference', error: e);
      _currentTheme = AppThemeMode.light;
      _initialized = true;
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeMode theme) async {
    if (_currentTheme == theme) return;

    Logger.i(_tag, 'Setting theme to: ${theme.toString()}');
    _currentTheme = theme;
    await _saveThemePreference(theme);
    notifyListeners();
  }

  Future<void> toggleLightDark() async {
    AppThemeMode newTheme;
    switch (_currentTheme) {
      case AppThemeMode.light:
        newTheme = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        newTheme = AppThemeMode.light;
        break;
    }
    await setTheme(newTheme);
  }

  Future<void> _saveThemePreference(AppThemeMode theme) async {
    if (_prefs == null) {
      Logger.w(_tag, 'Cannot save preferences - SharedPreferences not initialized');
      return;
    }

    try {
      Logger.d(_tag, 'Saving theme preference: ${theme.toString()}');
      await _prefs!.setString(_themePreferenceKey, theme.toString());
    } catch (e) {
      Logger.e(_tag, 'Error saving theme preference', error: e);
    }
  }

  // =========================
  // THEME DATA GENERATION
  // =========================

  ThemeData get lightTheme {
    final ColorScheme colorScheme = _createColorScheme(false);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _createVediraTextTheme(),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary, // Primary buttons use secondary color
          foregroundColor: colorScheme.onSecondary,
          surfaceTintColor: Colors.transparent,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  ThemeData get darkTheme {
    final ColorScheme colorScheme = _createColorScheme(true);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _createVediraTextTheme(),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary, // Primary buttons use secondary color
          foregroundColor: colorScheme.onSecondary,
          surfaceTintColor: Colors.transparent,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  ThemeMode get themeMode {
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // =========================
  // COLOR SCHEME CREATION
  // =========================

  ColorScheme _createColorScheme(bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppConstants.palettePrimary, // App bar, with tint for bg
      onPrimary: AppConstants.paletteNeutral000,
      secondary: AppConstants.paletteSecondary, // Primary buttons, primary action
      onSecondary: AppConstants.paletteNeutral000,
      tertiary: AppConstants.paletteTertiary, // Secondary actions
      onTertiary: AppConstants.paletteNeutral900,
      error: AppConstants.paletteErrorMain,
      onError: AppConstants.paletteNeutral000,
      // surface: isDark 
      //     ? AppConstants.paletteNeutral900
      //     : AppConstants.paletteNeutral000,
      surface: isDark ? AppConstants.paletteNeutral900 : AppConstants.paletteNeutral000,
      onSurface: isDark 
          ? AppConstants.paletteNeutral100
          : AppConstants.paletteNeutral900,
      surfaceContainerHighest: isDark
          ? AppConstants.paletteNeutral800
          : AppConstants.paletteNeutral100,
      outline: isDark 
          ? AppConstants.paletteNeutral600
          : AppConstants.paletteNeutral400,
      outlineVariant: isDark
          ? AppConstants.paletteNeutral700
          : AppConstants.paletteNeutral300,
      shadow: AppConstants.paletteNeutral900,
      scrim: AppConstants.paletteNeutral900,
      inverseSurface: isDark
          ? AppConstants.paletteNeutral100
          : AppConstants.paletteNeutral800,
      onInverseSurface: isDark
          ? AppConstants.paletteNeutral800
          : AppConstants.paletteNeutral100,
      inversePrimary: isDark
          ? AppConstants.palettePrimary
          : AppConstants.palettePrimary,
      primaryContainer: isDark
          ? AppConstants.paletteSuccessDark
          : AppConstants.paletteSuccessLight,
      onPrimaryContainer: isDark
          ? AppConstants.paletteNeutral100
          : AppConstants.paletteNeutral900,
      secondaryContainer: isDark
          ? AppConstants.paletteNeutral800
          : AppConstants.paletteNeutral200,
      onSecondaryContainer: isDark
          ? AppConstants.paletteNeutral200
          : AppConstants.paletteNeutral800,
      tertiaryContainer: isDark
          ? AppConstants.paletteSuccessDark
          : AppConstants.paletteSuccessLight,
      onTertiaryContainer: isDark
          ? AppConstants.paletteNeutral100
          : AppConstants.paletteNeutral900,
      errorContainer: isDark
          ? AppConstants.paletteErrorDark
          : AppConstants.paletteErrorLight,
      onErrorContainer: isDark
          ? AppConstants.paletteNeutral100
          : AppConstants.paletteNeutral900,
      onSurfaceVariant: isDark
          ? AppConstants.paletteNeutral300
          : AppConstants.paletteNeutral700,
    );
  }

  // =========================
  // THEME DATA CONSTRUCTION
  // =========================

  TextTheme _createVediraTextTheme() {
    return TextTheme(
      // Display styles - Inter
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),

      // Headline styles - Inter
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),

      // Title styles - Inter
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),

      // Body styles - Poppins
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),

      // Label styles - Poppins
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
