import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/lesson_controller.dart';
import '../models/lesson.dart';
import '../models/section.dart';

import '../services/api_service.dart';
import '../services/mcq_service.dart';
import '../services/flashcard_service.dart';
import '../services/progress_service.dart';
import '../screens/mcq_quiz_screen.dart';
import '../screens/flashcard_screen.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../components/custom_app_bar.dart';
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
  final FlashcardService _flashcardService = FlashcardService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'LessonViewScreen';
  final ScrollController _scrollController = ScrollController();

  Map<String, String> _lessonContentSections = {};
  List<String> _sectionKeys = [];
  String _currentSectionContent = '';
  String _currentSectionTitle = '';
  bool _isLoading = true;
  bool _error = false;
  bool _isCompleting = false;
  FontSize _fontSize = FontSize.medium;
  bool _showScrollToTop = false;
  bool _hasReached90Percent = false;
  bool _isScrollingNeeded = false;
  double _thumbRatio = 0.0;

  bool _hasMcqs = false;
  bool _hasFlashcards = false;
  bool _hasNextLesson = false;

  List<GlobalKey> _sectionHeaderKeys = [];
  List<String> _allSectionsContent = [];
  List<String> _allSectionTitles = [];
  int _currentVisibleSection = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadLessonData();
    _checkMcqAvailability();
    _checkFlashcardAvailability();
    _checkNextLessonAvailability();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _mcqService.dispose();
    _flashcardService.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients || !mounted) return;

    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportDimension = _scrollController.position.viewportDimension;

    final isScrollingNeeded = maxScrollExtent > 0;
    if (_isScrollingNeeded != isScrollingNeeded) {
      setState(() {
        _isScrollingNeeded = isScrollingNeeded;
      });
    }

    _updateVisibleSection();

    if (maxScrollExtent > 0) {
      final scrollPercentage = scrollOffset / maxScrollExtent;
      if (scrollPercentage >= 0.9 && !_hasReached90Percent) {
        setState(() {
          _hasReached90Percent = true;
        });
      }
    }
  }

  void _updateVisibleSection() {
    if (_sectionHeaderKeys.isEmpty) return;

    int newVisibleSection = 0;
    final scrollOffset = _scrollController.offset;

    for (int i = 0; i < _sectionHeaderKeys.length; i++) {
      final context = _sectionHeaderKeys[i].currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          if (position.dy <= MediaQuery.of(context).size.height / 2) {
            newVisibleSection = i;
          }
        }
      }
    }

    if (newVisibleSection != _currentVisibleSection) {
      setState(() {
        _currentVisibleSection = newVisibleSection;
      });
    }
  }

  Future<void> _loadLessonData() async {
    try {
      final contentSections = await _apiService.getLessonContent(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
      );

      if (contentSections != null && mounted) {
        setState(() {
          _lessonContentSections = contentSections;
          _sectionKeys = contentSections.keys.toList();
          _allSectionsContent = _sectionKeys.map((key) => contentSections[key] ?? '').toList();
          _allSectionTitles = _sectionKeys.map((key) => _extractTitleFromContent(contentSections[key] ?? '')).toList();
          
          _sectionHeaderKeys = List.generate(_sectionKeys.length, (index) => GlobalKey());
          
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkScrollingNeeded();
        });
      } else {
        Logger.w(_tag, 'No lesson data found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading lesson data', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkScrollingNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final isScrollingNeeded = maxScrollExtent > 0;
    
    if (_isScrollingNeeded != isScrollingNeeded) {
      setState(() {
        _isScrollingNeeded = isScrollingNeeded;
      });
    }
  }

  void _onThumbRatioChanged(double ratio) {
    if (_thumbRatio != ratio) {
      setState(() {
        _thumbRatio = ratio;
      });
    }
  }

  bool get _shouldShowScrollAids {
    return _isScrollingNeeded && _thumbRatio < 0.4;
  }

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

  Future<void> _checkFlashcardAvailability() async {
    try {
      final hasFlashcards = await _flashcardService.areFlashcardsAvailable(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
      );

      if (mounted) {
        setState(() {
          _hasFlashcards = hasFlashcards;
        });
      }
    } catch (e) {
      Logger.w(_tag, 'Error checking flashcard availability: $e');
    }
  }

  Future<void> _checkNextLessonAvailability() async {
    try {
      final course = await _apiService.getCourse(widget.courseId);
      
      bool hasNext = false;
      if (course.sections != null) {
        for (final section in course.sections!) {
          final lessonIndex = section.lessons.indexWhere((l) => l.id == widget.lessonId);
          if (lessonIndex >= 0) {
            hasNext = lessonIndex + 1 < section.lessons.length;
            Logger.i(_tag, 'Next lesson check: Current index $lessonIndex, Total lessons ${section.lessons.length}, Has next: $hasNext');
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasNextLesson = hasNext;
        });
        Logger.i(_tag, 'Updated _hasNextLesson to: $_hasNextLesson');
      }
    } catch (e) {
      Logger.w(_tag, 'Error checking next lesson availability: $e');
    }
  }

  Future<void> _markLessonAsCompleted() async {
    if (!mounted) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final success = await _progressService.markLessonCompleted(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        studyTimeMinutes: 5,
      );

      if (success) {
        await _navigateToNextLessonOrCourse();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save progress. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isCompleting = false;
          });
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error marking lesson as completed', error: e);

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
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _navigateToNextLessonOrCourse() async {
    try {
      final course = await _apiService.getCourse(widget.courseId);
      
      // Find current lesson and check for next lesson
      Section? currentSection;
      int? currentLessonIndex;
      
      Logger.i(_tag, 'Looking for next lesson. Current lesson ID: ${widget.lessonId}');
      
      if (course.sections != null) {
        for (final section in course.sections!) {
          final lessonIndex = section.lessons.indexWhere((l) => l.id == widget.lessonId);
          if (lessonIndex >= 0) {
            currentSection = section;
            currentLessonIndex = lessonIndex;
            Logger.i(_tag, 'Found current lesson at index $lessonIndex in section with ${section.lessons.length} lessons');
            break;
          }
        }
      }
      
      if (currentSection != null && currentLessonIndex != null) {
        // Check if there's a next lesson in the current section
        if (currentLessonIndex + 1 < currentSection.lessons.length) {
          final nextLesson = currentSection.lessons[currentLessonIndex + 1];
          Logger.i(_tag, 'Found next lesson: ${nextLesson.title} (${nextLesson.id})');
          
          // Navigate to next lesson using MaterialPageRoute for reliability
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LessonViewScreen(
                  courseId: widget.courseId,
                  chapterId: widget.chapterId,
                  lessonId: nextLesson.id,
                  lessonTitle: nextLesson.title,
                ),
              ),
            );
          }
          return;
        } else {
          Logger.i(_tag, 'No next lesson found, this is the last lesson in the section');
        }
      } else {
        Logger.w(_tag, 'Could not find current lesson in course sections');
      }
      
      // No next lesson, go back to course details
      Logger.i(_tag, 'Navigating back to course details with completion data');
      if (mounted) {
        Navigator.of(context).pop({
          'lessonCompleted': true,
          'lessonId': widget.lessonId,
          'lessonTitle': widget.lessonTitle,
          'chapterId': widget.chapterId,
          'courseId': widget.courseId,
        });
      }
    } catch (e) {
      Logger.e(_tag, 'Error navigating after lesson completion', error: e);
      
      // Fallback: go back to course details
      if (mounted) {
        Navigator.of(context).pop({
          'lessonCompleted': true,
          'lessonId': widget.lessonId,
          'lessonTitle': widget.lessonTitle,
          'chapterId': widget.chapterId,
          'courseId': widget.courseId,
        });
      }
    }
  }

  

  void _changeFontSize(FontSize size) {
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Font size changed to ${size.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _navigateToMcqQuiz() async {
    Section? section;
    int? currentLessonIndex;

    try {
      final course = await _apiService.getCourse(widget.courseId);

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

    final result = await Navigator.push<Map<String, dynamic>>(
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

    if (result != null && result['quizCompleted'] == true) {
      Logger.i(_tag, 'Quiz completed, going back to course overview. Score: ${result['score']}/${result['totalQuestions']}');
      Navigator.of(context).pop(result);
    }
  }

  void _navigateToFlashcards() async {
    Section? section;
    int? currentLessonIndex;

    try {
      final course = await _apiService.getCourse(widget.courseId);

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
      Logger.w(_tag, 'Failed to fetch section info for flashcard navigation: $e');
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => FlashcardScreen(
              courseId: widget.courseId,
              chapterId: widget.chapterId,
              lessonId: widget.lessonId,
              lessonTitle: widget.lessonTitle,
              section: section,
              currentLessonIndex: currentLessonIndex,
            ),
      ),
    );

    if (result != null && result['flashcardsCompleted'] == true) {
      Logger.i(_tag, 'Flashcards completed, refreshing lesson view');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final bodyBackgroundColor = colorScheme.bodyBackground;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: CustomAppBar(
        title: widget.lessonTitle,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Text Size',
            onPressed: () => _showFontSizeOptions(context),
          ),

          IconButton(
            icon: const Icon(Icons.quiz),
            tooltip: 'Take Quiz',
            onPressed: _hasMcqs ? _navigateToMcqQuiz : null,
          ),
          IconButton(
            icon: const Icon(Icons.style),
            tooltip: 'Study Flashcards',
            onPressed: _hasFlashcards ? _navigateToFlashcards : null,
          ),
        ],
      ),
      floatingActionButton: _shouldShowScrollAids ? FloatingActionButton(
        mini: true,
        onPressed: () {
          if (_showScrollToTop) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
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
            final isUpArrow = (child.key as ValueKey).value == 'up';
            final slideOffset =
                isUpArrow
                    ? const Offset(0.0, 0.3)
                    : const Offset(0.0, -0.3);

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
      ) : null,
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
                            : Text(_hasNextLesson ? 'Next Lesson' : 'Finish Chapter'),
                  ),
                ),
              )
              : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    
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
            Text(
              'Failed to load lesson content',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLessonData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allSectionsContent.isEmpty) {
      return const Center(child: Text('No content to display'));
    }

    return SafeArea(
      child: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildContinuousContent(),
                      ),
                    ),
                  ),
                ),

                if (_shouldShowScrollAids)
                  Container(
                    width: 12,
                    margin: const EdgeInsets.only(right: 8, top: 16, bottom: 16),
                    child: ScrollIndicator(
                      scrollController: _scrollController,
                      width: 8,
                      onThumbRatioChanged: _onThumbRatioChanged,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Part ${_currentVisibleSection + 1} of ${_allSectionTitles.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              if (_allSectionTitles.length > 1)
                TextButton.icon(
                  onPressed: _showSectionNavigation,
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('Jump to'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: (_currentVisibleSection + 1) / _allSectionTitles.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            _allSectionTitles.isNotEmpty ? _allSectionTitles[_currentVisibleSection] : '',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousContent() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            widget.lessonTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        
        ...List.generate(_allSectionsContent.length, (index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: _sectionHeaderKeys[index],
                padding: EdgeInsets.only(top: index == 0 ? 0 : 32, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.3),
                      ),
                    Text(
                      _allSectionTitles[index],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildSectionMarkdown(_allSectionsContent[index], isDarkMode),
              
              const SizedBox(height: 16),
            ],
          );
        }),
        
        const SizedBox(height: 32),
        _buildCompletionSection(),
      ],
    );
  }

  Widget _buildSectionMarkdown(String content, bool isDarkMode) {
    final theme = Theme.of(context);
    
    try {
      final baseFontSize = _getFontSizeValue();
      String cleanedContent = _cleanMarkdownContent(content);
      final isLargeSection = cleanedContent.length > 10000;

      final customConfig = isDarkMode ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;

      final List<WidgetConfig> configs = [
        PConfig(textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: baseFontSize) ?? GoogleFonts.poppins(fontSize: baseFontSize)),
        H1Config(
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: baseFontSize * 1.8) ?? 
                 GoogleFonts.inter(fontSize: baseFontSize * 1.8, fontWeight: FontWeight.bold),
        ),
        H2Config(
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: baseFontSize * 1.5) ?? 
                 GoogleFonts.inter(fontSize: baseFontSize * 1.5, fontWeight: FontWeight.bold),
        ),
        H3Config(
          style: theme.textTheme.headlineSmall?.copyWith(fontSize: baseFontSize * 1.2) ?? 
                 GoogleFonts.inter(fontSize: baseFontSize * 1.2, fontWeight: FontWeight.bold),
        ),
        CodeConfig(
          style: GoogleFonts.jetBrainsMono(
            fontSize: baseFontSize,
            letterSpacing: 0.3,
            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
            backgroundColor: isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
          ),
        ),
      ];

      if (!isLargeSection) {
        configs.add(
          PreConfig(
            textStyle: GoogleFonts.jetBrainsMono(fontSize: baseFontSize * 0.9),
            wrapper: (child, text, language) {
              try {
                final isLikelyActualCode = _isLikelyCodeBlock(text, language);
                if (!isLikelyActualCode) return child;

                String safeLanguage = 'plaintext';
                if (language.isNotEmpty) {
                  final validLanguages = [
                    'python', 'dart', 'javascript', 'java', 'kotlin', 'swift', 'c', 'cpp',
                    'csharp', 'go', 'rust', 'html', 'css', 'json', 'yaml', 'markdown',
                    'bash', 'shell', 'sql', 'plaintext', 'txt',
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
                return child;
              }
            },
          ),
        );
      }

      return MarkdownWidget(
        data: cleanedContent,
        selectable: true,
        shrinkWrap: true,
        config: customConfig.copy(configs: configs),
      );
    } catch (e) {
      Logger.e(_tag, 'Error rendering section markdown', error: e);
      return Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error rendering section content',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? 
                   GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text('Showing raw content instead:\n\n$content'),
        ],
      );
    }
  }

  void _showSectionNavigation() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to Part'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allSectionTitles.length,
              itemBuilder: (context, index) {
                final isCurrentSection = index == _currentVisibleSection;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isCurrentSection 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCurrentSection 
                            ? theme.colorScheme.onPrimary 
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    _allSectionTitles[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentSection ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentSection 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isCurrentSection 
                      ? Icon(Icons.visibility, color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _scrollToSection(index);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _scrollToSection(int sectionIndex) {
    if (sectionIndex < 0 || sectionIndex >= _sectionHeaderKeys.length) return;

    final context = _sectionHeaderKeys[sectionIndex].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCompletionSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve reached the end!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Great job reading through "${widget.lessonTitle}". Test your knowledge or review key concepts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              if (_hasFlashcards)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/flashcard',
                        arguments: {
                          'courseId': widget.courseId,
                          'chapterId': widget.chapterId,
                          'lessonId': widget.lessonId,
                          'lessonTitle': widget.lessonTitle,
                        },
                      );
                    },
                    icon: const Icon(Icons.style),
                    label: const Text('Flashcards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              
              if (_hasFlashcards && _hasMcqs)
                const SizedBox(width: 12),
              
              if (_hasMcqs)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToMcqQuiz,
                    icon: const Icon(Icons.quiz),
                    label: const Text('Take Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
              style: theme.textTheme.bodyMedium?.copyWith(
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



  bool get _shouldShowCompletionButton =>
      _currentVisibleSection == _sectionKeys.length - 1 && _hasReached90Percent;

  bool _isLikelyCodeBlock(String text, String language) {
    if (language.isNotEmpty && language != 'plaintext') {
      return true;
    }

    if (text.length > 2000) {
      return false;
    }

    if (text.contains(RegExp(r'^#{1,6}\s+', multiLine: true))) {
      return false;
    }

    if (text.contains(RegExp(r'\*\*.*?\*\*')) ||
        text.contains(RegExp(r'\*.*?\*')) ||
        text.contains(RegExp(r'\[.*?\]\(.*?\)'))) {
      return false;
    }

    final paragraphCount = text.split(RegExp(r'\n\s*\n')).length;
    if (paragraphCount > 3) {
      return false;
    }

    final trimmedText = text.trim();
    if (trimmedText.startsWith('##') ||
        trimmedText.startsWith('**') ||
        trimmedText.startsWith('The ') ||
        trimmedText.startsWith('In ') ||
        trimmedText.startsWith('A ') ||
        trimmedText.startsWith('An ')) {
      return false;
    }

    final codePatterns = [
      RegExp(r'\{.*\}'),
      RegExp(r'\[.*\]'),
      RegExp(r'function\s*\('),
      RegExp(r'class\s+\w+'),
      RegExp(r'import\s+'),
      RegExp(r'def\s+\w+'),
      RegExp(r'var\s+\w+'),
      RegExp(r'const\s+\w+'),
    ];

    int codePatternMatches = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) {
        codePatternMatches++;
      }
    }

    if (codePatternMatches >= 2) {
      return true;
    }

    final lines = text.split('\n');
    if (lines.length <= 20) {
      final indentedLines =
          lines
              .where((line) => line.startsWith('  ') || line.startsWith('\t'))
              .length;
      if (indentedLines > lines.length * 0.6) {
        return true;
      }
    }

    return false;
  }

  // Extract title from markdown content by finding the first heading
  String _extractTitleFromContent(String content) {
    if (content.isEmpty) return 'Untitled Section';
    
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Look for markdown headings (# ## ###)
      if (trimmedLine.startsWith('#')) {
        // Remove the # symbols and any extra whitespace
        final title = trimmedLine.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        if (title.isNotEmpty) {
          return title;
        }
      }
      
      // Look for lines that might be titles (non-empty, not starting with common text indicators)
      if (trimmedLine.isNotEmpty && 
          !trimmedLine.startsWith('```') &&
          !trimmedLine.toLowerCase().startsWith('the ') &&
          !trimmedLine.toLowerCase().startsWith('in ') &&
          !trimmedLine.toLowerCase().startsWith('before ') &&
          !trimmedLine.toLowerCase().startsWith('when ') &&
          !trimmedLine.toLowerCase().startsWith('after ') &&
          trimmedLine.length < 100) { // Reasonable title length
        return trimmedLine;
      }
    }
    
    return 'Untitled Section';
  }

  String _cleanMarkdownContent(String content) {
    final lines = content.split('\n');
    List<String> workingLines = List.from(lines);

    // Remove code block wrappers
    if (workingLines.isNotEmpty && workingLines[0].trim() == '```') {
      workingLines.removeAt(0);
      if (workingLines.isNotEmpty && workingLines.last.trim() == '```') {
        workingLines.removeLast();
      }
    }

    if (workingLines.isNotEmpty && workingLines[0].trim().startsWith('```')) {
      workingLines.removeAt(0);
      if (workingLines.isNotEmpty && workingLines.last.trim() == '```') {
        workingLines.removeLast();
      }
    }

    // Remove the first heading to avoid duplication with section header
    bool foundFirstHeading = false;
    for (int i = 0; i < workingLines.length; i++) {
      final trimmedLine = workingLines[i].trim();
      if (trimmedLine.startsWith('#') && !foundFirstHeading) {
        workingLines.removeAt(i);
        foundFirstHeading = true;
        // Also remove any empty lines immediately following
        while (i < workingLines.length && workingLines[i].trim().isEmpty) {
          workingLines.removeAt(i);
        }
        break;
      }
      // Stop looking if we hit non-empty, non-heading content
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
        break;
      }
    }

    return workingLines.join('\n');
  }
}
