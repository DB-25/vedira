import 'dart:async';

import 'api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

enum ChapterGenerationStatus { running, completed, failed, timeout }

class ChapterGenerationResult {
  final ChapterGenerationStatus status;
  final String? error;

  ChapterGenerationResult({required this.status, this.error});
}

class ChapterGenerationService {
  final ApiService _apiService = ApiService();
  final String _tag = 'ChapterGenerationService';
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  StreamController<ChapterGenerationResult>? _statusController;

  // Start chapter generation and return a stream of status updates
  Stream<ChapterGenerationResult> generateChapter({
    required String courseId,
    required String chapterId,
  }) async* {
    _statusController = StreamController<ChapterGenerationResult>();

    try {
      Logger.i(
        _tag,
        'Starting chapter generation',
        data: {'courseId': courseId, 'chapterId': chapterId},
      );

      // Trigger chapter generation
      final response = await _apiService.generateChapter(
        courseId: courseId,
        chapterId: chapterId,
      );

      final executionArn = response['executionArn'] as String?;
      if (executionArn == null || executionArn.isEmpty) {
        throw Exception('No execution ARN received from chapter generation');
      }

      // Remove any extra quotes that might be wrapping the ARN
      final cleanExecutionArn = executionArn.replaceAll('"', '');
      if (cleanExecutionArn.isEmpty) {
        throw Exception('Invalid execution ARN received: $executionArn');
      }

      Logger.i(
        _tag,
        'Chapter generation triggered, starting polling',
        data: {'executionArn': cleanExecutionArn},
      );

      // Start polling for status
      _startPolling(cleanExecutionArn);

      // Set timeout
      _startTimeout();

      // Yield from the status stream
      yield* _statusController!.stream;
    } catch (e) {
      Logger.e(_tag, 'Error starting chapter generation', error: e);
      yield ChapterGenerationResult(
        status: ChapterGenerationStatus.failed,
        error: 'Failed to start chapter generation: ${e.toString()}',
      );
    }
  }

  void _startPolling(String executionArn) {
    _pollingTimer = Timer.periodic(AppConstants.chapterPollingInterval, (
      timer,
    ) async {
      try {
        Logger.d(_tag, 'Polling chapter generation status');

        final status = await _apiService.checkChapterGenerationStatus(
          executionArn: executionArn,
        );

        final isComplete = status['isComplete'] as bool? ?? false;
        final isFailed = status['isFailed'] as bool? ?? false;
        final statusString = status['status'] as String? ?? 'UNKNOWN';

        Logger.d(
          _tag,
          'Polling result',
          data: {
            'isComplete': isComplete,
            'isFailed': isFailed,
            'status': statusString,
          },
        );

        if (isComplete) {
          Logger.i(_tag, 'Chapter generation completed successfully');
          _statusController?.add(
            ChapterGenerationResult(status: ChapterGenerationStatus.completed),
          );
          _cleanup();
        } else if (isFailed) {
          Logger.w(_tag, 'Chapter generation failed');
          _statusController?.add(
            ChapterGenerationResult(
              status: ChapterGenerationStatus.failed,
              error: AppConstants.chapterGenerationFailedMessage,
            ),
          );
          _cleanup();
        }
        // If neither complete nor failed, continue polling
      } catch (e) {
        Logger.e(_tag, 'Error during status polling', error: e);
        _statusController?.add(
          ChapterGenerationResult(
            status: ChapterGenerationStatus.failed,
            error: 'Error checking status: ${e.toString()}',
          ),
        );
        _cleanup();
      }
    });
  }

  void _startTimeout() {
    _timeoutTimer = Timer(AppConstants.chapterGenerationTimeout, () {
      Logger.w(_tag, 'Chapter generation timed out');
      _statusController?.add(
        ChapterGenerationResult(
          status: ChapterGenerationStatus.timeout,
          error: AppConstants.errorChapterGenerationTimeout,
        ),
      );
      _cleanup();
    });
  }

  void _cleanup() {
    Logger.d(_tag, 'Cleaning up polling resources');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _statusController?.close();
    _statusController = null;
  }

  void cancel() {
    Logger.i(_tag, 'Chapter generation cancelled by user');
    _cleanup();
  }

  void dispose() {
    _cleanup();
    _apiService.dispose();
  }
}
