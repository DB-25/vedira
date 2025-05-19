import 'package:flutter/material.dart';
import '../screens/course_details_screen.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final String _tag = 'CreateCourseScreen';

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _timelineController = TextEditingController();
  final TextEditingController _customInstructionsController =
      TextEditingController();

  String _difficulty = 'medium'; // Default value
  bool _isLoading = false;
  String _elapsedTime = "0:00";
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Screen initialized');
  }

  @override
  void dispose() {
    _topicController.dispose();
    _timelineController.dispose();
    _customInstructionsController.dispose();
    Logger.i(_tag, 'Screen disposed');
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isLoading && mounted) {
        setState(() {
          _elapsedSeconds++;
          final minutes = _elapsedSeconds ~/ 60;
          final seconds = _elapsedSeconds % 60;
          _elapsedTime = "$minutes:${seconds.toString().padLeft(2, '0')}";
        });

        // Log every 30 seconds to track long-running processes
        if (_elapsedSeconds % 30 == 0) {
          Logger.i(
            _tag,
            'Course generation in progress - elapsed time: $_elapsedTime',
          );
        }

        _startTimer();
      }
    });
  }

  Future<void> _generateCoursePlan() async {
    if (!_formKey.currentState!.validate()) {
      Logger.w(_tag, 'Form validation failed');
      return;
    }

    final courseParams = {
      'topic': _topicController.text,
      'timeline': _timelineController.text,
      'difficulty': _difficulty,
      'custom_instructions': _customInstructionsController.text,
    };

    Logger.i(_tag, 'Starting course generation', data: courseParams);

    setState(() {
      _isLoading = true;
      _elapsedSeconds = 0;
      _elapsedTime = "0:00";
    });

    _startTimer();

    try {
      Logger.i(_tag, 'Sending course generation request');

      final course = await _apiService.generateCoursePlan(
        topic: _topicController.text,
        timeline: _timelineController.text,
        difficulty: _difficulty,
        customInstructions: _customInstructionsController.text,
      );

      Logger.i(
        _tag,
        'Course generation completed successfully',
        data: {
          'courseId': course.courseID,
          'title': course.title,
          'elapsed_time': _elapsedTime,
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to course details screen with the generated course
        Logger.i(
          _tag,
          'Navigating to course details screen for courseId: ${course.courseID}',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => CourseDetailsScreen(courseId: course.courseID),
          ),
        );
      }
    } catch (e) {
      Logger.e(
        _tag,
        'Course generation failed',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        final errorMessage = AppConstants.errorGeneratingCourse;
        Logger.i(_tag, 'Showing error message: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Generate a New Course Plan',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      hintText: 'e.g. Python, Flutter, Machine Learning',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a topic';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timelineController,
                    decoration: const InputDecoration(
                      labelText: 'Timeline',
                      hintText: 'e.g. 2 weeks, 3 months',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a timeline';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged:
                        _isLoading
                            ? null
                            : (value) {
                              if (value != null) {
                                setState(() {
                                  _difficulty = value;
                                });
                              }
                            },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Instructions (Optional)',
                      hintText: 'Any specific requirements or preferences',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateCoursePlan,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Generate Course Plan'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          AppConstants.generatingCourseMessage,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.generatingCourseSubMessage,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Elapsed time: $_elapsedTime',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Logger.i(
                              _tag,
                              'Course generation cancelled by user at elapsed time: $_elapsedTime',
                            );
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          child: Text(
                            AppConstants.generatingCourseCancelMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
