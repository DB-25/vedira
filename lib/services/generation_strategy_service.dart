import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chapter_generation_service.dart';
import '../services/progress_service.dart';
import '../models/chapter_status.dart';
import '../models/user_progress.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';

class GenerationStrategyService {
  final ChapterGenerationService _generationService =
      ChapterGenerationService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'GenerationStrategyService';

  // Active generation streams
  final Map<String, StreamSubscription> _activeGenerations = {};
  final Map<String, StreamController<GenerationProgress>> _progressControllers =
      {};

  // Track which generations should continue in background
  final Set<String> _backgroundGenerations = {};

  // Callbacks for background generation completion
  final Map<String, VoidCallback> _backgroundCompletionCallbacks = {};

  // Suggested chapters to generate
  final Set<String> _suggestedChapters = {};

  // Periodic background status checker
  Timer? _backgroundPollingTimer;

  // Move generation to background (continue polling but no UI updates)
  void moveToBackground(
    String courseId,
    String chapterId, {
    VoidCallback? onCompleted,
  }) {
    final key = '$courseId-$chapterId';
    Logger.i(_tag, 'Moving generation to background: $key');
    _backgroundGenerations.add(key);

    // Store completion callback if provided
    if (onCompleted != null) {
      _backgroundCompletionCallbacks[key] = onCompleted;
    }

    // Close the progress controller to stop UI updates, but keep the underlying generation running
    _progressControllers[key]?.close();
    _progressControllers.remove(key);

    Logger.i(
      _tag,
      'Generation moved to background - UI updates stopped for: $key',
    );
  }

  // Check if a generation is running in background
  bool isRunningInBackground(String courseId, String chapterId) {
    final key = '$courseId-$chapterId';
    return _backgroundGenerations.contains(key);
  }

  // Get list of all background generations for a course
  List<String> getBackgroundGenerations(String courseId) {
    return _backgroundGenerations
        .where((key) => key.startsWith('$courseId-'))
        .map((key) => key.substring('$courseId-'.length))
        .toList();
  }

  // Check what user should study next and suggest proactive generation
  Future<StudyRecommendation> getStudyRecommendation({
    required String courseId,
    required List<String> allChapterIds,
    required Map<String, ChapterStatus> chaptersStatus,
  }) async {
    try {
      final progress = await _progressService.getCourseProgress(courseId);

      // Find available chapters to study
      final availableChapters = <String>[];
      final generatingChapters = <String>[];
      final suggestedToGenerate = <String>[];

      for (var chapterId in allChapterIds) {
        final status = chaptersStatus[chapterId];

        if (status?.hasContent == true) {
          availableChapters.add(chapterId);
        } else if (status?.isGenerating == true) {
          generatingChapters.add(chapterId);
        } else {
          // Not generated yet - potential candidate for suggestion
          suggestedToGenerate.add(chapterId);
        }
      }

      // Smart suggestions based on current progress
      String? nextToGenerate;
      String? currentToStudy;

      if (availableChapters.isNotEmpty) {
        // Find the chapter with least progress to continue studying
        currentToStudy = _findChapterWithLeastProgress(
          availableChapters,
          progress,
        );

        // Suggest generating the next chapter in sequence
        final currentIndex = allChapterIds.indexOf(currentToStudy!);
        if (currentIndex >= 0 && currentIndex + 1 < allChapterIds.length) {
          final nextChapter = allChapterIds[currentIndex + 1];
          if (suggestedToGenerate.contains(nextChapter)) {
            nextToGenerate = nextChapter;
          }
        }
      } else if (suggestedToGenerate.isNotEmpty) {
        // No content available, suggest first chapter
        nextToGenerate = suggestedToGenerate.first;
      }

      return StudyRecommendation(
        currentToStudy: currentToStudy,
        nextToGenerate: nextToGenerate,
        availableChapters: availableChapters,
        generatingChapters: generatingChapters,
        suggestedToGenerate:
            suggestedToGenerate.take(2).toList(), // Limit suggestions
      );
    } catch (e) {
      Logger.e(_tag, 'Error getting study recommendation', error: e);
      return StudyRecommendation.empty();
    }
  }

  // Start generation with user-friendly progress tracking
  Stream<GenerationProgress> startGeneration({
    required String courseId,
    required String chapterId,
    required BuildContext context,
  }) {
    final key = '$courseId-$chapterId';

    // Cancel existing generation for this chapter
    _activeGenerations[key]?.cancel();
    _progressControllers[key]?.close();

    // Create new progress stream
    final controller = StreamController<GenerationProgress>.broadcast();
    _progressControllers[key] = controller;

    // Start the generation process
    _startGenerationProcess(courseId, chapterId, controller, context);

    return controller.stream;
  }

  // Check if a chapter is currently being generated
  bool isGenerating(String courseId, String chapterId) {
    final key = '$courseId-$chapterId';
    return _activeGenerations.containsKey(key);
  }

  // Cancel generation for a specific chapter
  void cancelGeneration(String courseId, String chapterId) {
    final key = '$courseId-$chapterId';
    _activeGenerations[key]?.cancel();
    _activeGenerations.remove(key);
    _progressControllers[key]?.close();
    _progressControllers.remove(key);
  }

  // Show smart generation suggestion dialog
  Future<bool> showGenerationSuggestion({
    required BuildContext context,
    required String chapterName,
    required String currentActivity,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: colorScheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'Smart Study Suggestion',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Content
                      Text(
                        'While you $currentActivity, would you like me to prepare "$chapterName" for you?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Info box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This takes 5-10 minutes, perfect timing!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Primary action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Yes, prepare it!',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary action
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: colorScheme.outline),
                          ),
                          child: Text(
                            'Not now',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ) ??
        false;
  }

  // Show generation progress dialog
  void showGenerationProgress({
    required BuildContext context,
    required String chapterName,
    required Stream<GenerationProgress> progressStream,
    required String courseId,
    required String chapterId,
    VoidCallback? onRunInBackground,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => GenerationProgressDialog(
            chapterName: chapterName,
            progressStream: progressStream,
            courseId: courseId,
            chapterId: chapterId,
            onRunInBackground: () {
              // Call the UI callback immediately when user clicks "Run in Background"
              onRunInBackground?.call();

              // Then move generation to background (without completion callback since we already called it)
              moveToBackground(courseId, chapterId);
            },
          ),
    );
  }

  // Private helper methods
  String? _findChapterWithLeastProgress(
    List<String> availableChapters,
    UserProgress? progress,
  ) {
    if (progress == null || availableChapters.isEmpty) {
      return availableChapters.isNotEmpty ? availableChapters.first : null;
    }

    String? leastProgressChapter;
    double leastProgress = 100.0;

    for (var chapterId in availableChapters) {
      final chapterProgress = progress.chapterProgress[chapterId];
      final progressPercent = chapterProgress?.completionPercentage ?? 0.0;

      if (progressPercent < leastProgress) {
        leastProgress = progressPercent;
        leastProgressChapter = chapterId;
      }
    }

    return leastProgressChapter ?? availableChapters.first;
  }

  void _startGenerationProcess(
    String courseId,
    String chapterId,
    StreamController<GenerationProgress> controller,
    BuildContext context,
  ) async {
    final key = '$courseId-$chapterId';

    try {
      // Initial progress
      if (!controller.isClosed) {
        controller.add(
          GenerationProgress(
            phase: GenerationPhase.starting,
            message: 'Starting content generation...',
            progress: 0.0,
          ),
        );
      }

      // Start the actual generation
      final generationStream = _generationService.generateChapter(
        courseId: courseId,
        chapterId: chapterId,
      );

      final subscription = generationStream.listen(
        (result) {
          // Only send updates if not running in background and controller is open
          final isBackground = _backgroundGenerations.contains(key);
          final shouldSendUpdate = !isBackground && !controller.isClosed;

          switch (result.status) {
            case ChapterGenerationStatus.completed:
              Logger.i(
                _tag,
                'Generation completed for $key (background: $isBackground)',
              );
              if (shouldSendUpdate) {
                controller.add(
                  GenerationProgress(
                    phase: GenerationPhase.completed,
                    message: 'Content ready! 🎉',
                    progress: 1.0,
                  ),
                );
              }

              // Call background completion callback if this was a background generation
              if (isBackground &&
                  _backgroundCompletionCallbacks.containsKey(key)) {
                Logger.i(
                  _tag,
                  'Calling background completion callback for $key',
                );
                _backgroundCompletionCallbacks[key]?.call();
              }

              _cleanup(key);
              break;

            case ChapterGenerationStatus.running:
              if (shouldSendUpdate) {
                controller.add(
                  GenerationProgress(
                    phase: GenerationPhase.generating,
                    message: _getProgressMessage(result),
                    progress: _estimateProgress(result),
                  ),
                );
              }
              break;

            case ChapterGenerationStatus.failed:
              Logger.e(_tag, 'Generation failed for $key: ${result.error}');
              if (shouldSendUpdate) {
                controller.add(
                  GenerationProgress(
                    phase: GenerationPhase.failed,
                    message: 'Generation failed. Please try again.',
                    progress: 0.0,
                    error: result.error,
                  ),
                );
              }
              _cleanup(key);
              break;

            case ChapterGenerationStatus.timeout:
              Logger.w(_tag, 'Generation timed out for $key');
              if (shouldSendUpdate) {
                controller.add(
                  GenerationProgress(
                    phase: GenerationPhase.timeout,
                    message: 'Generation is taking longer than expected.',
                    progress: 0.5,
                  ),
                );
              }
              break;
          }
        },
        onError: (error) {
          Logger.e(_tag, 'Generation error for $key', error: error);
          if (!controller.isClosed) {
            controller.add(
              GenerationProgress(
                phase: GenerationPhase.failed,
                message: 'An error occurred during generation.',
                progress: 0.0,
                error: error.toString(),
              ),
            );
          }
          _cleanup(key);
        },
      );

      _activeGenerations[key] = subscription;
    } catch (e) {
      Logger.e(_tag, 'Error starting generation process', error: e);
      if (!controller.isClosed) {
        controller.add(
          GenerationProgress(
            phase: GenerationPhase.failed,
            message: 'Failed to start generation.',
            progress: 0.0,
            error: e.toString(),
          ),
        );
      }
      _cleanup(key);
    }
  }

  void _cleanup(String key) {
    Logger.d(_tag, 'Cleaning up generation: $key');
    _activeGenerations[key]?.cancel();
    _activeGenerations.remove(key);
    _backgroundGenerations.remove(key);
    _backgroundCompletionCallbacks.remove(key);

    // Close controller after a delay to allow final message to be received
    Timer(const Duration(seconds: 2), () {
      _progressControllers[key]?.close();
      _progressControllers.remove(key);
    });
  }

  String _getProgressMessage(ChapterGenerationResult result) {
    // TODO: Extract more specific progress info from result
    return 'Creating lessons and quizzes...';
  }

  double _estimateProgress(ChapterGenerationResult result) {
    // TODO: Better progress estimation based on result details
    return 0.5; // Assume halfway through
  }

  void startBackgroundPolling() {
    if (_backgroundPollingTimer?.isActive == true) return;

    Logger.i(_tag, 'Starting background polling for generations');
    _backgroundPollingTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (timer) async {
        if (_backgroundGenerations.isEmpty) {
          Logger.d(_tag, 'No background generations, stopping polling');
          timer.cancel();
          return;
        }

        Logger.d(
          _tag,
          'Checking ${_backgroundGenerations.length} background generations',
        );

        // Check each background generation
        final completedGenerations = <String>[];
        for (final key in _backgroundGenerations.toList()) {
          try {
            final parts = key.split('-');
            if (parts.length >= 2) {
              final courseId = parts[0];
              final chapterId = parts.sublist(1).join('-');

              // This would need to be implemented to check individual chapter status
              // For now, we'll rely on the existing stream-based approach
            }
          } catch (e) {
            Logger.e(
              _tag,
              'Error checking background generation: $key',
              error: e,
            );
            completedGenerations.add(key);
          }
        }

        // Clean up completed generations
        for (final key in completedGenerations) {
          _backgroundGenerations.remove(key);
        }
      },
    );
  }

  void stopBackgroundPolling() {
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = null;
    Logger.i(_tag, 'Stopped background polling');
  }

  void dispose() {
    stopBackgroundPolling();
    Logger.i(
      _tag,
      'Disposing GenerationStrategyService - cancelling all active generations',
    );
    for (var subscription in _activeGenerations.values) {
      subscription.cancel();
    }
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    _backgroundGenerations.clear();
    _backgroundCompletionCallbacks.clear();
    _generationService.dispose();
  }
}

class StudyRecommendation {
  final String? currentToStudy;
  final String? nextToGenerate;
  final List<String> availableChapters;
  final List<String> generatingChapters;
  final List<String> suggestedToGenerate;

  StudyRecommendation({
    this.currentToStudy,
    this.nextToGenerate,
    required this.availableChapters,
    required this.generatingChapters,
    required this.suggestedToGenerate,
  });

  factory StudyRecommendation.empty() {
    return StudyRecommendation(
      availableChapters: [],
      generatingChapters: [],
      suggestedToGenerate: [],
    );
  }

  bool get hasContentToStudy => availableChapters.isNotEmpty;
  bool get hasSuggestions =>
      nextToGenerate != null || suggestedToGenerate.isNotEmpty;
  bool get isGenerating => generatingChapters.isNotEmpty;
}

enum GenerationPhase { starting, generating, completed, failed, timeout }

class GenerationProgress {
  final GenerationPhase phase;
  final String message;
  final double progress; // 0.0 to 1.0
  final String? error;

  GenerationProgress({
    required this.phase,
    required this.message,
    required this.progress,
    this.error,
  });
}

class GenerationProgressDialog extends StatefulWidget {
  final String chapterName;
  final Stream<GenerationProgress> progressStream;
  final VoidCallback? onRunInBackground;
  final String courseId;
  final String chapterId;

  const GenerationProgressDialog({
    super.key,
    required this.chapterName,
    required this.progressStream,
    required this.courseId,
    required this.chapterId,
    this.onRunInBackground,
  });

  @override
  State<GenerationProgressDialog> createState() =>
      _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<GenerationProgressDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<GenerationProgress>(
          stream: widget.progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Preparing "${widget.chapterName}"',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Progress indicator
                if (progress?.phase != GenerationPhase.completed) ...[
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value:
                          progress?.phase == GenerationPhase.generating
                              ? progress?.progress
                              : null,
                      strokeWidth: 4,
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 60,
                    width: 60,
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
                ],

                const SizedBox(height: 16),

                // Status message
                Text(
                  progress?.message ?? 'Preparing...',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Time estimate
                if (progress?.phase == GenerationPhase.generating) ...[
                  Text(
                    'Usually takes 5-10 minutes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (progress?.phase == GenerationPhase.completed) ...[
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.school, size: 18),
                        label: const Text('Start Learning'),
                      ),
                    ] else if (progress?.phase == GenerationPhase.failed) ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Retry generation
                          Navigator.of(context).pop();
                        },
                        child: const Text('Retry'),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {
                          // Get the generation service from context or pass it through
                          // For now, we'll use a static approach
                          Navigator.of(context).pop();
                          widget.onRunInBackground?.call();
                        },
                        child: const Text('Run in Background'),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
