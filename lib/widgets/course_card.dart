import 'package:flutter/material.dart';
import '../models/course.dart';
import '../screens/course_details_screen.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'authenticated_image.dart';

class CourseCard extends StatelessWidget {
  final Course? course;
  final String _tag = 'CourseCard';

  const CourseCard({super.key, this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (course == null) {
      return const SizedBox.shrink();
    }

    // Debug log to check course ID
    if (course!.courseID.isEmpty) {
      Logger.e(_tag, 'Empty courseID detected in CourseCard: ${course!.title}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CourseDetailsScreen(courseId: course!.courseID),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Cover Image Section (more prominent)
            _buildCoverImage(theme),

            // Content Section (reduced text density)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Title (smaller)
                  Text(
                    course!.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Course Description (more compact)
                  Text(
                    course!.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Compact meta info row
                  Row(
                    children: [
                      // Content count badge
                      if (course!.sections?.isNotEmpty == true ||
                          course!.lessons?.isNotEmpty == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getContentCountText(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Tap indicator
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(ThemeData theme) {
    const double imageHeight = 180;

    if (course!.coverImageUrl != null && course!.coverImageUrl!.isNotEmpty) {
      final imageUrl = AppConstants.getImageUrl(course!.coverImageUrl!);

      if (imageUrl.isNotEmpty) {
        return SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: AuthenticatedImage(
            imageUrl: imageUrl,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: _buildImagePlaceholder(theme, isLoading: true),
            errorWidget: _buildImagePlaceholder(theme, hasError: true),
            onImageLoaded: () {},
            onImageError: (error) {
              Logger.e(
                _tag,
                'Failed to load course image: ${course!.title} - $error',
              );
            },
          ),
        );
      }
    }

    return _buildImagePlaceholder(theme);
  }

  Widget _buildImagePlaceholder(
    ThemeData theme, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    const double imageHeight = 180;

    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.15),
            theme.colorScheme.tertiary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError ? Icons.broken_image_outlined : Icons.auto_stories,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hasError ? 'Image unavailable' : course!.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getContentCountText() {
    if (course!.sections?.isNotEmpty == true) {
      final chapterCount = course!.sections!.length;
      final lessonCount = course!.sections!.fold<int>(
        0,
        (sum, section) => sum + section.lessons.length,
      );

      if (chapterCount == 1) {
        return '$lessonCount lessons';
      } else {
        return '$chapterCount chapters';
      }
    } else if (course!.lessons?.isNotEmpty == true) {
      final lessonCount = course!.lessons!.length;
      return '$lessonCount lessons';
    }

    return 'New course';
  }
}
