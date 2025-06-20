import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/section.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../services/generation_strategy_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import '../widgets/study_chapter_card.dart';
import '../widgets/authenticated_image.dart';
import '../screens/lesson_view_screen.dart';
import '../screens/mcq_quiz_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  CourseDetailsScreen({super.key, required this.courseId}) {
    // Validate courseId is not empty
    assert(
      courseId.isNotEmpty,
      'CourseDetailsScreen: courseId cannot be empty',
    );
  }

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final ApiService _apiService = ApiService();
  final ProgressService _progressService = ProgressService();
  final GenerationStrategyService _generationService =
      GenerationStrategyService();

  late Future<Course> _courseFuture;
  UserProgress? _userProgress;
  StudyRecommendation? _studyRecommendation;
  bool _isRefreshing = false;
  bool _isDescriptionExpanded = false;
  final String _tag = 'CourseDetailsScreen';

  // Flags to prevent multiple initialization calls
  bool _progressInitialized = false;
  bool _recommendationsLoaded = false;
  String? _lastCourseId;

  @override
  void initState() {
    super.initState();
    // Added additional validation and logging for courseId
    if (widget.courseId.isEmpty) {
      Logger.e(_tag, 'Empty courseId provided to CourseDetailsScreen');
    }
    Logger.i(_tag, 'Screen initialized for course ID: "${widget.courseId}"');
    _loadCourse();
    _loadUserProgress();
  }

  @override
  void dispose() {
    _generationService.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    // Check if courseId is empty and treat it as an error
    if (widget.courseId.isEmpty) {
      Logger.e(_tag, 'Empty courseId provided to CourseDetailsScreen');
      setState(() {
        _courseFuture = Future.error(Exception('Course ID is required'));
      });
      return;
    }

    Logger.i(_tag, 'Loading course details for ID: ${widget.courseId}');
    setState(() {
      // Use the course endpoint which now directly calls the lesson plan API
      _courseFuture = _apiService.getCourse(widget.courseId);
      // Reset flags when loading new course
      _progressInitialized = false;
      _recommendationsLoaded = false;
      _lastCourseId = null;
    });
  }

  Future<void> _loadUserProgress() async {
    try {
      final progress = await _progressService.getCourseProgress(
        widget.courseId,
      );
      setState(() {
        _userProgress = progress;
      });
      Logger.i(
        _tag,
        'User progress loaded: ${progress != null ? 'found' : 'not found'}',
      );
    } catch (e) {
      Logger.e(_tag, 'Error loading user progress', error: e);
    }
  }

  Future<void> _loadStudyRecommendation(Course course) async {
    // Prevent multiple calls for the same course
    if (_recommendationsLoaded && _lastCourseId == course.courseID) {
      return;
    }

    try {
      final chapterIds = course.sections?.map((s) => s.id).toList() ?? ['main'];
      final recommendation = await _generationService.getStudyRecommendation(
        courseId: widget.courseId,
        allChapterIds: chapterIds,
        chaptersStatus: course.chaptersStatus,
      );

      setState(() {
        _studyRecommendation = recommendation;
        _recommendationsLoaded = true;
        _lastCourseId = course.courseID;
      });

      Logger.i(
        _tag,
        'Study recommendation loaded',
        data: {
          'hasContentToStudy': recommendation.hasContentToStudy,
          'hasSuggestions': recommendation.hasSuggestions,
          'nextToGenerate': recommendation.nextToGenerate,
        },
      );

      // Show smart suggestion if applicable
      await _checkAndShowSmartSuggestion(course, recommendation);
    } catch (e) {
      Logger.e(_tag, 'Error loading study recommendation', error: e);
    }
  }

  Future<void> _checkAndShowSmartSuggestion(
    Course course,
    StudyRecommendation recommendation,
  ) async {
    if (!mounted) return;

    // Only show suggestion if user has content to study and there's a next chapter to generate
    if (recommendation.hasContentToStudy &&
        recommendation.nextToGenerate != null) {
      final nextChapterId = recommendation.nextToGenerate!;
      final nextChapter = course.sections?.firstWhere(
        (s) => s.id == nextChapterId,
      );

      if (nextChapter != null) {
        final shouldGenerate = await _generationService
            .showGenerationSuggestion(
              context: context,
              chapterName: nextChapter.title,
              currentActivity: 'study the current chapter',
            );

        if (shouldGenerate) {
          _startChapterGeneration(nextChapterId, nextChapter.title);
        }
      }
    }
  }

  void _startChapterGeneration(String chapterId, String chapterTitle) {
    final progressStream = _generationService.startGeneration(
      courseId: widget.courseId,
      chapterId: chapterId,
      context: context,
    );

    _generationService.showGenerationProgress(
      context: context,
      chapterName: chapterTitle,
      progressStream: progressStream,
    );

    // Listen for completion to refresh the course data
    progressStream.listen((progress) {
      if (progress.phase == GenerationPhase.completed) {
        _handleRefresh();
      }
    });
  }

  Future<void> _handleRefresh() async {
    Logger.i(_tag, 'Refreshing course details for ID: ${widget.courseId}');
    setState(() {
      _isRefreshing = true;
    });

    await _loadCourse();
    await _loadUserProgress();

    setState(() {
      _isRefreshing = false;
    });

    Logger.i(_tag, 'Course refresh completed');
  }

  Future<void> _initializeProgress(Course course) async {
    // Prevent multiple initialization calls for the same course
    if (_progressInitialized && _lastCourseId == course.courseID) {
      return;
    }

    if (_userProgress == null) {
      final chapterNames = <String, String>{};
      if (course.sections != null) {
        for (var section in course.sections!) {
          chapterNames[section.id] = section.title;
        }
      } else {
        chapterNames['main'] = 'Main Chapter';
      }

      final progress = await _progressService.initializeCourseProgress(
        courseId: widget.courseId,
        courseName: course.title,
        chapterNames: chapterNames,
      );

      setState(() {
        _userProgress = progress;
        _progressInitialized = true;
        _lastCourseId = course.courseID;
      });
    } else {
      setState(() {
        _progressInitialized = true;
        _lastCourseId = course.courseID;
      });
    }
  }

  Future<void> _navigateToChapterLessons(Section section) async {
    // Track study session start
    if (_userProgress != null) {
      // Update last studied time for the chapter
      // This could be expanded to track when user actually starts reading
    }

    // Get the course data to pass to the overview
    try {
      final course = await _courseFuture;

      // Navigate directly to the lesson content
      if (section.lessons.isNotEmpty) {
        // If there's only one lesson, go directly to it
        if (section.lessons.length == 1) {
          final lesson = section.lessons.first;
          _navigateToSingleLesson(section, lesson);
        } else {
          // Multiple lessons - show a chapter overview or navigate to first lesson
          _showChapterLessonsOverview(section, course);
        }
      } else {
        // No lessons available - show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No lessons available in ${section.title}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading course for chapter navigation', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load course data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToSingleLesson(Section section, Lesson lesson) {
    final chapterId = _extractChapterId(section.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LessonViewScreen(
              courseId: widget.courseId,
              chapterId: chapterId,
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              lesson: lesson,
            ),
      ),
    ).then((result) async {
      // Refresh progress when returning from lesson
      if (result == true) {
        await _loadUserProgress();
        // Force UI rebuild
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _showChapterLessonsOverview(Section section, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              final theme = Theme.of(context);
              final chapterProgress =
                  _userProgress?.chapterProgress[section.id];

              // Get chapter status to check if MCQs are available
              final chapterStatus = course.getChapterStatus(section.id);
              final hasMcqs = chapterStatus?.hasMcqs ?? false;

              // Create mixed list of lessons and quizzes
              final List<Map<String, dynamic>> studyItems = [];

              for (int i = 0; i < section.lessons.length; i++) {
                final lesson = section.lessons[i];

                // Add lesson
                studyItems.add({
                  'type': 'lesson',
                  'lesson': lesson,
                  'index': i + 1,
                });

                // Add corresponding quiz if the chapter has MCQs available
                // MCQs can be generated independently of lesson content
                if (hasMcqs) {
                  final attempts =
                      chapterProgress?.quizAttempts[lesson.id] ?? [];
                  final bestAttempt =
                      attempts.isNotEmpty
                          ? attempts.reduce(
                            (a, b) =>
                                a.scorePercentage > b.scorePercentage ? a : b,
                          )
                          : null;

                  studyItems.add({
                    'type': 'quiz',
                    'lesson': lesson,
                    'index': i + 1,
                    'bestAttempt': bestAttempt,
                  });
                } else {
                  // Quiz not available for this lesson
                }
              }

              // Find first uncompleted lesson for auto-scroll
              int firstUncompletedIndex = -1;
              for (int i = 0; i < studyItems.length; i++) {
                final item = studyItems[i];
                if (item['type'] == 'lesson') {
                  final lesson = item['lesson'] as Lesson;
                  final isCompleted =
                      chapterProgress?.completedLessons.contains(lesson.id) ??
                      false;
                  if (!isCompleted && lesson.generated) {
                    firstUncompletedIndex = i;
                    break;
                  }
                }
              }

              // Auto-scroll to first uncompleted lesson after sheet is built
              if (firstUncompletedIndex >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    final itemHeight = 100.0; // Approximate height of each item
                    final scrollOffset = firstUncompletedIndex * itemHeight;
                    scrollController.animateTo(
                      scrollOffset,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }

              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${section.lessons.length} lessons${hasMcqs ? ' • Interactive quizzes available' : ''}${section.time.isNotEmpty ? ' • ~${section.time}' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Study items list
                    Expanded(
                      child:
                          studyItems.isNotEmpty
                              ? ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: studyItems.length,
                                itemBuilder: (context, index) {
                                  final item = studyItems[index];
                                  final isLesson = item['type'] == 'lesson';
                                  final lesson = item['lesson'] as Lesson;
                                  final itemIndex = item['index'] as int;

                                  if (isLesson) {
                                    return _buildLessonItem(
                                      lesson,
                                      itemIndex,
                                      section,
                                      theme,
                                      chapterProgress?.completedLessons
                                              .contains(lesson.id) ??
                                          false,
                                    );
                                  } else {
                                    final bestAttempt =
                                        item['bestAttempt'] as QuizAttempt?;
                                    return _buildQuizItem(
                                      lesson,
                                      itemIndex,
                                      section,
                                      theme,
                                      bestAttempt,
                                    );
                                  }
                                },
                              )
                              : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Content Available',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Generate content to start studying',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey[500]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                    ),
                    // Bottom padding for safe area
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildLessonItem(
    Lesson lesson,
    int index,
    Section section,
    ThemeData theme,
    bool isCompleted,
  ) {
    // Use clear color differentiation - more visible for completed items
    final cardColor =
        isCompleted
            ? Colors.grey.withOpacity(0.2)
            : theme.colorScheme.primary.withOpacity(0.1);
    final borderColor =
        isCompleted ? Colors.grey.shade600 : theme.colorScheme.primary;
    final textColor =
        isCompleted ? Colors.grey.shade700 : theme.colorScheme.primary;
    final circleColor =
        isCompleted ? Colors.grey.shade600 : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isCompleted ? 1 : 3, // Less elevation for completed
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: isCompleted ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close the modal
            _navigateToSingleLesson(section, lesson);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Leading circle with number or checkmark
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        isCompleted
                            ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                            : Text(
                              '$index',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? 'Completed' : _getLessonSubtitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: borderColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizItem(
    Lesson lesson,
    int index,
    Section section,
    ThemeData theme,
    QuizAttempt? bestAttempt,
  ) {
    final hasAttempt = bestAttempt != null;
    // Use more visible colors for completed quizzes, secondary color for active ones
    final quizColor =
        hasAttempt ? Colors.grey.shade600 : theme.colorScheme.secondary;
    final cardColor =
        hasAttempt
            ? Colors.grey.withOpacity(0.2)
            : theme.colorScheme.secondary.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: hasAttempt ? 1 : 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                hasAttempt
                    ? Colors.grey.shade600
                    : theme.colorScheme.secondary.withOpacity(0.3),
            width: hasAttempt ? 1 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close the modal
            _navigateToQuiz(section, lesson);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Leading circle with quiz icon or checkmark
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: quizColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        hasAttempt
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 28,
                            )
                            : const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${lesson.title} Quiz',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: quizColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAttempt ? 'Completed' : _getQuizSubtitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: quizColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score badge and arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAttempt)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: quizColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${bestAttempt.scorePercentage.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: quizColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: quizColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractChapterId(String sectionId) {
    // Try to extract chapter ID from sectionId (e.g., "chapter_2" -> "2")
    if (sectionId.contains('chapter-')) {
      return sectionId;
    } else if (sectionId.contains('_')) {
      return sectionId.split('_').last;
    }
    return sectionId;
  }

  // Helper method to get inspirational text for uncompleted lessons
  String _getLessonSubtitle() {
    final inspirationalTexts = [
      'Begin your journey! 📚',
      'Start exploring! 🚀',
      'Unlock new knowledge! 💡',
      'Begin learning! ✨',
      'Start your discovery! 🌟',
      'Dive into learning! 🏊‍♂️',
      'Embark on knowledge! 🎯',
      'Begin your quest! 🗺️',
      'Start your adventure! 🌈',
      'Unlock wisdom! 🔑',
    ];

    // Use a simple pseudo-random selection based on current time
    final index =
        DateTime.now().millisecondsSinceEpoch % inspirationalTexts.length;
    return inspirationalTexts[index];
  }

  // Helper method to get inspirational text for uncompleted quizzes
  String _getQuizSubtitle() {
    final inspirationalTexts = [
      'Test your knowledge! 🧠',
      'Challenge yourself! 💪',
      'Show what you\'ve learned! ⭐',
      'Put skills to test! 🎯',
      'Prove your mastery! 🏆',
      'Demonstrate learning! 📝',
      'Rise to the challenge! 🚀',
      'Showcase your skills! 💎',
      'Take the challenge! ⚡',
      'Time to shine! ✨',
    ];

    // Use a simple pseudo-random selection based on current time
    final index =
        DateTime.now().millisecondsSinceEpoch % inspirationalTexts.length;
    return inspirationalTexts[index];
  }

  void _navigateToQuiz(Section section, Lesson lesson) {
    final chapterId = _extractChapterId(section.id);

    // Find the lesson index within the section
    final lessonIndex = section.lessons.indexWhere((l) => l.id == lesson.id);

    Logger.i(
      _tag,
      'Navigating to quiz: lesson="${lesson.title}", index=$lessonIndex, sectionLessons=${section.lessons.length}',
    );
    for (int i = 0; i < section.lessons.length; i++) {
      final l = section.lessons[i];
      Logger.i(
        _tag,
        'Section lesson $i: "${l.title}", generated=${l.generated}',
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => McqQuizScreen(
              courseId: widget.courseId,
              chapterId: chapterId,
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              section: section,
              currentLessonIndex: lessonIndex >= 0 ? lessonIndex : null,
            ),
      ),
    ).then((result) async {
      // Refresh progress when returning from quiz
      await _loadUserProgress();
      // Force UI rebuild
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: 'Refresh course content',
          ),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: FutureBuilder<Course>(
            future: _courseFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Logger.d(_tag, 'Course details loading');
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                final error = snapshot.error;
                Logger.e(
                  _tag,
                  'Error loading course details',
                  error: error,
                  stackTrace: StackTrace.current,
                );
                return _buildErrorView(context, error, theme);
              } else if (!snapshot.hasData) {
                Logger.w(
                  _tag,
                  'No course data found for ID: ${widget.courseId}',
                );
                return const Center(child: Text('Course not found'));
              }

              final course = snapshot.data!;

              // Initialize progress and load recommendations only once per course
              if (!_progressInitialized || _lastCourseId != course.courseID) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _initializeProgress(course);
                });
              }

              if (!_recommendationsLoaded || _lastCourseId != course.courseID) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadStudyRecommendation(course);
                });
              }

              Logger.i(
                _tag,
                'Course details loaded successfully',
                data: {
                  'id': course.courseID,
                  'title': course.title,
                  'sections': course.sections?.length ?? 0,
                  'lessons': course.lessons?.length ?? 0,
                },
              );
              return _buildCourseView(context, course, theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Object? error, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading course details',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Logger.i(_tag, 'User trying to reload course after error');
                  setState(() {
                    _loadCourse();
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseView(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    Widget sectionsContent;

    if (course.sections != null && course.sections!.isNotEmpty) {
      Logger.d(_tag, 'Rendering ${course.sections!.length} sections');
      sectionsContent = _buildSectionsList(
        context,
        course.sections!,
        course,
        theme,
      );
    } else if (course.lessons != null && course.lessons!.isNotEmpty) {
      Logger.d(
        _tag,
        'Rendering legacy view with ${course.lessons!.length} lessons',
      );
      sectionsContent = _buildLegacySectionView(context, course, theme);
    } else {
      Logger.w(_tag, 'Course has no content: ${course.courseID}');
      sectionsContent = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            'No content available for this course',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCourseHeader(context, course, theme),
        const SizedBox(height: 16),
        if (_studyRecommendation != null) ...[
          _buildStudyRecommendationCard(theme),
          const SizedBox(height: 16),
        ],
        Text(
          'Chapters',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        sectionsContent,
      ],
    );
  }

  Widget _buildCourseHeader(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Cover Image Section
          _buildCourseCoverImage(course, theme),

          // Course Info Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Collapsible Description
                _buildCollapsibleDescription(course.description, theme),

                const SizedBox(height: 16),

                // Course metadata row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (course.createdAt != null)
                      _buildMetaChip(
                        icon: Icons.calendar_today,
                        label: 'Created: ${_formatDate(course.createdAt!)}',
                        theme: theme,
                      ),
                    if (course.author.isNotEmpty &&
                        course.author != 'Unknown' &&
                        !_looksLikeUUID(course.author))
                      _buildMetaChip(
                        icon: Icons.person_outline,
                        label: course.author,
                        theme: theme,
                      ),
                    if (course.sections?.isNotEmpty == true ||
                        course.lessons?.isNotEmpty == true)
                      _buildMetaChip(
                        icon: Icons.book_outlined,
                        label: _getCourseContentText(course),
                        theme: theme,
                        isPrimary: true,
                      ),
                  ],
                ),

                // Add study stats if available
                if (_userProgress != null) ...[
                  const SizedBox(height: 20),
                  _buildProgressSummary(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDescription(String description, ThemeData theme) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    const int maxLines = 3;
    const int maxCharsBeforeEllipsis = 150;

    // Check if description is long enough to need collapsing
    final isLongDescription = description.length > maxCharsBeforeEllipsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _isDescriptionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
          firstChild: Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
        if (isLongDescription) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isDescriptionExpanded ? 'Show less' : 'Show more',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCourseCoverImage(Course course, ThemeData theme) {
    const double imageHeight = 200;

    if (course.coverImageUrl != null && course.coverImageUrl!.isNotEmpty) {
      final imageUrl = AppConstants.getImageUrl(course.coverImageUrl!);

      if (imageUrl.isNotEmpty) {
        return SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: AuthenticatedImage(
            imageUrl: imageUrl,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: _buildCourseCoverPlaceholder(
              course,
              theme,
              isLoading: true,
            ),
            errorWidget: _buildCourseCoverPlaceholder(
              course,
              theme,
              hasError: true,
            ),
            onImageLoaded: () {
              Logger.d(_tag, 'Course image loaded: ${course.title}');
            },
            onImageError: (error) {
              Logger.e(
                _tag,
                'Failed to load course image: ${course.title} - $error',
              );
            },
          ),
        );
      }
    }

    return _buildCourseCoverPlaceholder(course, theme);
  }

  Widget _buildCourseCoverPlaceholder(
    Course course,
    ThemeData theme, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    const double imageHeight = 200;

    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.15),
            theme.colorScheme.tertiary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError ? Icons.broken_image_outlined : Icons.auto_stories,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                hasError ? 'Course image unavailable' : course.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isPrimary
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            isPrimary
                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isPrimary
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCourseContentText(Course course) {
    if (course.sections?.isNotEmpty == true) {
      final chapterCount = course.sections!.length;
      final lessonCount = course.sections!.fold<int>(
        0,
        (sum, section) => sum + section.lessons.length,
      );

      if (chapterCount == 1) {
        return '$lessonCount lessons';
      } else {
        return '$chapterCount chapters • $lessonCount lessons';
      }
    } else if (course.lessons?.isNotEmpty == true) {
      final lessonCount = course.lessons!.length;
      return '$lessonCount lessons';
    }

    return 'Course content';
  }

  Widget _buildProgressSummary(ThemeData theme) {
    final progress = _userProgress!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${progress.completedLessons}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Lessons\nCompleted',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${progress.totalQuizzesTaken}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  'Quizzes\nTaken',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${progress.averageQuizScore.round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Avg\nScore',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyRecommendationCard(ThemeData theme) {
    final recommendation = _studyRecommendation!;

    if (!recommendation.hasContentToStudy && !recommendation.hasSuggestions) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Study Recommendation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendation.currentToStudy != null) ...[
              Text(
                '📚 Continue studying your current chapter',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            if (recommendation.isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Content is being prepared in the background...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSectionsList(
    BuildContext context,
    List<Section> sections,
    Course course,
    ThemeData theme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        Logger.v(
          _tag,
          'Rendering section: ${section.title} with ${section.lessons.length} lessons',
        );

        // Get chapter status and progress for this section
        final chapterStatus = course.getChapterStatus(section.id);
        final chapterProgress = _userProgress?.chapterProgress[section.id];

        return StudyChapterCard(
          section: section,
          progress: chapterProgress,
          status: chapterStatus,
          onTap: () => _navigateToChapterLessons(section),
          onGenerateContent:
              () => _startChapterGeneration(section.id, section.title),
        );
      },
    );
  }

  Widget _buildLegacySectionView(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    // Create a fake section for legacy courses
    final mainSection = Section(
      id: 'main',
      title: 'Main Chapter',
      description: '',
      time: '',
      lessons: course.lessons ?? [],
    );

    final chapterStatus = course.getChapterStatus('main');
    final chapterProgress = _userProgress?.chapterProgress['main'];

    return StudyChapterCard(
      section: mainSection,
      progress: chapterProgress,
      status: chapterStatus,
      onTap: () => _navigateToChapterLessons(mainSection),
      onGenerateContent: () => _startChapterGeneration('main', 'Main Chapter'),
    );
  }

  /// Helper method to detect if a string looks like a UUID
  /// UUIDs typically have the format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  bool _looksLikeUUID(String input) {
    if (input.length != 36) return false;

    // Check for UUID pattern: 8-4-4-4-12 characters separated by hyphens
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(input);
  }
}
