import 'dart:async';

import 'api_service.dart';
import '../models/chapter_status.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

enum ChapterGenerationStatus { running, completed, failed, timeout }

class ChapterGenerationResult {
  final ChapterGenerationStatus status;
  final String? error;
  final Map<String, ChapterStatus>? chaptersStatus;

  ChapterGenerationResult({
    required this.status,
    this.error,
    this.chaptersStatus,
  });
}

class ChapterGenerationService {
  static final ChapterGenerationService _instance =
      ChapterGenerationService._internal();
  factory ChapterGenerationService() => _instance;
  ChapterGenerationService._internal();

  final ApiService _apiService = ApiService();
  final String _tag = 'ChapterGenerationService';

  // Per-course polling management
  final Map<String, Timer> _coursePollingTimers = {}; // courseId -> Timer
  final Map<String, StreamController<ChapterGenerationResult>>
  _activeGenerations = {};
  final Map<String, String> _executionArns =
      {}; // courseId-chapterId -> executionArn
  final Map<String, DateTime> _startTimes = {};
  final Map<String, Set<String>> _courseActiveChapters =
      {}; // courseId -> Set<chapterId>

  // Start chapter generation and return a stream of status updates
  Stream<ChapterGenerationResult> generateChapter({
    required String courseId,
    required String chapterId,
  }) async* {
    final key = '$courseId-$chapterId';

    try {
      Logger.i(_tag, 'Starting chapter generation for: $key');

      // Cancel existing generation for this chapter
      _activeGenerations[key]?.close();
      _activeGenerations.remove(key);

      // Trigger chapter generation
      final response = await _apiService.generateChapter(
        courseId: courseId,
        chapterId: chapterId,
      );

      final executionArn = response['executionArn'] as String?;
      if (executionArn == null || executionArn.isEmpty) {
        throw Exception('No execution ARN received from chapter generation');
      }

      final cleanExecutionArn = executionArn.replaceAll('"', '');
      if (cleanExecutionArn.isEmpty) {
        throw Exception('Invalid execution ARN received: $executionArn');
      }

      // Store execution ARN and start time
      _executionArns[key] = cleanExecutionArn;
      _startTimes[key] = DateTime.now();

      // Track this chapter as active for this course
      _courseActiveChapters[courseId] ??= <String>{};
      _courseActiveChapters[courseId]!.add(chapterId);

      // Create new stream controller
      final controller = StreamController<ChapterGenerationResult>.broadcast();
      _activeGenerations[key] = controller;

      Logger.i(
        _tag,
        'Chapter generation triggered for $key, executionArn: $cleanExecutionArn',
      );

      // Start polling for this course if not already running
      _startCoursePolling(courseId);

      // Yield from the stream
      yield* controller.stream;
    } catch (e) {
      Logger.e(_tag, 'Error starting chapter generation for $key', error: e);
      yield ChapterGenerationResult(
        status: ChapterGenerationStatus.failed,
        error: 'Failed to start chapter generation: ${e.toString()}',
      );
    }
  }

  void _startCoursePolling(String courseId) {
    if (_coursePollingTimers.containsKey(courseId)) {
      Logger.d(_tag, 'Polling already active for course: $courseId');
      return;
    }

    Logger.i(_tag, 'Starting polling for course: $courseId');

    _coursePollingTimers[courseId] = Timer.periodic(
      AppConstants.chapterPollingInterval,
      (timer) async {
        final activeChapters = _courseActiveChapters[courseId];
        if (activeChapters == null || activeChapters.isEmpty) {
          Logger.i(
            _tag,
            'No active chapters for course $courseId, stopping polling',
          );
          _stopCoursePolling(courseId);
          return;
        }

        Logger.d(
          _tag,
          'Polling ${activeChapters.length} chapters for course: $courseId',
        );

        final completedChapters = <String>[];

        for (final chapterId in activeChapters.toList()) {
          final key = '$courseId-$chapterId';
          final controller = _activeGenerations[key];
          final executionArn = _executionArns[key];
          final startTime = _startTimes[key];

          if (executionArn == null ||
              controller == null ||
              controller.isClosed) {
            completedChapters.add(chapterId);
            continue;
          }

          // Check for timeout
          if (startTime != null &&
              DateTime.now().difference(startTime) >
                  AppConstants.chapterGenerationTimeout) {
            Logger.w(_tag, 'Generation timed out for: $key');
            if (!controller.isClosed) {
              controller.add(
                ChapterGenerationResult(
                  status: ChapterGenerationStatus.timeout,
                  error: AppConstants.errorChapterGenerationTimeout,
                ),
              );
            }
            completedChapters.add(chapterId);
            continue;
          }

          try {
            final statusResponse = await _apiService
                .checkChapterGenerationStatus(executionArn: executionArn);

            final isComplete = statusResponse['isComplete'] as bool? ?? false;
            final isFailed = statusResponse['isFailed'] as bool? ?? false;

            // Extract chapter generation status if available
            Map<String, ChapterStatus>? chaptersStatus;
            final chapterStatusData =
                statusResponse['chapter_generation_status']
                    as Map<String, dynamic>?;
            if (chapterStatusData != null) {
              chaptersStatus = {};
              chapterStatusData.forEach((statusKey, value) {
                if (value is Map<String, dynamic>) {
                  chaptersStatus![statusKey] = ChapterStatus.fromJson(value);
                }
              });
            }

            if (isComplete) {
              Logger.i(_tag, 'Generation completed for: $key');
              if (!controller.isClosed) {
                controller.add(
                  ChapterGenerationResult(
                    status: ChapterGenerationStatus.completed,
                    chaptersStatus: chaptersStatus,
                  ),
                );
              }
              completedChapters.add(chapterId);
            } else if (isFailed) {
              Logger.w(_tag, 'Generation failed for: $key');
              if (!controller.isClosed) {
                controller.add(
                  ChapterGenerationResult(
                    status: ChapterGenerationStatus.failed,
                    error: AppConstants.chapterGenerationFailedMessage,
                    chaptersStatus: chaptersStatus,
                  ),
                );
              }
              completedChapters.add(chapterId);
            } else {
              // Still running
              if (!controller.isClosed && chaptersStatus != null) {
                controller.add(
                  ChapterGenerationResult(
                    status: ChapterGenerationStatus.running,
                    chaptersStatus: chaptersStatus,
                  ),
                );
              }
            }
          } catch (e) {
            Logger.e(_tag, 'Error polling status for $key', error: e);
            if (!controller.isClosed) {
              controller.add(
                ChapterGenerationResult(
                  status: ChapterGenerationStatus.failed,
                  error: 'Error checking status: ${e.toString()}',
                ),
              );
            }
            completedChapters.add(chapterId);
          }
        }

        // Clean up completed chapters
        for (final chapterId in completedChapters) {
          _cleanupChapterGeneration(courseId, chapterId);
        }
      },
    );
  }

  void _stopCoursePolling(String courseId) {
    final timer = _coursePollingTimers[courseId];
    if (timer != null) {
      Logger.i(_tag, 'Stopping polling for course: $courseId');
      timer.cancel();
      _coursePollingTimers.remove(courseId);
    }
  }

  void _cleanupChapterGeneration(String courseId, String chapterId) {
    final key = '$courseId-$chapterId';
    Logger.d(_tag, 'Cleaning up generation: $key');

    _activeGenerations[key]?.close();
    _activeGenerations.remove(key);
    _executionArns.remove(key);
    _startTimes.remove(key);

    // Remove from course active chapters
    _courseActiveChapters[courseId]?.remove(chapterId);
    if (_courseActiveChapters[courseId]?.isEmpty == true) {
      _courseActiveChapters.remove(courseId);
    }
  }

  // Call this when user navigates away from a course details screen
  void stopCoursePolling(String courseId) {
    Logger.i(
      _tag,
      'User navigated away from course $courseId, stopping polling',
    );

    // Clean up all active generations for this course
    final activeChapters = _courseActiveChapters[courseId]?.toList() ?? [];
    for (final chapterId in activeChapters) {
      _cleanupChapterGeneration(courseId, chapterId);
    }

    _stopCoursePolling(courseId);
  }

  // Call this when user navigates to a course details screen with active generations
  void resumeCoursePolling(String courseId) {
    final activeChapters = _courseActiveChapters[courseId];
    if (activeChapters != null && activeChapters.isNotEmpty) {
      Logger.i(
        _tag,
        'User returned to course $courseId, resuming polling for ${activeChapters.length} chapters',
      );
      _startCoursePolling(courseId);
    }
  }

  void cancel() {
    Logger.i(_tag, 'Cancelling all chapter generations');
    final courseIds = _coursePollingTimers.keys.toList();
    for (final courseId in courseIds) {
      stopCoursePolling(courseId);
    }
  }

  void dispose() {
    Logger.i(_tag, 'Disposing ChapterGenerationService');
    cancel();
    _apiService.dispose();
  }

  // Check if any chapters need periodic polling (are in PENDING or GENERATING state)
  static bool shouldPollChapterStatus(
    Map<String, ChapterStatus> chaptersStatus,
  ) {
    return chaptersStatus.values.any(
      (status) =>
          status.lessonsStatus == 'PENDING' ||
          status.lessonsStatus == 'GENERATING' ||
          status.mcqsStatus == 'PENDING' ||
          status.mcqsStatus == 'GENERATING',
    );
  }

  // Get active generations count for debugging
  int getActiveGenerationsCount(String courseId) =>
      _courseActiveChapters[courseId]?.length ?? 0;
  bool isCoursePolling(String courseId) =>
      _coursePollingTimers.containsKey(courseId);
  List<String> get activeCourses => _coursePollingTimers.keys.toList();
}
