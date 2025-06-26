import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return IconButton(
      icon: Icon(
        themeManager.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: theme.appBarTheme.foregroundColor,
      ),
      tooltip: themeManager.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      onPressed: () {
                themeManager.toggleLightDark();
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

    return IconButton(
          icon: Icon(
            themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: theme.appBarTheme.foregroundColor,
          ),
          tooltip: themeManager.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () {
            themeManager.toggleLightDark();
          },
    );
  }
} 