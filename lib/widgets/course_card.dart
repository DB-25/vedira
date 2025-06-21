import 'package:flutter/material.dart';
import '../models/course.dart';
import '../screens/course_details_screen.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'authenticated_image.dart';

class CourseCard extends StatefulWidget {
  final Course? course;
  final bool? isStarred; // External star state for smooth animations
  final VoidCallback? onDeleted;
  final Function(bool)? onStarToggle; // Callback with new star state

  const CourseCard({
    super.key, 
    this.course, 
    this.isStarred,
    this.onDeleted, 
    this.onStarToggle,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  final String _tag = 'CourseCard';
  bool _isStarLoading = false;

  // Always use external star state - no internal state management
  bool get _isStarred => widget.isStarred ?? false;

  Future<void> _toggleStar() async {
    if (widget.course?.courseID.isEmpty ?? true) return;
    
    setState(() {
      _isStarLoading = true;
    });

    try {
      // Calculate new star state and notify parent immediately
      final newStarState = !_isStarred;
      
      // Notify parent with the new star state - parent handles everything
      widget.onStarToggle?.call(newStarState);
      
    } catch (e) {
      Logger.e(_tag, 'Error toggling star', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating star status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.course == null) {
      return const SizedBox.shrink();
    }

    // Debug log to check course ID
    if (widget.course!.courseID.isEmpty) {
      Logger.e(_tag, 'Empty courseID detected in CourseCard: ${widget.course!.title}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CourseDetailsScreen(courseId: widget.course!.courseID),
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
                        widget.course!.title,
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
                        widget.course!.description,
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
                          if (widget.course!.sections?.isNotEmpty == true ||
                              widget.course!.lessons?.isNotEmpty == true) ...[
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
          
          // Star button overlay (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isStarLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        color: _isStarred ? Colors.orange : Colors.white,
                        size: 20,
                      ),
                onPressed: _isStarLoading ? null : _toggleStar,
                tooltip: _isStarred ? 'Unstar Course' : 'Star Course',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          
          // Delete button overlay (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _handleDelete(context),
                tooltip: 'Delete Course',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    if (widget.course?.courseID.isEmpty ?? true) {
      Logger.e(_tag, 'Cannot delete course with empty ID');
      return;
    }

    // Confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Course'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${widget.course!.title}"?'),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. All course content, lessons, and progress will be permanently deleted.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting course...'),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final apiService = ApiService();
      final success = await apiService.deleteCourse(widget.course!.courseID);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (success) {
          Logger.i(_tag, 'Course deleted successfully: ${widget.course!.title}');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course "${widget.course!.title}" deleted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Notify parent widget to refresh the list
          widget.onDeleted?.call();
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error deleting course: ${widget.course!.title}', error: e);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _handleDelete(context),
            ),
          ),
        );
      }
    }
  }

  Widget _buildCoverImage(ThemeData theme) {
    const double imageHeight = 180;

    if (widget.course!.coverImageUrl != null && widget.course!.coverImageUrl!.isNotEmpty) {
      final imageUrl = AppConstants.getImageUrl(widget.course!.coverImageUrl!);

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
                'Failed to load course image: ${widget.course!.title} - $error',
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
                hasError ? 'Image unavailable' : widget.course!.title,
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
    if (widget.course!.sections?.isNotEmpty == true) {
      final chapterCount = widget.course!.sections!.length;
      final lessonCount = widget.course!.sections!.fold<int>(
        0,
        (sum, section) => sum + section.lessons.length,
      );

      if (chapterCount == 1) {
        return '$lessonCount lessons';
      } else {
        return '$chapterCount chapters';
      }
    } else if (widget.course!.lessons?.isNotEmpty == true) {
      final lessonCount = widget.course!.lessons!.length;
      return '$lessonCount lessons';
    }

    return 'New course';
  }
}
