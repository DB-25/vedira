import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Title')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lesson Content',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is placeholder content for the lesson. It would typically contain text, images, videos, and other learning materials.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Resources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Resource 1'),
              onTap: () {
                // Handle resource tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Resource 2'),
              onTap: () {
                // Handle resource tap
              },
            ),
          ],
        ),
      ),
    );
  }
}
