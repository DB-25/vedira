import 'package:flutter/material.dart';
import '../models/course.dart';
import '../screens/course_details_screen.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import '../utils/theme_manager.dart';
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
    final colorScheme = theme.colorScheme;

    if (widget.course == null) {
      return const SizedBox.shrink();
    }

    // Debug log to check course ID
    if (widget.course!.courseID.isEmpty) {
      Logger.e(_tag, 'Empty courseID detected in CourseCard: ${widget.course!.title}');
    }

    // Use consistent card color from theme manager
    final cardColor = colorScheme.cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
          
          // Star button overlay (top-right) - Follows UI conventions
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: _isStarred 
                    ? colorScheme.tertiary.withOpacity(0.95)
                    : colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isStarred 
                      ? colorScheme.tertiary.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isStarLoading ? null : _toggleStar,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _isStarLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.paletteAction, // Use action color for stars
                              ),
                            ),
                          )
                        : Icon(
                            _isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppConstants.paletteAction, // Use action color for stars
                            size: 16,
                          ),
                  ),
                ),
              ),
            ),
          ),
          
          // Delete button overlay (top-left) - Classic placement
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleDelete(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                      size: 16,
                    ),
                  ),
                ),
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

    // Confirmation dialog with modern design
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        // Create solid background for better readability
        final dialogColor = theme.brightness == Brightness.light
            ? colorScheme.surface
            : colorScheme.surface;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: dialogColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with modern styling
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 32,
                    color: colorScheme.error,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Delete Course',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                                 // Main message
                 Text(
                   'Are you sure you want to delete "${widget.course!.title}"?',
                   style: theme.textTheme.bodyLarge?.copyWith(
                     color: colorScheme.onSurface,
                     height: 1.4,
                   ),
                   textAlign: TextAlign.center,
                 ),
                
                const SizedBox(height: 16),
                
                                 // Warning message with modern styling
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: theme.brightness == Brightness.light
                         ? colorScheme.errorContainer.withOpacity(0.15)
                         : colorScheme.errorContainer.withOpacity(0.25),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(
                       color: theme.brightness == Brightness.light
                           ? colorScheme.error.withOpacity(0.3)
                           : colorScheme.error.withOpacity(0.5),
                       width: 1,
                     ),
                   ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                                                 child: Text(
                           'This action cannot be undone. All course content, lessons, and progress will be permanently deleted.',
                           style: theme.textTheme.bodyMedium?.copyWith(
                             color: theme.brightness == Brightness.light
                                 ? colorScheme.error
                                 : colorScheme.onErrorContainer,
                             fontWeight: FontWeight.w500,
                             height: 1.4,
                           ),
                         ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons with modern styling
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                                         Expanded(
                       child: ElevatedButton(
                         onPressed: () => Navigator.pop(context, true),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: colorScheme.error,
                           foregroundColor: Colors.white, // Force white text for accessibility
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           elevation: 0,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                         child: Text(
                           'Delete',
                           style: theme.textTheme.labelLarge?.copyWith(
                             fontWeight: FontWeight.bold, // Make it bold
                             color: Colors.white, // Ensure white color
                           ),
                         ),
                       ),
                     ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading dialog with modern design
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          
          // Create solid background for better readability
          final dialogColor = colorScheme.surface;

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                color: dialogColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Deleting course...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                color: theme.brightness == Brightness.light
                    ? theme.colorScheme.primary.withOpacity(0.8)
                    : theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hasError ? 'Image unavailable' : widget.course!.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? theme.colorScheme.primary.withOpacity(0.9)
                      : theme.colorScheme.onPrimaryContainer,
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
