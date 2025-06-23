import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return PopupMenuButton<AppThemeMode>(
      icon: Icon(
        themeManager.isDarkMode 
            ? (themeManager.isPalette1 ? Icons.palette : Icons.palette_outlined)
            : (themeManager.isPalette1 ? Icons.light_mode : Icons.light_mode_outlined),
        color: theme.appBarTheme.foregroundColor,
      ),
      tooltip: 'Change Theme',
      onSelected: (AppThemeMode mode) {
        themeManager.setTheme(mode);
      },
      itemBuilder: (BuildContext context) {
        return [
          // Palette 1 Options
          PopupMenuItem<AppThemeMode>(
            value: AppThemeMode.palette1Light,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                                         color: const Color(0xFF1B5E20), // Palette 1 primary
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeManager.currentTheme == AppThemeMode.palette1Light
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: themeManager.currentTheme == AppThemeMode.palette1Light
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Icon(Icons.light_mode, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Green Light'),
              ],
            ),
          ),
          PopupMenuItem<AppThemeMode>(
            value: AppThemeMode.palette1Dark,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                                         color: const Color(0xFF2E2E2E), // Palette 1 background
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeManager.currentTheme == AppThemeMode.palette1Dark
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: themeManager.currentTheme == AppThemeMode.palette1Dark
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Icon(Icons.dark_mode, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Green Dark'),
              ],
            ),
          ),
          
          // Divider
          const PopupMenuDivider(),
          
          // Palette 2 Options
          PopupMenuItem<AppThemeMode>(
            value: AppThemeMode.palette2Light,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                                         color: const Color(0xFF1976D2), // Palette 2 primary
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeManager.currentTheme == AppThemeMode.palette2Light
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: themeManager.currentTheme == AppThemeMode.palette2Light
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Icon(Icons.light_mode, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Blue Light'),
              ],
            ),
          ),
          PopupMenuItem<AppThemeMode>(
            value: AppThemeMode.palette2Dark,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                                         color: const Color(0xFF1E1E1E), // Palette 2 background
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeManager.currentTheme == AppThemeMode.palette2Dark
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: themeManager.currentTheme == AppThemeMode.palette2Dark
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Icon(Icons.dark_mode, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Blue Dark'),
              ],
            ),
          ),
          
          // Quick actions divider
          const PopupMenuDivider(),
          
          // Quick Actions
          PopupMenuItem<AppThemeMode>(
            value: null, // Special case for toggle
            onTap: () {
              // Delay to allow popup to close
              Future.delayed(const Duration(milliseconds: 100), () {
                themeManager.toggleLightDark();
              });
            },
            child: Row(
              children: [
                Icon(
                  themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(themeManager.isDarkMode ? 'Switch to Light' : 'Switch to Dark'),
              ],
            ),
          ),
          PopupMenuItem<AppThemeMode>(
            value: null, // Special case for palette switch
            onTap: () {
              // Delay to allow popup to close
              Future.delayed(const Duration(milliseconds: 100), () {
                themeManager.switchPalette();
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 24,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(themeManager.isPalette1 ? 'Switch to Blue' : 'Switch to Green'),
              ],
            ),
          ),
        ];
      },
    );
  }
}

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Light/Dark toggle
        IconButton(
          icon: Icon(
            themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: theme.appBarTheme.foregroundColor,
          ),
          tooltip: themeManager.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () {
            themeManager.toggleLightDark();
          },
        ),
        // Palette switcher
        IconButton(
          icon: Icon(
            themeManager.isPalette1 ? Icons.palette : Icons.palette_outlined,
            color: theme.appBarTheme.foregroundColor,
          ),
          tooltip: themeManager.isPalette1 ? 'Switch to Blue Theme' : 'Switch to Green Theme',
          onPressed: () {
            themeManager.switchPalette();
          },
        ),
      ],
    );
  }
} 