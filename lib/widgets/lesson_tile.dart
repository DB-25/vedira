import 'package:flutter/material.dart';
import 'dart:async';

import '../models/lesson.dart';
import '../models/section.dart';
import '../models/chapter_status.dart';
import '../screens/lesson_view_screen.dart';
import '../screens/mcq_quiz_screen.dart';
import '../services/chapter_generation_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class LessonTile extends StatefulWidget {
  final Lesson? lesson;
  final VoidCallback? onTap;
  final String? courseId;
  final VoidCallback? onRefreshNeeded;
  final ChapterStatus? chapterStatus;

  const LessonTile({
    super.key,
    this.lesson,
    this.onTap,
    this.courseId,
    this.onRefreshNeeded,
    this.chapterStatus,
  });

  @override
  State<LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<LessonTile> {
  final ChapterGenerationService _chapterGenerationService =
      ChapterGenerationService();
  bool _isGenerating = false;
  StreamSubscription<ChapterGenerationResult>? _generationSubscription;
  final String _tag = 'LessonTile';

  @override
  void dispose() {
    _generationSubscription?.cancel();
    _chapterGenerationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = widget.lesson;

    if (lesson == null) {
      return const ListTile(
        title: Text('Unknown Lesson'),
        subtitle: Text('Lesson data is unavailable'),
      );
    }

    // Determine if content is generated based on chapter status or lesson properties
    final isGenerated = widget.chapterStatus?.hasContent ?? lesson.generated;
    final isCompleted = lesson.completed;
    final hasMcqs = widget.chapterStatus?.hasMcqs ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                lesson.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color:
                      isGenerated
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ),
            if (_isGenerating)
              _buildStatusChip(
                icon: Icons.autorenew,
                label: 'Generating',
                backgroundColor: theme.colorScheme.primary.withAlpha(26),
                textColor: theme.colorScheme.primary,
                iconColor: theme.colorScheme.primary,
                isAnimated: true,
              ),
          ],
        ),
        subtitle:
            lesson.content.isNotEmpty
                ? Text(
                  lesson.content.length > 100
                      ? '${lesson.content.substring(0, 100)}...'
                      : lesson.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isGenerated
                            ? theme.colorScheme.onSurface.withAlpha(153)
                            : theme.colorScheme.onSurface.withAlpha(102),
                  ),
                )
                : Text(
                  'Tap to view lesson content',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(128),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        leading: CircleAvatar(
          backgroundColor:
              isGenerated
                  ? (isCompleted
                      ? Colors.green.withAlpha(51)
                      : theme.colorScheme.primary.withAlpha(51))
                  : Colors.orange.withAlpha(51),
          child: Icon(
            isGenerated
                ? (isCompleted ? Icons.check : Icons.book)
                : Icons.pending,
            color:
                isGenerated
                    ? (isCompleted ? Colors.green : theme.colorScheme.primary)
                    : Colors.orange,
            size: 20,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MCQ Quiz button - show if MCQs are available
            if (hasMcqs && isGenerated)
              IconButton(
                icon: const Icon(Icons.quiz),
                onPressed: _navigateToMcqQuiz,
                tooltip: 'Take Quiz',
                color: theme.colorScheme.secondary,
              ),
            // Generate content button - show if content is not generated and not currently generating
            if (!isGenerated && !_isGenerating)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateChapterContent,
                tooltip: 'Generate content',
              ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  isGenerated
                      ? theme.colorScheme.onSurface.withAlpha(153)
                      : theme.colorScheme.onSurface.withAlpha(77),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        enabled: isGenerated,
        onTap:
            isGenerated
                ? (widget.onTap ??
                    () => _navigateToLessonView(context, widget.lesson))
                : _promptGenerateContent,
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    bool isAnimated = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isAnimated
              ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159, // Full rotation
                    child: Icon(icon, size: 12, color: iconColor),
                  );
                },
                onEnd: () {
                  // Restart animation if still generating
                  if (mounted && _isGenerating) {
                    setState(() {});
                  }
                },
              )
              : Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateChapterContent() async {
    if (widget.lesson == null || widget.courseId == null) return;

    final chapterId = _extractChapterId(widget.lesson!.sectionId);
    if (chapterId.isEmpty) return;

    // Cancel any existing generation
    _generationSubscription?.cancel();

    setState(() {
      _isGenerating = true;
    });

    try {
      // Show initial loading snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.generatingChapterMessage),
          duration: const Duration(seconds: 3),
        ),
      );

      // Start chapter generation with polling
      final generationStream = _chapterGenerationService.generateChapter(
        courseId: widget.courseId!,
        chapterId: chapterId,
      );

      _generationSubscription = generationStream.listen(
        (result) {
          if (!mounted) return;

          switch (result.status) {
            case ChapterGenerationStatus.completed:
              Logger.i(_tag, 'Chapter generation completed successfully');
              setState(() {
                _isGenerating = false;
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppConstants.chapterGeneratedSuccessMessage),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Notify parent to refresh
              if (widget.onRefreshNeeded != null) {
                widget.onRefreshNeeded!();
              }
              break;

            case ChapterGenerationStatus.failed:
              Logger.e(_tag, 'Chapter generation failed: ${result.error}');
              setState(() {
                _isGenerating = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.error ?? AppConstants.chapterGenerationFailedMessage,
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
              break;

            case ChapterGenerationStatus.timeout:
              Logger.w(_tag, 'Chapter generation timed out');
              setState(() {
                _isGenerating = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppConstants.errorChapterGenerationTimeout),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
              break;

            case ChapterGenerationStatus.running:
              // Keep showing generating state
              break;
          }
        },
        onError: (error) {
          Logger.e(_tag, 'Error in chapter generation stream', error: error);
          if (!mounted) return;

          setState(() {
            _isGenerating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate content: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    } catch (e) {
      Logger.e(_tag, 'Error starting chapter generation', error: e);
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start generation: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _promptGenerateContent() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Content Not Generated'),
            content: const Text(
              'This lesson content hasn\'t been generated yet. Would you like to generate it now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generateChapterContent();

                  // Alternative: Use progress dialog for better UX
                  // showDialog(
                  //   context: context,
                  //   barrierDismissible: false,
                  //   builder: (context) => ChapterGenerationProgressDialog(
                  //     courseId: widget.courseId!,
                  //     chapterId: _extractChapterId(widget.lesson!.sectionId),
                  //     chapterTitle: widget.lesson!.title,
                  //     onCompleted: widget.onRefreshNeeded,
                  //     onFailed: () {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text('Chapter generation failed'),
                  //           backgroundColor: Colors.red,
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // );
                },
                child: const Text('Generate'),
              ),
            ],
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

  void _navigateToLessonView(BuildContext context, Lesson? lesson) {
    if (lesson == null || widget.courseId == null) {
      _showLessonDetails(context, lesson);
      return;
    }

    final chapterId = _extractChapterId(lesson.sectionId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LessonViewScreen(
              courseId: widget.courseId!,
              chapterId: chapterId,
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              lesson: lesson,
            ),
      ),
    );
  }

  void _showLessonDetails(BuildContext context, Lesson? lesson) {
    if (lesson == null) return;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
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
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          lesson.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(lesson.content, style: theme.textTheme.bodyMedium),
                        if (lesson.resources.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Resources', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...lesson.resources.map(
                            (resource) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      resource,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _navigateToMcqQuiz() async {
    if (widget.lesson == null || widget.courseId == null) return;

    final chapterId = _extractChapterId(widget.lesson!.sectionId);

    // Try to fetch section information to enable next lesson navigation
    Section? section;
    int? currentLessonIndex;
    
    try {
      final apiService = ApiService();
      final course = await apiService.getCourse(widget.courseId!);
      
      // Find the section that contains this lesson
      if (course.sections != null) {
        for (final s in course.sections!) {
          final lessonIndex = s.lessons.indexWhere((l) => l.id == widget.lesson!.id);
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
              courseId: widget.courseId!,
              chapterId: chapterId,
              lessonId: widget.lesson!.id,
              lessonTitle: widget.lesson!.title,
              section: section,
              currentLessonIndex: currentLessonIndex,
            ),
      ),
    );
  }
}
