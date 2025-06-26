import 'package:flutter/material.dart';

import '../utils/theme_manager.dart';

/// Custom app bar component with consistent styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool showLogo;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 5,
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'lib/assets/transparent_logo_no_text.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text(
                    title.length > 1 ? title.substring(1) : title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: colorScheme.appBarBackground,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      actions: actions,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Custom sliver app bar component with consistent styling
class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double? expandedHeight;
  final bool showLogo;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 5),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'lib/assets/transparent_logo_no_text.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    title.length > 1 ? title.substring(1) : title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: colorScheme.appBarBackground,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      actions: actions,
      leading: leading,
    );
  }
}
