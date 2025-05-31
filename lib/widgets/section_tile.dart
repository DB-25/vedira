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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              softWrap: true,
              //overflow: TextOverflow.ellipsis,
            ),
          ),
          if (section?.description != null && section!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                section!.description,
                style: theme.textTheme.bodySmall,
                softWrap: true,
                //maxLines: 2,
                //overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
