import 'package:flutter/material.dart';
import '../screens/course_details_screen.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../components/custom_app_bar.dart';

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

    // Use the body background from theme manager
    final bodyBackgroundColor = colorScheme.bodyBackground;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Create Your Course',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Let\'s Create Your Perfect Course!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us what you want to learn, and our AI will craft a personalized learning journey just for you.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // What do you want to learn?
                  _buildSectionHeader(
                    icon: Icons.lightbulb_outline,
                    title: 'What do you want to learn?',
                    subtitle: 'Choose any topic that interests you',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  // Topic suggestions
                  _buildTopicSuggestions(colorScheme, theme),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: 'Your Learning Topic',
                      hintText: 'Type anything you\'re curious about...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please tell us what you want to learn';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // How much time do you have?
                  _buildSectionHeader(
                    icon: Icons.schedule,
                    title: 'How much time do you have?',
                    subtitle:
                        'We\'ll break it down into manageable daily lessons',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  // Timeline suggestions
                  _buildTimelineSuggestions(colorScheme, theme),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _timelineController,
                    decoration: InputDecoration(
                      labelText: 'Your Learning Timeline',
                      hintText: 'e.g., "2 weeks", "1 month", "3 months"',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please let us know your timeline';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // What's your experience level?
                  _buildSectionHeader(
                    icon: Icons.trending_up,
                    title: 'What\'s your experience level?',
                    subtitle: 'This helps us adjust the content difficulty',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  _buildDifficultySelector(colorScheme, theme),
                  const SizedBox(height: 32),

                  // Any special requirements?
                  _buildSectionHeader(
                    icon: Icons.tune,
                    title: 'Any special requirements?',
                    subtitle:
                        'Optional: Tell us about your specific needs or preferences',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _customInstructionsController,
                    decoration: InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      hintText:
                          'e.g., "Focus on practical examples", "Include coding exercises", "Beginner-friendly explanations"',
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    maxLines: 3,
                    enabled: !_isLoading,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),

                  // Generate button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ready to start your learning journey?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateCoursePlan,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(
                              'Generate My Course',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  color: colorScheme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Creating Your Course ✨',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our AI is crafting personalized lessons just for you. This usually takes 1-2 minutes.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Time elapsed: $_elapsedTime',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () {
                            Logger.i(
                              _tag,
                              'Course generation cancelled by user at elapsed time: $_elapsedTime',
                            );
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicSuggestions(ColorScheme colorScheme, ThemeData theme) {
    final suggestions = [
      'Python Programming',
      'Digital Marketing',
      'Photography',
      'Web Development',
      'Data Science',
      'UI/UX Design',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        _topicController.text = suggestion;
                      },
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTimelineSuggestions(ColorScheme colorScheme, ThemeData theme) {
    final suggestions = ['1 week', '2 weeks', '1 month', '3 months'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        _timelineController.text = suggestion;
                      },
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDifficultySelector(ColorScheme colorScheme, ThemeData theme) {
    final difficulties = [
      {
        'value': 'easy',
        'title': 'Beginner',
        'description': 'New to this topic',
        'icon': Icons.school,
      },
      {
        'value': 'medium',
        'title': 'Intermediate',
        'description': 'Some experience',
        'icon': Icons.trending_up,
      },
      {
        'value': 'hard',
        'title': 'Advanced',
        'description': 'Ready for a challenge',
        'icon': Icons.star,
      },
    ];

    return Column(
      children:
          difficulties.map((diff) {
            final isSelected = _difficulty == diff['value'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _difficulty = diff['value'] as String;
                          });
                        },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? colorScheme.primary.withOpacity(0.1)
                            : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diff['icon'] as IconData,
                        color:
                            isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diff['title'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              diff['description'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
