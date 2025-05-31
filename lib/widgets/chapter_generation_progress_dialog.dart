import 'package:flutter/material.dart';
import 'dart:async';

import '../services/chapter_generation_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class ChapterGenerationProgressDialog extends StatefulWidget {
  final String courseId;
  final String chapterId;
  final String chapterTitle;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;
  final VoidCallback? onCancelled;

  const ChapterGenerationProgressDialog({
    super.key,
    required this.courseId,
    required this.chapterId,
    required this.chapterTitle,
    this.onCompleted,
    this.onFailed,
    this.onCancelled,
  });

  @override
  State<ChapterGenerationProgressDialog> createState() =>
      _ChapterGenerationProgressDialogState();
}

class _ChapterGenerationProgressDialogState
    extends State<ChapterGenerationProgressDialog> {
  final ChapterGenerationService _chapterGenerationService =
      ChapterGenerationService();
  final String _tag = 'ChapterGenerationProgressDialog';

  StreamSubscription<ChapterGenerationResult>? _generationSubscription;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  String _elapsedTime = "0:00";
  String _statusMessage = 'Starting generation...';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startGeneration();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _generationSubscription?.cancel();
    _elapsedTimer?.cancel();
    _chapterGenerationService.dispose();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        final minutes = _elapsedSeconds ~/ 60;
        final seconds = _elapsedSeconds % 60;
        _elapsedTime = "$minutes:${seconds.toString().padLeft(2, '0')}";
      });
    });
  }

  void _startGeneration() async {
    try {
      setState(() {
        _statusMessage = 'Initializing chapter generation...';
      });

      final generationStream = _chapterGenerationService.generateChapter(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
      );

      setState(() {
        _statusMessage = 'Generating chapter content...';
      });

      _generationSubscription = generationStream.listen(
        (result) {
          if (!mounted) return;

          switch (result.status) {
            case ChapterGenerationStatus.completed:
              Logger.i(_tag, 'Chapter generation completed successfully');
              setState(() {
                _statusMessage = 'Chapter generated successfully!';
                _isCompleted = true;
              });

              // Close dialog after a brief delay
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onCompleted?.call();
                }
              });
              break;

            case ChapterGenerationStatus.failed:
              Logger.e(_tag, 'Chapter generation failed: ${result.error}');
              setState(() {
                _statusMessage = result.error ?? 'Generation failed';
              });

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onFailed?.call();
                }
              });
              break;

            case ChapterGenerationStatus.timeout:
              Logger.w(_tag, 'Chapter generation timed out');
              setState(() {
                _statusMessage = 'Generation timed out';
              });

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onFailed?.call();
                }
              });
              break;

            case ChapterGenerationStatus.running:
              setState(() {
                _statusMessage = 'Processing chapter content...';
              });
              break;
          }
        },
        onError: (error) {
          Logger.e(_tag, 'Error in generation stream', error: error);
          if (!mounted) return;

          setState(() {
            _statusMessage = 'An error occurred during generation';
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
              widget.onFailed?.call();
            }
          });
        },
      );
    } catch (e) {
      Logger.e(_tag, 'Error starting generation', error: e);
      setState(() {
        _statusMessage = 'Failed to start generation';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onFailed?.call();
        }
      });
    }
  }

  void _cancelGeneration() {
    _chapterGenerationService.cancel();
    Navigator.of(context).pop();
    widget.onCancelled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _isCompleted,
      child: AlertDialog(
        title: Text('Generating Chapter', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chapterTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 50,
              height: 50,
              child:
                  _isCompleted
                      ? Icon(Icons.check_circle, size: 50, color: Colors.green)
                      : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.generatingChapterSubMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Elapsed time: $_elapsedTime',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ),
        actions:
            _isCompleted
                ? null
                : [
                  TextButton(
                    onPressed: _cancelGeneration,
                    child: const Text('Cancel'),
                  ),
                ],
      ),
    );
  }
}
