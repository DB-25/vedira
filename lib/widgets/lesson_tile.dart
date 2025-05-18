import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonTile extends StatelessWidget {
  final Lesson? lesson;

  const LessonTile({super.key, this.lesson});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(lesson?.title ?? 'Lesson Title'),
      leading: const Icon(Icons.book),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        // Navigate to lesson screen
      },
    );
  }
}
