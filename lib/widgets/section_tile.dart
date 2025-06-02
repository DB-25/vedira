import 'package:flutter/material.dart';

import '../models/section.dart';
import '../models/chapter_status.dart';
import 'status_badge.dart';

class SectionTile extends StatelessWidget {
  final String? title;
  final int? lessonCount;
  final Section? section;
  final ChapterStatus? chapterStatus;

  const SectionTile({
    super.key,
    this.title,
    this.lessonCount,
    this.section,
    this.chapterStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = section?.title ?? title ?? 'Section Title';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    displayTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    softWrap: true,
                  ),
                ),
              ),
              if (chapterStatus != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      status: chapterStatus!.lessonsStatus,
                      label: 'Lessons',
                      fontSize: 11,
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      status: chapterStatus!.mcqsStatus,
                      label: 'MCQs',
                      fontSize: 11,
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (section?.description != null && section!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 5.0, right: 5.0),
              child: Text(
                section!.description,
                style: theme.textTheme.bodySmall,
                softWrap: true,
              ),
            ),
          if (chapterStatus != null && chapterStatus!.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 5.0),
              child: Text(
                'Last updated: ${_formatDate(chapterStatus!.lastUpdated)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
