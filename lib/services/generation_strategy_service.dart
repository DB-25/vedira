import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chapter_generation_service.dart';
import '../services/progress_service.dart';
import '../models/chapter_status.dart';
import '../models/user_progress.dart';
import '../utils/logger.dart';

class GenerationStrategyService {
  final ChapterGenerationService _generationService =
      ChapterGenerationService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'GenerationStrategyService';

  // Active generation streams
  final Map<String, StreamSubscription> _activeGenerations = {};
  final Map<String, StreamController<GenerationProgress>> _progressControllers =
      {};

  // Suggested chapters to generate
  final Set<String> _suggestedChapters = {};

  // Cleanup
  void dispose() {
    for (var subscription in _activeGenerations.values) {
      subscription.cancel();
    }
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    _generationService.dispose();
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
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('📚 Smart Study Suggestion'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'While you $currentActivity, would you like me to prepare "$chapterName" for you?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This takes 5-10 minutes, perfect timing!',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Not now'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Yes, prepare it!'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // Show generation progress dialog
  void showGenerationProgress({
    required BuildContext context,
    required String chapterName,
    required Stream<GenerationProgress> progressStream,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => GenerationProgressDialog(
            chapterName: chapterName,
            progressStream: progressStream,
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
      controller.add(
        GenerationProgress(
          phase: GenerationPhase.starting,
          message: 'Starting content generation...',
          progress: 0.0,
        ),
      );

      // Start the actual generation
      final generationStream = _generationService.generateChapter(
        courseId: courseId,
        chapterId: chapterId,
      );

      final subscription = generationStream.listen(
        (result) {
          switch (result.status) {
            case ChapterGenerationStatus.completed:
              controller.add(
                GenerationProgress(
                  phase: GenerationPhase.completed,
                  message: 'Content ready! 🎉',
                  progress: 1.0,
                ),
              );
              _cleanup(key);
              break;

            case ChapterGenerationStatus.running:
              controller.add(
                GenerationProgress(
                  phase: GenerationPhase.generating,
                  message: _getProgressMessage(result),
                  progress: _estimateProgress(result),
                ),
              );
              break;

            case ChapterGenerationStatus.failed:
              controller.add(
                GenerationProgress(
                  phase: GenerationPhase.failed,
                  message: 'Generation failed. Please try again.',
                  progress: 0.0,
                  error: result.error,
                ),
              );
              _cleanup(key);
              break;

            case ChapterGenerationStatus.timeout:
              controller.add(
                GenerationProgress(
                  phase: GenerationPhase.timeout,
                  message: 'Generation is taking longer than expected.',
                  progress: 0.5,
                ),
              );
              break;
          }
        },
        onError: (error) {
          controller.add(
            GenerationProgress(
              phase: GenerationPhase.failed,
              message: 'An error occurred during generation.',
              progress: 0.0,
              error: error.toString(),
            ),
          );
          _cleanup(key);
        },
      );

      _activeGenerations[key] = subscription;
    } catch (e) {
      Logger.e(_tag, 'Error starting generation process', error: e);
      controller.add(
        GenerationProgress(
          phase: GenerationPhase.failed,
          message: 'Failed to start generation.',
          progress: 0.0,
          error: e.toString(),
        ),
      );
      _cleanup(key);
    }
  }

  void _cleanup(String key) {
    _activeGenerations[key]?.cancel();
    _activeGenerations.remove(key);

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

class GenerationProgressDialog extends StatelessWidget {
  final String chapterName;
  final Stream<GenerationProgress> progressStream;

  const GenerationProgressDialog({
    super.key,
    required this.chapterName,
    required this.progressStream,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<GenerationProgress>(
          stream: progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Preparing "$chapterName"',
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
                        onPressed: () => Navigator.of(context).pop(),
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
