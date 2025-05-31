import 'package:flutter/material.dart';
import '../models/course.dart';
import '../screens/course_details_screen.dart';
import '../utils/logger.dart';

class CourseCard extends StatelessWidget {
  final Course? course;
  final String _tag = 'CourseCard';

  const CourseCard({super.key, this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (course == null) {
      return const SizedBox.shrink();
    }

    // Debug log to check course ID
    if (course!.courseID.isEmpty) {
      Logger.e(_tag, 'Empty courseID detected in CourseCard: ${course!.title}');
    } else {
      Logger.d(_tag, 'CourseCard has valid courseID: ${course!.courseID}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course!.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(course!.description, style: theme.textTheme.bodyMedium),
            // const SizedBox(height: 16),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text('By ${course!.author}', style: theme.textTheme.bodyMedium),
            //     Text(
            //       '${course!.lessons?.length ?? 0} lessons',
            //       style: theme.textTheme.bodyMedium,
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Add debug log right before navigation
                Logger.i(
                  _tag,
                  'Navigating to course details with ID: ${course!.courseID}',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CourseDetailsScreen(courseId: course!.courseID),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.primary,
              ),
              child: const Text('View Course'),
            ),
          ],
        ),
      ),
    );
  }
}
