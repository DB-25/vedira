import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../controllers/lesson_controller.dart';
import '../models/lesson.dart';
import '../models/section.dart';
import '../models/user_progress.dart';
import '../services/api_service.dart';
import '../services/mcq_service.dart';
import '../services/progress_service.dart';
import '../screens/mcq_quiz_screen.dart';
import '../utils/logger.dart';
import '../widgets/code_block_builder.dart';
import '../widgets/reading_progress_indicator.dart';

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
  final McqService _mcqService = McqService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'LessonViewScreen';
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tocScrollController = ScrollController();
  final TocController _tocController = TocController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, String> _lessonContentSections = {};
  List<String> _sectionKeys = [];
  int _currentSectionIndex = 0;
  bool _isLoading = true;
  bool _error = false;
  bool _isCompleting = false;
  FontSize _fontSize = FontSize.medium;
  bool _showScrollToTop = false;
  bool _hasReached90Percent =
      false; // Track 90% scroll progress for completion button
  bool _showFab = true; // Always show FAB, but with dynamic behavior
  bool _hasMcqs = false; // Track if MCQs are available

  @override
  void initState() {
    super.initState();
    _loadLessonContent();
    _checkMcqAvailability();

    // Add scroll listener for FAB visibility
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tocScrollController.dispose();
    _mcqService.dispose();
    super.dispose();
  }

  // Track scroll position for FAB visibility and 90% progress detection
  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final currentPosition = _scrollController.offset;
    final threshold = 50.0; // 50px threshold to account for precision issues

    // Check if scrolled to bottom (for FAB behavior)
    final isAtBottom = currentPosition >= (maxScrollExtent - threshold);

    // Check if reached 90% scroll progress (for completion button)
    final scrollProgress =
        maxScrollExtent > 0 ? currentPosition / maxScrollExtent : 0.0;
    final hasReached90Percent = scrollProgress >= 0.9;

    // Update FAB state
    if (_showScrollToTop != isAtBottom && mounted) {
      setState(() {
        _showScrollToTop = isAtBottom;
      });
    }

    // Update 90% progress state - once true, keep it true (don't hide completion button)
    if (!_hasReached90Percent && hasReached90Percent && mounted) {
      setState(() {
        _hasReached90Percent = true;
      });
    }
  }

  // Load lesson content from API or use provided lesson
  Future<void> _loadLessonContent() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      // Use lesson content if provided, otherwise fetch from API
      if (widget.lesson != null && widget.lesson!.content.isNotEmpty) {
        if (mounted) {
          setState(() {
            _lessonContentSections = {'section1': widget.lesson!.content};
            _sectionKeys = ['section1'];
            _currentSectionIndex = 0;
            _isLoading = false;
          });
        }
      } else {
        final contentSections = await _apiService.getLessonContent(
          courseId: widget.courseId,
          chapterId: widget.chapterId,
          lessonId: widget.lessonId,
        );
        if (mounted) {
          setState(() {
            _lessonContentSections = contentSections;
            _sectionKeys = contentSections.keys.toList();
            _currentSectionIndex = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading lesson content', error: e);
      if (mounted) {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    }
  }

  // Check if MCQs are available for this lesson
  Future<void> _checkMcqAvailability() async {
    try {
      final hasMcqs = await _mcqService.areMcqsAvailable(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
      );

      if (mounted) {
        setState(() {
          _hasMcqs = hasMcqs;
        });
      }
    } catch (e) {
      Logger.w(_tag, 'Error checking MCQ availability: $e');
    }
  }

  // Toggle the TOC drawer
  void _toggleToc() {
    // Only show TOC if content is available
    if (_currentSectionContent.isEmpty) {
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
    if (!mounted) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      // Save lesson completion to local progress
      final success = await _progressService.markLessonCompleted(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        studyTimeMinutes: 5, // Estimate - could be more sophisticated
      );

      if (success) {
        // Show completion dialog instead of just returning
        if (mounted) {
          await _showCompletionDialog();
        }
      } else {
        // Show error if saving failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save progress. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _showCompletionDialog() async {
    // Get existing quiz attempts to show in dialog
    final progress = await _progressService.getCourseProgress(widget.courseId);
    final chapterProgress = progress?.chapterProgress[widget.chapterId];
    final attempts = chapterProgress?.quizAttempts[widget.lessonId] ?? [];
    final bestAttempt =
        attempts.isNotEmpty
            ? attempts.reduce(
              (a, b) => a.scorePercentage > b.scorePercentage ? a : b,
            )
            : null;

    if (!mounted) return;

    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon and message
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lesson Completed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job finishing "${widget.lessonTitle}"',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // What's next section
                Text(
                  'What would you like to do next?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Quiz option
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.quiz, size: 20),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bestAttempt != null ? 'Retake Quiz' : 'Take Quiz',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (bestAttempt != null)
                          Text(
                            'Best score: ${bestAttempt.score}/${bestAttempt.totalQuestions} (${bestAttempt.scorePercentage.round()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSecondary.withOpacity(
                                0.8,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Test your knowledge of this lesson',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSecondary.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Next lesson option
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop('next'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Continue to Next Lesson',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Back to course option
                Container(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop('back'),
                    icon: Icon(
                      Icons.list,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    label: Text(
                      'Back to Chapter Overview',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Handle user's choice
    if (result != null && mounted) {
      switch (result) {
        case 'quiz':
          // Navigate to quiz
          _navigateToMcqQuiz();
          break;
        case 'next':
          // TODO: Navigate to next lesson (would need to determine which is next)
          Navigator.of(
            context,
          ).pop(true); // For now, go back with completion indicator
          break;
        case 'back':
          Navigator.of(context).pop(true); // Go back to course details
          break;
      }
    }
  }

  // Change the font size
  void _changeFontSize(FontSize size) {
    if (mounted) {
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
  }

  void _navigateToMcqQuiz() async {
    // Try to fetch section information to enable next lesson navigation
    Section? section;
    int? currentLessonIndex;

    try {
      final course = await _apiService.getCourse(widget.courseId);

      // Find the section that contains this lesson
      if (course.sections != null) {
        for (final s in course.sections!) {
          final lessonIndex = s.lessons.indexWhere(
            (l) => l.id == widget.lessonId,
          );
          if (lessonIndex >= 0) {
            section = s;
            currentLessonIndex = lessonIndex;
            break;
          }
        }
      }
    } catch (e) {
      Logger.w(_tag, 'Failed to fetch section info for quiz navigation: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => McqQuizScreen(
              courseId: widget.courseId,
              chapterId: widget.chapterId,
              lessonId: widget.lessonId,
              lessonTitle: widget.lessonTitle,
              section: section,
              currentLessonIndex: currentLessonIndex,
            ),
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
          // MCQ button
          IconButton(
            icon: const Icon(Icons.quiz),
            tooltip: 'Take Quiz',
            onPressed: _hasMcqs ? _navigateToMcqQuiz : null,
          ),
        ],
      ),
      // Dynamic floating action button - scroll down by default, scroll up when at bottom
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          if (_showScrollToTop) {
            // At bottom - scroll to top
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            // Not at bottom - scroll to bottom
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        tooltip: _showScrollToTop ? 'Scroll to top' : 'Scroll to bottom',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Natural directional slide based on arrow direction
            final isUpArrow = (child.key as ValueKey).value == 'up';
            final slideOffset =
                isUpArrow
                    ? const Offset(0.0, 0.3) // Up arrow slides from below
                    : const Offset(0.0, -0.3); // Down arrow slides from above

            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: slideOffset,
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Icon(
            _showScrollToTop
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            key: ValueKey(_showScrollToTop ? 'up' : 'down'),
          ),
        ),
      ),
      // Bottom bar with "Mark as Completed" button - only show on last section when scrolled to bottom
      bottomNavigationBar:
          _shouldShowCompletionButton
              ? Container(
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
              )
              : null,
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
                  if (_currentSectionContent.isEmpty) {
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

    if (_currentSectionContent.isEmpty) {
      return const Center(child: Text('No content to display'));
    }

    // Build content with pagination controls and reading progress indicator
    return SafeArea(
      child: Column(
        children: [
          // Reading Progress Indicator

          // Top pagination controls
          if (_hasMultipleSections) _buildPaginationControls(isTop: true),
          ReadingProgressIndicator(
            scrollController: _scrollController,
            height: 6.0,
            showPercentage: false,
            borderRadius: BorderRadius.circular(5.0),
          ),
          // Main scrollable content with side scroll indicator
          Expanded(
            child: Row(
              children: [
                // Main content area - now the entire area is scrollable
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: _buildMarkdownContent(isDarkMode),
                  ),
                ),

                // Side scroll indicator
                Container(
                  width: 12,
                  margin: const EdgeInsets.only(right: 8, top: 16, bottom: 16),
                  child: ScrollIndicator(
                    scrollController: _scrollController,
                    width: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build pagination controls
  Widget _buildPaginationControls({required bool isTop}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: isTop ? BorderSide.none : BorderSide(color: theme.dividerColor),
          bottom:
              isTop ? BorderSide(color: theme.dividerColor) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          TextButton.icon(
            onPressed: _currentSectionIndex > 0 ? _goToPreviousSection : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Previous'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),

          // Section indicator
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Section ${_currentSectionIndex + 1} of ${_sectionKeys.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                if (isTop) // Only show section title at the top
                  Text(
                    _currentSectionTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Next button
          TextButton.icon(
            onPressed:
                _currentSectionIndex < _sectionKeys.length - 1
                    ? _goToNextSection
                    : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to previous section
  void _goToPreviousSection() {
    if (_currentSectionIndex > 0 && mounted) {
      setState(() {
        _currentSectionIndex--;
        _hasReached90Percent =
            false; // Reset 90% progress when changing sections
      });

      // Reset scroll to top for new section after the rebuild is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // Navigate to next section
  void _goToNextSection() {
    if (_currentSectionIndex < _sectionKeys.length - 1 && mounted) {
      setState(() {
        _currentSectionIndex++;
        _hasReached90Percent =
            false; // Reset 90% progress when changing sections
      });

      // Reset scroll to top for new section after the rebuild is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // Build the markdown content widget
  Widget _buildMarkdownContent(bool isDarkMode) {
    // Create the markdown widget with custom code wrapper
    return Builder(
      builder: (context) {
        try {
          final baseFontSize = _getFontSizeValue();

          // Clean the markdown content to prevent entire sections being treated as code blocks
          String cleanedContent = _cleanMarkdownContent(_currentSectionContent);

          // Check if this is a large section that might be problematic
          final isLargeSection = cleanedContent.length > 10000;

          // Create a config with our custom font sizes
          final customConfig =
              isDarkMode
                  ? MarkdownConfig.darkConfig
                  : MarkdownConfig.defaultConfig;

          // Prepare config list - conditionally include PreConfig
          final List<WidgetConfig> configs = [
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
                        ? const Color(0xFF3A3A3A) // Darker gray in dark mode
                        : const Color(0xFFEEEEEE), // Light gray in light mode
              ),
            ),
          ];

          // Only add PreConfig for smaller content to avoid large sections being treated as code
          if (!isLargeSection) {
            configs.add(
              // Code block configuration with safe language handling
              PreConfig(
                textStyle: TextStyle(
                  fontSize: baseFontSize * 0.9,
                  fontFamily: 'monospace',
                ),
                wrapper: (child, text, language) {
                  try {
                    // Check if this looks like actual code or just incorrectly formatted content
                    final isLikelyActualCode = _isLikelyCodeBlock(
                      text,
                      language,
                    );

                    if (!isLikelyActualCode) {
                      // This doesn't look like a code block, return original child
                      return child;
                    }

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
                      if (validLanguages.contains(language.toLowerCase())) {
                        safeLanguage = language.toLowerCase();
                      }
                    }

                    return CodeBlockBuilder(
                      code: text,
                      language: safeLanguage,
                      isDarkMode: isDarkMode,
                    );
                  } catch (e) {
                    // Return original child on error
                    return child;
                  }
                },
              ),
            );
          }

          // Create markdown widget (ScrollView is now handled at parent level)
          return MarkdownWidget(
            data: cleanedContent,
            tocController: _tocController,
            selectable: true,
            shrinkWrap:
                true, // Changed back to true since no more SingleChildScrollView wrapper
            config: customConfig.copy(configs: configs),
          );
        } catch (e) {
          Logger.e(_tag, 'Error rendering markdown content', error: e);
          return Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error rendering content',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text('Showing raw content instead:\n\n$_currentSectionContent'),
            ],
          );
        }
      },
    );
  }

  // Clean markdown content to prevent parsing issues
  String _cleanMarkdownContent(String content) {
    final lines = content.split('\n');
    List<String> workingLines = List.from(lines);

    // Remove wrapping code block markers if the entire content is wrapped
    if (workingLines.isNotEmpty && workingLines[0].trim() == '```') {
      workingLines.removeAt(0);

      // Also remove the corresponding closing marker at the end
      if (workingLines.isNotEmpty && workingLines.last.trim() == '```') {
        workingLines.removeLast();
      }
    }

    // Check for other variations of wrapping code blocks (with language specified)
    if (workingLines.isNotEmpty && workingLines[0].trim().startsWith('```')) {
      workingLines.removeAt(0);

      // Remove corresponding closing marker
      if (workingLines.isNotEmpty && workingLines.last.trim() == '```') {
        workingLines.removeLast();
      }
    }

    return workingLines.join('\n');
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

  // Get current section content
  String get _currentSectionContent {
    if (_sectionKeys.isEmpty) return '';
    final currentKey = _sectionKeys[_currentSectionIndex];
    return _lessonContentSections[currentKey] ?? '';
  }

  // Get current section title/key
  String get _currentSectionTitle {
    if (_sectionKeys.isEmpty) return '';
    return _sectionKeys[_currentSectionIndex];
  }

  // Check if there are multiple sections for pagination
  bool get _hasMultipleSections => _sectionKeys.length > 1;

  // Check if the current section is the last section
  bool get _isOnLastSection => _currentSectionIndex == _sectionKeys.length - 1;

  // Check if the completion button should be shown
  bool get _shouldShowCompletionButton =>
      _isOnLastSection && _hasReached90Percent;

  // Helper method to check if a string looks like actual code
  bool _isLikelyCodeBlock(String text, String language) {
    // If a specific language is provided (not empty), it's likely a code block
    if (language.isNotEmpty && language != 'plaintext') {
      return true;
    }

    // If text is very long (more than 2000 characters), it's probably not a code block
    if (text.length > 2000) {
      return false;
    }

    // Check for markdown headers (##, ###, etc.) - these indicate it's markdown content, not code
    if (text.contains(RegExp(r'^#{1,6}\s+', multiLine: true))) {
      return false;
    }

    // Check for common markdown patterns
    if (text.contains(RegExp(r'\*\*.*?\*\*')) || // Bold text
        text.contains(RegExp(r'\*.*?\*')) || // Italic text
        text.contains(RegExp(r'\[.*?\]\(.*?\)'))) {
      // Links
      return false;
    }

    // Check for paragraph breaks - code blocks typically don't have multiple paragraphs
    final paragraphCount = text.split(RegExp(r'\n\s*\n')).length;
    if (paragraphCount > 3) {
      return false;
    }

    // If text starts with markdown content indicators, it's not a code block
    final trimmedText = text.trim();
    if (trimmedText.startsWith('##') ||
        trimmedText.startsWith('**') ||
        trimmedText.startsWith('The ') ||
        trimmedText.startsWith('In ') ||
        trimmedText.startsWith('A ') ||
        trimmedText.startsWith('An ')) {
      return false;
    }

    // Check for code-like patterns
    final codePatterns = [
      RegExp(r'\{.*\}'), // Curly braces
      RegExp(r'\[.*\]'), // Square brackets (but not markdown links)
      RegExp(r'function\s*\('), // Function declarations
      RegExp(r'class\s+\w+'), // Class declarations
      RegExp(r'import\s+'), // Import statements
      RegExp(r'def\s+\w+'), // Python function definitions
      RegExp(r'var\s+\w+'), // Variable declarations
      RegExp(r'const\s+\w+'), // Constant declarations
    ];

    int codePatternMatches = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) {
        codePatternMatches++;
      }
    }

    // If we have multiple code patterns, it's likely code
    if (codePatternMatches >= 2) {
      return true;
    }

    // Check line count and indentation
    final lines = text.split('\n');
    if (lines.length <= 20) {
      // Short content might be code
      // Check if most lines are indented (common in code)
      final indentedLines =
          lines
              .where((line) => line.startsWith('  ') || line.startsWith('\t'))
              .length;
      if (indentedLines > lines.length * 0.6) {
        return true;
      }
    }

    // Default to false - don't treat as code block unless we're confident
    return false;
  }
}
