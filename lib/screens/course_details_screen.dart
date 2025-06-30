import 'dart:async';
import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/lesson.dart';
import '../models/section.dart';
import '../models/user_progress.dart';
import '../screens/lesson_view_screen.dart';
import '../screens/mcq_quiz_screen.dart';
import '../screens/flashcard_screen.dart';
import '../services/api_service.dart';
import '../services/chapter_generation_service.dart';
import '../services/generation_strategy_service.dart';
import '../services/progress_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../widgets/authenticated_image.dart';
import '../widgets/study_chapter_card.dart';
import '../components/custom_app_bar.dart';

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

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final ProgressService _progressService = ProgressService();
  final GenerationStrategyService _generationService =
      GenerationStrategyService();
  final ChapterGenerationService _chapterGenerationService =
      ChapterGenerationService();

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
  
  // Background generation polling
  Timer? _backgroundPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Added additional validation and logging for courseId
    if (widget.courseId.isEmpty) {
      Logger.e(_tag, 'Empty courseId provided to CourseDetailsScreen');
    }
    Logger.i(_tag, 'Screen initialized for course ID: "${widget.courseId}"');

    // Resume polling for this course if there are active generations
    _chapterGenerationService.resumeCoursePolling(widget.courseId);

    _loadCourse();
    _loadUserProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Stop background polling timer
    _backgroundPollingTimer?.cancel();

    // Stop polling when user navigates away from this screen
    _chapterGenerationService.stopCoursePolling(widget.courseId);

    _generationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Stop polling when app goes to background
        _chapterGenerationService.stopCoursePolling(widget.courseId);
        break;
      case AppLifecycleState.resumed:
        // Resume polling when app comes to foreground
        _chapterGenerationService.resumeCoursePolling(widget.courseId);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action needed for inactive or hidden states
        break;
    }
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
        final shouldGenerate =
            await _generationService.showGenerationSuggestion(
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
      courseId: widget.courseId,
      chapterId: chapterId,
      onRunInBackground: () {
        // Trigger immediate UI update to show background generation
        Logger.i(_tag, 'User clicked "Run in Background" - updating UI');

        // Force refresh of study recommendations to show background generations
        _forceRefreshStudyRecommendation();

        // Force immediate setState to refresh the study recommendation card
        if (mounted) {
          setState(() {
            // This will trigger a rebuild and show the background generation indicator
          });
        }

        // Start periodic refresh while background generation is active
        _startBackgroundGenerationPolling();

        // Also trigger a delayed refresh to ensure data is up to date
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _handleRefresh();
          }
        });
      },
    );

    // Listen for completion to refresh the course data (for foreground completion)
    progressStream.listen((progress) {
      if (progress.phase == GenerationPhase.completed) {
        Logger.i(_tag, 'Foreground generation completed for $chapterId - refreshing UI');
        _handleRefresh();
      }
    });
  }

  Future<void> _forceRefreshStudyRecommendation() async {
    try {
      final course = await _courseFuture;
      final chapterIds = course.sections?.map((s) => s.id).toList() ?? ['main'];
      final recommendation = await _generationService.getStudyRecommendation(
        courseId: widget.courseId,
        allChapterIds: chapterIds,
        chaptersStatus: course.chaptersStatus,
      );

      if (mounted) {
        setState(() {
          _studyRecommendation = recommendation;
        });
      }

      Logger.i(
        _tag,
        'Study recommendation force refreshed',
        data: {
          'hasContentToStudy': recommendation.hasContentToStudy,
          'hasSuggestions': recommendation.hasSuggestions,
          'nextToGenerate': recommendation.nextToGenerate,
          'backgroundGenerations': _generationService
              .getBackgroundGenerations(widget.courseId)
              .length,
        },
      );
    } catch (e) {
      Logger.e(_tag, 'Error force refreshing study recommendation', error: e);
    }
  }

  Future<void> _handleRefresh() async {
    Logger.i(_tag, 'Refreshing course details for ID: ${widget.courseId}');
    setState(() {
      _isRefreshing = true;
    });

    await _loadCourse();
    await _loadUserProgress();

    // Check if course data was updated after refresh
    try {
      final course = await _courseFuture;
      Logger.i(
        _tag,
        'Course refresh completed - checking chapter status:',
        data: {
          'courseId': course.courseID,
          'sectionsCount': course.sections?.length ?? 0,
          'chaptersStatus': course.chaptersStatus.map(
            (key, value) => MapEntry(key, {
              'lessonsStatus': value.lessonsStatus,
              'mcqsStatus': value.mcqsStatus,
              'hasContent': value.hasContent,
              'isGenerating': value.isGenerating,
            }),
          ),
        },
      );
    } catch (e) {
      Logger.e(_tag, 'Error checking course data after refresh', error: e);
    }

    setState(() {
      _isRefreshing = false;
    });

    Logger.i(_tag, 'Course refresh setState completed');
  }

  void _startBackgroundGenerationPolling() {
    // Stop any existing polling timer
    _backgroundPollingTimer?.cancel();

    Logger.i(_tag, 'Starting lightweight background generation polling');
    
    _backgroundPollingTimer = Timer.periodic(
      const Duration(seconds: 5), // Check more frequently but lightweight
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Lightweight check - just see if background generations are still active
        final backgroundGenerations = _generationService.getBackgroundGenerations(widget.courseId);
        
        if (backgroundGenerations.isEmpty) {
          // Background generation completed! Now refresh the UI once
          Logger.i(_tag, 'Background generation completed - refreshing UI once');
          timer.cancel();
          _backgroundPollingTimer = null;
          
          // Only refresh now that generation is actually complete
          await _handleRefresh();
          return;
        }

        // Still generating - just log, don't refresh the entire screen
        Logger.d(_tag, 'Background generation still active (${backgroundGenerations.length} chapters) - no UI refresh needed');
      },
    );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No lessons available in ${section.title}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading course for chapter navigation', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load course data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSingleLesson(Section section, Lesson lesson) {
    final chapterId = _extractChapterId(section.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewScreen(
          courseId: widget.courseId,
          chapterId: chapterId,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          lesson: lesson,
        ),
      ),
    ).then((result) async {
      // Refresh progress when returning from lesson or quiz
      if (result != null) {
        bool shouldRefresh = false;
        
        if (result == true) {
          // Simple boolean return (legacy lesson completion)
          shouldRefresh = true;
        } else if (result is Map<String, dynamic>) {
          if (result['quizCompleted'] == true) {
            // Quiz completion return with details
            shouldRefresh = true;
            Logger.i('CourseDetailsScreen', 'Quiz completed from lesson view. Score: ${result['score']}/${result['totalQuestions']}');
          } else if (result['lessonCompleted'] == true) {
            // Lesson completion return with details
            shouldRefresh = true;
            Logger.i('CourseDetailsScreen', 'Lesson completed: "${result['lessonTitle']}" in chapter ${result['chapterId']}');
          }
        }
        
        if (shouldRefresh) {
          await _handleRefresh();
        }
      }
    });
  }

  void _showChapterLessonsOverview(Section section, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final chapterProgress = _userProgress?.chapterProgress[section.id];

          // Get chapter status to check if MCQs and flashcards are available
          final chapterStatus = course.getChapterStatus(section.id);
          final hasMcqs = chapterStatus?.hasMcqs ?? false;
          final hasFlashcards = chapterStatus?.hasFlashcards ?? false;

          // Calculate progress
          final totalLessons = section.lessons.length;
          final completedLessons = chapterProgress?.completedLessons.length ?? 0;
          final totalQuizAttempts = chapterProgress?.quizAttempts.values.expand((attempts) => attempts).length ?? 0;
          final totalFlashcardSessions = chapterProgress?.flashcardAttempts.values.expand((attempts) => attempts).length ?? 0;
          final progressPercentage = totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;

          // Find next recommended action (lesson → flashcards → quiz)
          String nextAction = 'Start your first lesson';
          int? nextLessonIndex;
          for (int i = 0; i < section.lessons.length; i++) {
            final lesson = section.lessons[i];
            final isCompleted = chapterProgress?.completedLessons.contains(lesson.id) ?? false;
            final hasQuizAttempts = (chapterProgress?.quizAttempts[lesson.id]?.isNotEmpty ?? false);
            final hasFlashcardAttempts = (chapterProgress?.flashcardAttempts[lesson.id]?.isNotEmpty ?? false);
            
            if (!isCompleted && lesson.generated) {
              nextAction = 'Continue with "${lesson.title}"';
              nextLessonIndex = i;
              break;
            } else if (isCompleted && hasFlashcards && !hasFlashcardAttempts) {
              nextAction = 'Reinforce learning with "${lesson.title}" flashcards';
              nextLessonIndex = i;
              break;
            } else if (isCompleted && hasFlashcardAttempts && hasMcqs && !hasQuizAttempts) {
              nextAction = 'Test your knowledge with "${lesson.title}" quiz';
              nextLessonIndex = i;
              break;
            } else if (isCompleted && hasMcqs && !hasQuizAttempts && !hasFlashcards) {
              nextAction = 'Test your knowledge with "${lesson.title}" quiz';
              nextLessonIndex = i;
              break;
            }
          }
          
          if (nextLessonIndex == null && completedLessons > 0) {
            nextAction = 'Great progress! Keep learning';
          }

          // Auto-scroll to next uncompleted lesson after sheet is built
          if (nextLessonIndex != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                final itemHeight = 200.0; // Approximate height of each learning path item
                final scrollOffset = nextLessonIndex! * itemHeight;
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
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header with progress
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${section.lessons.length} lessons • ${section.time.isNotEmpty ? section.time : 'Self-paced'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progress bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Progress',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${(progressPercentage * 100).round()}%',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progressPercentage,
                              backgroundColor: colorScheme.outline.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completedLessons of $totalLessons lessons completed${totalQuizAttempts > 0 ? ' • $totalQuizAttempts quiz attempts' : ''}${totalFlashcardSessions > 0 ? ' • $totalFlashcardSessions flashcard sessions' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Next action recommendation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary.withOpacity(0.1),
                              colorScheme.secondary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.secondary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: colorScheme.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommended Next',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextAction,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Learning path
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: section.lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = section.lessons[index];
                      return _buildLearningPathItem(
                        lesson,
                        index,
                        section,
                        theme,
                        chapterProgress,
                        hasMcqs,
                        hasFlashcards,
                        nextLessonIndex == index,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLearningPathItem(
    Lesson lesson,
    int index,
    Section section,
    ThemeData theme,
    ChapterProgress? chapterProgress,
    bool hasMcqs,
    bool hasFlashcards,
    bool isRecommended,
  ) {
    final colorScheme = theme.colorScheme;
    final isCompleted = chapterProgress?.completedLessons.contains(lesson.id) ?? false;
    final quizAttempts = chapterProgress?.quizAttempts[lesson.id] ?? [];
    final flashcardAttempts = chapterProgress?.flashcardAttempts[lesson.id] ?? [];
    final hasFlashcardCompletion = flashcardAttempts.isNotEmpty;
    final bestQuizScore = quizAttempts.isNotEmpty 
        ? quizAttempts.map((a) => a.scorePercentage).reduce((a, b) => a > b ? a : b)
        : null;
    
    // Determine the current step in the learning path (lesson → flashcards → quiz)
    String currentStep = 'lesson';
    if (isCompleted && hasFlashcards && !hasFlashcardCompletion) {
      currentStep = 'flashcards'; // Next step is flashcards
    } else if (isCompleted && hasFlashcardCompletion && hasMcqs && quizAttempts.isEmpty) {
      currentStep = 'quiz'; // Flashcards done, now do quiz
    } else if (isCompleted && hasFlashcards && !hasMcqs && hasFlashcardCompletion) {
      currentStep = 'completed'; // Only flashcards available and done
    } else if (isCompleted && !hasFlashcards && hasMcqs && quizAttempts.isEmpty) {
      currentStep = 'quiz'; // No flashcards, go straight to quiz
    } else if (isCompleted && ((hasFlashcards && hasFlashcardCompletion) || !hasFlashcards) && hasMcqs && quizAttempts.isNotEmpty) {
      currentStep = 'completed'; // All available steps done
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson number and title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? colorScheme.primary 
                      : isRecommended 
                          ? colorScheme.secondary
                          : colorScheme.outline.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                          size: 20,
                        )
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isRecommended 
                                ? colorScheme.onSecondary
                                : colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isRecommended)
                      Text(
                        'Recommended next',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Learning path steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRecommended 
                    ? colorScheme.secondary.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.2),
                width: isRecommended ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Step 1: Read Lesson
                _buildPathStep(
                  context: context,
                  theme: theme,
                  stepNumber: 1,
                  title: 'Read Lesson',
                  subtitle: lesson.generated ? 'Tap to start reading' : 'Content not ready',
                  icon: Icons.menu_book,
                  isCompleted: isCompleted,
                  isActive: currentStep == 'lesson',
                  isEnabled: lesson.generated,
                  onTap: lesson.generated ? () {
                    Navigator.pop(context);
                    _navigateToSingleLesson(section, lesson);
                  } : null,
                ),

                if (hasFlashcards) ...[
                  _buildStepConnector(theme, isCompleted),
                  
                  // Step 2: Study Flashcards
                  _buildPathStep(
                    context: context,
                    theme: theme,
                    stepNumber: 2,
                    title: 'Study Flashcards',
                    subtitle: hasFlashcardCompletion
                        ? '${flashcardAttempts.length} session${flashcardAttempts.length > 1 ? 's' : ''} completed'
                        : isCompleted
                            ? 'Reinforce your learning'
                            : 'Complete lesson first',
                    icon: Icons.style,
                    isCompleted: hasFlashcardCompletion,
                    isActive: currentStep == 'flashcards',
                    isEnabled: isCompleted,
                    onTap: isCompleted ? () {
                      Navigator.pop(context);
                      _navigateToFlashcards(section, lesson);
                    } : null,
                  ),
                ],

                if (hasMcqs) ...[
                  _buildStepConnector(theme, isCompleted && (!hasFlashcards || hasFlashcardCompletion)),
                  
                  // Step 3: Take Quiz (after flashcards if available)
                  _buildPathStep(
                    context: context,
                    theme: theme,
                    stepNumber: hasFlashcards ? 3 : 2,
                    title: 'Take Quiz',
                    subtitle: bestQuizScore != null 
                        ? 'Best score: ${bestQuizScore!.round()}%'
                        : isCompleted 
                            ? 'Test your knowledge'
                            : 'Complete lesson first',
                    icon: Icons.quiz,
                    isCompleted: quizAttempts.isNotEmpty,
                    isActive: currentStep == 'quiz',
                    isEnabled: isCompleted,
                    onTap: isCompleted ? () {
                      Navigator.pop(context);
                      _navigateToQuiz(section, lesson);
                    } : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathStep({
    required BuildContext context,
    required ThemeData theme,
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    final colorScheme = theme.colorScheme;
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? colorScheme.primary
                    : isActive
                        ? colorScheme.secondary
                        : isEnabled
                            ? colorScheme.outline.withOpacity(0.1)
                            : colorScheme.outline.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted
                    ? colorScheme.onPrimary
                    : isActive
                        ? colorScheme.onSecondary
                        : isEnabled
                            ? colorScheme.onSurface.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.3),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isEnabled
                          ? colorScheme.onSurface.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow or check
            if (isEnabled)
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(ThemeData theme, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 2,
            height: 16,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(width: 18),
        ],
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
    final colorScheme = theme.colorScheme;
    // Use consistent card color for all lesson items
    final cardColor = colorScheme.cardColor;
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
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 28,
                          )
                        : Text(
                            '$index',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? 'Completed' : _getLessonSubtitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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
    final colorScheme = theme.colorScheme;
    final hasAttempt = bestAttempt != null;
    // Use consistent card color for all quiz items
    final cardColor = colorScheme.cardColor;
    final quizColor =
        hasAttempt ? Colors.grey.shade600 : theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: hasAttempt ? 1 : 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hasAttempt
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
                    child: hasAttempt
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
                          color: quizColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAttempt ? 'Completed' : _getQuizSubtitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: quizColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
        builder: (context) => McqQuizScreen(
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
      if (result != null && result is Map<String, dynamic> && result['quizCompleted'] == true) {
        Logger.i(_tag, 'Quiz completed from modal. Score: ${result['score']}/${result['totalQuestions']}');
      }
      
      await _handleRefresh();
    });
  }

  Widget _buildFlashcardItem(
    Lesson lesson,
    int itemIndex,
    Section section,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    // Use consistent card color for all flashcard items
    final cardColor = colorScheme.cardColor;
    final flashcardColor = theme.colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: flashcardColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close the modal
            _navigateToFlashcards(section, lesson);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flashcard icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: flashcardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.style,
                    color: flashcardColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flashcards: ${lesson.title}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Study with interactive flashcards',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFlashcards(Section section, Lesson lesson) {
    final chapterId = _extractChapterId(section.id);

    // Find the lesson index within the section
    final lessonIndex = section.lessons.indexWhere((l) => l.id == lesson.id);

    Logger.i(
      _tag,
      'Navigating to flashcards: lesson="${lesson.title}", index=$lessonIndex, sectionLessons=${section.lessons.length}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          courseId: widget.courseId,
          chapterId: chapterId,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          section: section,
          currentLessonIndex: lessonIndex >= 0 ? lessonIndex : null,
        ),
      ),
    ).then((result) async {
      // Handle any result from flashcard screen if needed
      if (result != null && result is Map<String, dynamic> && result['flashcardsCompleted'] == true) {
        Logger.i(_tag, 'Flashcards completed from modal');
      }
      
      await _handleRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the body background from theme manager
    final bodyBackgroundColor = colorScheme.bodyBackground;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: CustomAppBar(
        title: 'Course Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: 'Refresh course content',
          ),
        ],
      ),
      body: RefreshIndicator(
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
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.cardColor,
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
          crossFadeState: _isDescriptionExpanded
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
        color: isPrimary
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: isPrimary
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPrimary
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
          onGenerateContent: () =>
              _startChapterGeneration(section.id, section.title),
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
