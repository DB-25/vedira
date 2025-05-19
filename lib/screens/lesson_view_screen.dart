import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../controllers/lesson_controller.dart';
import '../models/lesson.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../widgets/code_block_builder.dart';

class LessonViewScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;
  final String lessonId;
  final String lessonTitle;
  final Lesson? lesson;

  const LessonViewScreen({
    super.key,
    required this.courseId,
    required this.chapterId,
    required this.lessonId,
    required this.lessonTitle,
    this.lesson,
  });

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  final ApiService _apiService = ApiService();
  final String _tag = 'LessonViewScreen';
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tocScrollController = ScrollController();
  final TocController _tocController = TocController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _lessonContent = '';
  bool _isLoading = true;
  bool _error = false;
  bool _isCompleting = false;
  FontSize _fontSize = FontSize.medium;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadLessonContent();

    // Add scroll listener for FAB visibility
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tocScrollController.dispose();
    super.dispose();
  }

  // Track scroll position for FAB visibility
  void _scrollListener() {
    final showButton = _scrollController.offset > 300;
    if (_showScrollToTop != showButton) {
      setState(() {
        _showScrollToTop = showButton;
      });
    }
  }

  // Load lesson content from API or use provided lesson
  Future<void> _loadLessonContent() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      // Use lesson content if provided, otherwise fetch from API
      if (widget.lesson != null && widget.lesson!.content.isNotEmpty) {
        setState(() {
          _lessonContent = widget.lesson!.content;
          _isLoading = false;
        });
      } else {
        final content = await _apiService.getLessonContent(
          courseId: widget.courseId,
          chapterId: widget.chapterId,
          lessonId: widget.lessonId,
        );
        setState(() {
          _lessonContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading lesson content', error: e);
      setState(() {
        _error = true;
        _isLoading = false;
      });
    }
  }

  // Toggle the TOC drawer
  void _toggleToc() {
    // Only show TOC if content is available
    if (_lessonContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content available for table of contents'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Open the end drawer
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  // Mark the lesson as completed
  Future<void> _markLessonAsCompleted() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // TODO: Implement API call to mark lesson as completed
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson marked as completed'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      Logger.e(_tag, 'Error marking lesson as completed', error: e);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to mark lesson as completed'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _markLessonAsCompleted,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  // Change the font size
  void _changeFontSize(FontSize size) {
    setState(() {
      _fontSize = size;
    });
    // Show a confirmation of the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Font size changed to ${size.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        centerTitle: false,
        actions: [
          // Font size button
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Text Size',
            onPressed: () => _showFontSizeOptions(context),
          ),
          // TOC button
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Table of Contents',
            onPressed: _toggleToc,
          ),
        ],
      ),
      // Floating action button for scrolling to top
      floatingActionButton:
          _showScrollToTop
              ? FloatingActionButton(
                mini: true,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.arrow_upward),
              )
              : null,
      // Bottom bar with "Mark as Completed" button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isCompleting ? null : _markLessonAsCompleted,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child:
                _isCompleting
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Marking as Completed...'),
                      ],
                    )
                    : const Text('Mark as Completed'),
          ),
        ),
      ),
      body: _buildBody(isDarkMode),
      endDrawer: _buildTocDrawer(theme),
    );
  }

  // Build the TOC drawer with error handling
  Widget? _buildTocDrawer(ThemeData theme) {
    return Drawer(
      width: 300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      elevation: 2,
      child: SafeArea(
        // SafeArea to handle notch/status bar overlap
        child: Column(
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Table of Contents',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface.withOpacity(
                        0.8,
                      ),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Divider below header
            Divider(height: 1, thickness: 1, color: theme.dividerColor),

            // TOC Content
            Expanded(
              child: Builder(
                builder: (context) {
                  // Only show TOC if we have content
                  if (_lessonContent.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'No content available',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  try {
                    // Use TocWidget with appropriate styling - based on documentation
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TocWidget(
                        controller: _tocController,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        // Basic styling for TOC items
                        tocTextStyle: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                        // Styling for active/current TOC item
                        currentTocTextStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          height: 1.5,
                        ),
                      ),
                    );
                  } catch (e) {
                    Logger.e(_tag, 'Error displaying TOC', error: e);
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to display table of contents.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the main body content
  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load lesson content',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLessonContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lessonContent.isEmpty) {
      return const Center(child: Text('No content to display'));
    }

    // Create the markdown widget with custom code wrapper
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            try {
              final baseFontSize = _getFontSizeValue();

              // Create a config with our custom font sizes
              final customConfig =
                  isDarkMode
                      ? MarkdownConfig.darkConfig
                      : MarkdownConfig.defaultConfig;

              // Create markdown widget
              return MarkdownWidget(
                data: _lessonContent,
                tocController: _tocController,
                physics: const ClampingScrollPhysics(),
                selectable: true,
                config: customConfig.copy(
                  configs: [
                    // Base text style with our selected font size
                    PConfig(textStyle: TextStyle(fontSize: baseFontSize)),
                    // Apply proportional font sizes to headings
                    H1Config(
                      style: TextStyle(
                        fontSize: baseFontSize * 1.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    H2Config(
                      style: TextStyle(
                        fontSize: baseFontSize * 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    H3Config(
                      style: TextStyle(
                        fontSize: baseFontSize * 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Style for inline code elements (like variables)
                    CodeConfig(
                      style: TextStyle(
                        fontSize: baseFontSize,
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                        color:
                            isDarkMode
                                ? const Color(
                                  0xFFE0E0E0,
                                ) // Light gray text in dark mode
                                : const Color(
                                  0xFF333333,
                                ), // Dark gray text in light mode
                        backgroundColor:
                            isDarkMode
                                ? const Color(
                                  0xFF3A3A3A,
                                ) // Darker gray in dark mode
                                : const Color(
                                  0xFFEEEEEE,
                                ), // Light gray in light mode
                      ),
                    ),
                    // Code block configuration with safe language handling
                    PreConfig(
                      textStyle: TextStyle(
                        fontSize: baseFontSize * 0.9,
                        fontFamily: 'monospace',
                      ),
                      wrapper: (child, text, language) {
                        try {
                          // Simple language validation to avoid null/empty issues
                          String safeLanguage = 'plaintext';
                          if (language.isNotEmpty) {
                            // Only use language if we support it
                            final validLanguages = [
                              'python',
                              'dart',
                              'javascript',
                              'java',
                              'kotlin',
                              'swift',
                              'c',
                              'cpp',
                              'csharp',
                              'go',
                              'rust',
                              'html',
                              'css',
                              'json',
                              'yaml',
                              'markdown',
                              'bash',
                              'shell',
                              'sql',
                              'plaintext',
                              'txt',
                            ];
                            if (validLanguages.contains(
                              language.toLowerCase(),
                            )) {
                              safeLanguage = language.toLowerCase();
                            }
                          }

                          return CodeBlockBuilder(
                            code: text,
                            language: safeLanguage,
                            isDarkMode: isDarkMode,
                          );
                        } catch (e) {
                          // Fallback for errors with very simple implementation
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color:
                                isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.grey[200],
                            child: SelectableText(
                              text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: baseFontSize * 0.9,
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[800],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            } catch (e) {
              Logger.e(_tag, 'Error rendering markdown content', error: e);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error rendering content',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Showing raw content instead:\n\n$_lessonContent'),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Show font size selection dialog
  void _showFontSizeOptions(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Text Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFontSizeOption(
                context,
                FontSize.small,
                'Small',
                _fontSize == FontSize.small,
              ),
              const SizedBox(height: 8),
              _buildFontSizeOption(
                context,
                FontSize.medium,
                'Medium',
                _fontSize == FontSize.medium,
              ),
              const SizedBox(height: 8),
              _buildFontSizeOption(
                context,
                FontSize.large,
                'Large',
                _fontSize == FontSize.large,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build a font size option for the dialog
  Widget _buildFontSizeOption(
    BuildContext context,
    FontSize size,
    String label,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        _changeFontSize(size);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withAlpha(26) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.withAlpha(77),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize:
                    size == FontSize.small
                        ? 14
                        : (size == FontSize.medium ? 16 : 18),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Get the font size value based on the selected FontSize enum
  double _getFontSizeValue() {
    switch (_fontSize) {
      case FontSize.small:
        return 14.0;
      case FontSize.medium:
        return 16.0;
      case FontSize.large:
        return 18.0;
    }
  }
}
