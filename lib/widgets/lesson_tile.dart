import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonTile extends StatelessWidget {
  final Lesson? lesson;
  final VoidCallback? onTap;

  const LessonTile({super.key, this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surface,
      child: ListTile(
        title: Text(
          lesson?.title ?? 'Lesson Title',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle:
            lesson?.content != null && lesson!.content.isNotEmpty
                ? Text(
                  lesson!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                )
                : null,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.book, color: theme.colorScheme.primary, size: 20),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap:
            onTap ??
            () {
              _showLessonDetails(context, lesson);
            },
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
                                      style: TextStyle(
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
}
