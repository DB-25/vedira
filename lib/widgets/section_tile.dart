import 'package:flutter/material.dart';
import '../models/section.dart';

class SectionTile extends StatelessWidget {
  final String? title;
  final int? lessonCount;
  final Section? section;

  const SectionTile({super.key, this.title, this.lessonCount, this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = section?.title ?? title ?? 'Section Title';
    final displayCount = section?.lessons.length ?? lessonCount ?? 0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$displayCount ${displayCount == 1 ? 'Lesson' : 'Lessons'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          if (section?.description != null && section!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                section!.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
