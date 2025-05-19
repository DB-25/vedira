
import 'package:markdown_widget/markdown_widget.dart';
import '../controllers/lesson_controller.dart';

/// Configuration for markdown rendering in lesson view
class LessonViewConfig {
  /// Get markdown widget configuration based on font size and theme
  static MarkdownConfig getMarkdownConfig({
    required FontSize fontSize,
    required bool isDarkMode,
  }) {
    // Use the appropriate base config
    return isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
  }
}
