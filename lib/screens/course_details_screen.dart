import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/section.dart';
import '../services/api_service.dart';
import '../widgets/section_tile.dart';
import '../widgets/lesson_tile.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  CourseDetailsScreen({super.key, required this.courseId}) {
    // Validate courseId is not empty
    assert(
      courseId.isNotEmpty,
      'CourseDetailsScreen: courseId cannot be empty',
    );
  }

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Course> _courseFuture;
  bool _isRefreshing = false;
  final String _tag = 'CourseDetailsScreen';

  @override
  void initState() {
    super.initState();
    // Added additional validation and logging for courseId
    if (widget.courseId.isEmpty) {
      Logger.e(_tag, 'Empty courseId provided to CourseDetailsScreen');
    }
    Logger.i(_tag, 'Screen initialized for course ID: "${widget.courseId}"');
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    // Ensure we have a non-empty courseId
    final courseId =
        widget.courseId.isEmpty
            ? 'cbbd5c0f-e4c9-42ee-81e0-7af5543292f3' // Use a sample ID if courseId is empty
            : widget.courseId;

    if (widget.courseId.isEmpty) {
      Logger.w(
        _tag,
        'Empty courseId provided, using sample ID instead: $courseId',
      );
    }

    Logger.i(_tag, 'Loading course details for ID: $courseId');
    setState(() {
      // Use the course endpoint which now directly calls the lesson plan API
      _courseFuture = _apiService.getCourse(
        courseId,
        userId: AppConstants.defaultUserId,
      );
    });
  }

  Future<void> _handleRefresh() async {
    Logger.i(_tag, 'Refreshing course details for ID: ${widget.courseId}');
    setState(() {
      _isRefreshing = true;
    });
    await _loadCourse();
    setState(() {
      _isRefreshing = false;
    });
    Logger.i(_tag, 'Course refresh completed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: 'Refresh course content',
          ),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: FutureBuilder<Course>(
            future: _courseFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Logger.d(_tag, 'Course details loading');
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                final error = snapshot.error;
                Logger.e(
                  _tag,
                  'Error loading course details',
                  error: error,
                  stackTrace: StackTrace.current,
                );
                return _buildErrorView(context, error, theme);
              } else if (!snapshot.hasData) {
                Logger.w(
                  _tag,
                  'No course data found for ID: ${widget.courseId}',
                );
                return const Center(child: Text('Course not found'));
              }

              final course = snapshot.data!;
              Logger.i(
                _tag,
                'Course details loaded successfully',
                data: {
                  'id': course.courseID,
                  'title': course.title,
                  'sections': course.sections?.length ?? 0,
                  'lessons': course.lessons?.length ?? 0,
                },
              );
              return _buildCourseView(context, course, theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Object? error, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading course details',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Logger.i(_tag, 'User trying to reload course after error');
                  setState(() {
                    _loadCourse();
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseView(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    Widget sectionsContent;

    if (course.sections != null && course.sections!.isNotEmpty) {
      Logger.d(_tag, 'Rendering ${course.sections!.length} sections');
      sectionsContent = _buildSectionsList(context, course.sections!, theme);
    } else if (course.lessons != null && course.lessons!.isNotEmpty) {
      Logger.d(
        _tag,
        'Rendering legacy view with ${course.lessons!.length} lessons',
      );
      sectionsContent = _buildLegacySectionView(context, course, theme);
    } else {
      Logger.w(_tag, 'Course has no content: ${course.courseID}');
      sectionsContent = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            'No content available for this course',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCourseHeader(context, course, theme),
        const SizedBox(height: 16),
        Text(
          'Sections',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        sectionsContent,
      ],
    );
  }

  Widget _buildCourseHeader(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (course.author.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'By ${course.author}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(course.description, style: theme.textTheme.bodyMedium),
            if (course.createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(course.createdAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSectionsList(
    BuildContext context,
    List<Section> sections,
    ThemeData theme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        Logger.v(
          _tag,
          'Rendering section: ${section.title} with ${section.lessons.length} lessons',
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTile(section: section),
              const Divider(),
              if (section.lessons.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No lessons in this section')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section.lessons.length,
                  itemBuilder: (context, lessonIndex) {
                    return LessonTile(
                      lesson: section.lessons[lessonIndex],
                      courseId: widget.courseId,
                      onRefreshNeeded: _handleRefresh,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegacySectionView(
    BuildContext context,
    Course course,
    ThemeData theme,
  ) {
    // Fallback for courses with only lessons (no sections)
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTile(
            title: 'Main Section',
            lessonCount: course.lessons!.length,
          ),
          const Divider(),
          if (course.lessons!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No lessons in this section')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: course.lessons!.length,
              itemBuilder: (context, lessonIndex) {
                return LessonTile(
                  lesson: course.lessons![lessonIndex],
                  courseId: widget.courseId,
                  onRefreshNeeded: _handleRefresh,
                );
              },
            ),
        ],
      ),
    );
  }
}
