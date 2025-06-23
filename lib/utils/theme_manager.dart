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
  palette1Light,
  palette1Dark,
  palette2Light,
  palette2Dark,
}

// =========================
// COLOR SCHEME EXTENSIONS
// =========================
extension AppColorScheme on ColorScheme {
  Color get success => brightness == Brightness.dark
      ? AppConstants.palette1Success
      : AppConstants.palette1Success;
  
  Color get warning => brightness == Brightness.dark
      ? AppConstants.palette1Warning
      : AppConstants.palette1Warning;
  
  Color get highlight => brightness == Brightness.dark
      ? AppConstants.palette2Highlight
      : AppConstants.palette2Highlight;
  
  Color get danger => brightness == Brightness.dark
      ? AppConstants.palette2Danger
      : AppConstants.palette2Danger;
}

// =========================
// THEME MANAGER CLASS
// =========================
class ThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme_mode';
  static const String _tag = 'ThemeManager';

  AppThemeMode _currentTheme = AppThemeMode.palette2Dark; // Default: Palette 2 + Dark mode
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
  bool get isDarkMode => _currentTheme == AppThemeMode.palette1Dark || _currentTheme == AppThemeMode.palette2Dark;
  bool get isPalette1 => _currentTheme == AppThemeMode.palette1Light || _currentTheme == AppThemeMode.palette1Dark;
  bool get isPalette2 => _currentTheme == AppThemeMode.palette2Light || _currentTheme == AppThemeMode.palette2Dark;

  String get currentThemeName {
    switch (_currentTheme) {
      case AppThemeMode.palette1Light:
        return 'Green Light';
      case AppThemeMode.palette1Dark:
        return 'Green Dark';
      case AppThemeMode.palette2Light:
        return 'Blue Light';
      case AppThemeMode.palette2Dark:
        return 'Blue Dark';
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
      _currentTheme = AppThemeMode.palette2Dark;
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
      _currentTheme = AppThemeMode.palette2Dark;
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
          orElse: () => AppThemeMode.palette2Dark,
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
      _currentTheme = AppThemeMode.palette2Dark;
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
      case AppThemeMode.palette1Light:
        newTheme = AppThemeMode.palette1Dark;
        break;
      case AppThemeMode.palette1Dark:
        newTheme = AppThemeMode.palette1Light;
        break;
      case AppThemeMode.palette2Light:
        newTheme = AppThemeMode.palette2Dark;
        break;
      case AppThemeMode.palette2Dark:
        newTheme = AppThemeMode.palette2Light;
        break;
    }
    await setTheme(newTheme);
  }

  Future<void> switchPalette() async {
    AppThemeMode newTheme;
    switch (_currentTheme) {
      case AppThemeMode.palette1Light:
        newTheme = AppThemeMode.palette2Light;
        break;
      case AppThemeMode.palette1Dark:
        newTheme = AppThemeMode.palette2Dark;
        break;
      case AppThemeMode.palette2Light:
        newTheme = AppThemeMode.palette1Light;
        break;
      case AppThemeMode.palette2Dark:
        newTheme = AppThemeMode.palette1Dark;
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
    final ColorScheme colorScheme = _currentTheme == AppThemeMode.palette1Light ||
            _currentTheme == AppThemeMode.palette1Dark
        ? _createPalette1ColorScheme(false)
        : _createPalette2ColorScheme(false);

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
        shadowColor: colorScheme.shadow.withOpacity(0.1),
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
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
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
    final ColorScheme colorScheme = _currentTheme == AppThemeMode.palette1Light ||
            _currentTheme == AppThemeMode.palette1Dark
        ? _createPalette1ColorScheme(true)
        : _createPalette2ColorScheme(true);

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
        shadowColor: colorScheme.shadow.withOpacity(0.1),
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
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
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
  // ACCESSIBILITY-FOCUSED COLOR SCHEMES
  // =========================

  ColorScheme _createPalette1ColorScheme(bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppConstants.palette1Primary,
      onPrimary: Colors.white,
      secondary: AppConstants.palette1Secondary,
      onSecondary: Colors.white,
      tertiary: AppConstants.palette1PrimaryLight,
      onTertiary: Colors.white,
      error: AppConstants.palette1Accent,
      onError: Colors.white,
      surface: isDark 
          ? AppConstants.palette1Background
          : const Color(0xFFFFFBFE),
      onSurface: isDark 
          ? const Color(0xFFE8E8E8)
          : const Color(0xFF1C1B1F),
      surfaceContainerHighest: isDark
          ? AppConstants.palette1Surface
          : const Color(0xFFE6E0E9),
      outline: isDark 
          ? const Color(0xFF938F99)
          : const Color(0xFF79747E),
      outlineVariant: isDark
          ? const Color(0xFF49454F)
          : const Color(0xFFCAC4D0),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: isDark
          ? const Color(0xFFE6E1E5)
          : const Color(0xFF313033),
      onInverseSurface: isDark
          ? const Color(0xFF313033)
          : const Color(0xFFF4EFF4),
      inversePrimary: isDark
          ? AppConstants.palette1PrimaryLight
          : AppConstants.palette1Primary,
      primaryContainer: isDark
          ? const Color(0xFF0F3A1A)
          : const Color(0xFFC8E6C9),
      onPrimaryContainer: isDark
          ? AppConstants.palette1PrimaryLight
          : AppConstants.palette1Primary,
      secondaryContainer: isDark
          ? const Color(0xFF4A0E22)
          : const Color(0xFFF8BBD0),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFCDD2)
          : const Color(0xFF880E4F),
      tertiaryContainer: isDark
          ? const Color(0xFF1B4A1F)
          : const Color(0xFFC8E6C9),
      onTertiaryContainer: isDark
          ? AppConstants.palette1Success
          : const Color(0xFF2E7D32),
      errorContainer: isDark
          ? const Color(0xFF4A1A1A)
          : const Color(0xFFFFCDD2),
      onErrorContainer: isDark
          ? const Color(0xFFFF8A80)
          : const Color(0xFFB71C1C),
      onSurfaceVariant: isDark
          ? const Color(0xFFCAC4D0)
          : const Color(0xFF49454F),
    );
  }

  ColorScheme _createPalette2ColorScheme(bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppConstants.palette2Primary,
      onPrimary: Colors.white,
      secondary: AppConstants.palette2Secondary,
      onSecondary: Colors.white,
      tertiary: AppConstants.palette2Accent,
      onTertiary: Colors.black,
      error: AppConstants.palette2Danger,
      onError: Colors.white,
      surface: isDark 
          ? AppConstants.palette2Background
          : const Color(0xFFFFFBFE),
      onSurface: isDark 
          ? const Color(0xFFE8E8E8)
          : const Color(0xFF1C1B1F),
      surfaceContainerHighest: isDark
          ? AppConstants.palette2Surface
          : const Color(0xFFE6E0E9),
      outline: isDark 
          ? const Color(0xFF938F99)
          : const Color(0xFF79747E),
      outlineVariant: isDark
          ? const Color(0xFF49454F)
          : const Color(0xFFCAC4D0),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: isDark
          ? const Color(0xFFE6E1E5)
          : const Color(0xFF313033),
      onInverseSurface: isDark
          ? const Color(0xFF313033)
          : const Color(0xFFF4EFF4),
      inversePrimary: isDark
          ? AppConstants.palette2PrimaryLight
          : AppConstants.palette2Primary,
      primaryContainer: isDark
          ? const Color(0xFF0D47A1)
          : const Color(0xFFBBDEFB),
      onPrimaryContainer: isDark
          ? AppConstants.palette2PrimaryLight
          : AppConstants.palette2Primary,
      secondaryContainer: isDark
          ? const Color(0xFF616161)
          : const Color(0xFFEEEEEE),
      onSecondaryContainer: isDark
          ? const Color(0xFFE0E0E0)
          : const Color(0xFF212121),
      tertiaryContainer: isDark
          ? const Color(0xFFBF360C)
          : const Color(0xFFFFE0B2),
      onTertiaryContainer: isDark
          ? AppConstants.palette2Accent
          : const Color(0xFFE65100),
      errorContainer: isDark
          ? const Color(0xFFB71C1C)
          : const Color(0xFFFFCDD2),
      onErrorContainer: isDark
          ? const Color(0xFFFF8A80)
          : const Color(0xFFB71C1C),
      onSurfaceVariant: isDark
          ? const Color(0xFFCAC4D0)
          : const Color(0xFF49454F),
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
