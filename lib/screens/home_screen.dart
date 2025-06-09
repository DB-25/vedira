import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../screens/create_course_screen.dart';
import '../screens/login_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme_manager.dart';
import '../utils/logger.dart';
import '../widgets/course_card.dart';

class HomeScreen extends StatefulWidget {
  final Future<List<Course>>? preloadedCourses;

  const HomeScreen({super.key, this.preloadedCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService.instance;
  late Future<List<Course>> _coursesFuture;
  bool _isLoading = false;
  final String _tag = 'HomeScreen';

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Screen initialized');

    if (widget.preloadedCourses != null) {
      Logger.i(_tag, 'Using preloaded courses from splash screen');
      _coursesFuture = widget.preloadedCourses!;
    } else {
      Logger.i(_tag, 'No preloaded courses, loading course list');
      _loadCourses();
    }
  }

  @override
  void dispose() {
    Logger.i(_tag, 'Screen disposed');
    super.dispose();
  }

  Future<void> _loadCourses() async {
    Logger.i(_tag, 'Loading course list');
    setState(() {
      _coursesFuture = _apiService.getCourseList();
    });
  }

  Future<void> _refreshCourses() async {
    Logger.i(_tag, 'Refreshing course list');
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadCourses();
      Logger.i(_tag, 'Course list refreshed successfully');
    } catch (e) {
      Logger.e(
        _tag,
        'Error refreshing courses',
        error: e,
        stackTrace: StackTrace.current,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    Logger.i(_tag, 'User requested logout');

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await _authService.logout();
        Logger.i(_tag, 'User logged out successfully');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        Logger.e(_tag, 'Error during logout', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error during logout. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Buddy'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () async {
              final newMode = !isDarkMode ? 'dark' : 'light';
              Logger.i(_tag, 'User requested theme change to $newMode mode');
              await themeManager.toggleTheme();
            },
            tooltip:
                isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined),
                        SizedBox(width: 8),
                        Text('Privacy Policy'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _isLoading) {
              Logger.d(_tag, 'Loading courses...');
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              final error = snapshot.error;
              Logger.e(
                _tag,
                'Error loading courses',
                error: error,
                stackTrace: StackTrace.current,
              );
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading courses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Logger.i(
                          _tag,
                          'User trying to reload courses after error',
                        );
                        _refreshCourses();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              Logger.w(_tag, 'No courses available');
              return _buildOnboardingExperience();
            }

            final courses = snapshot.data!;
            Logger.i(_tag, 'Loaded ${courses.length} courses');
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                Logger.v(_tag, 'Rendering course: ${course.title}');
                return CourseCard(course: course);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Logger.i(_tag, 'User navigating to create course screen');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOnboardingExperience() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Welcome header
          Icon(Icons.school_rounded, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),

          Text(
            'Welcome to Lesson Buddy!',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Your AI-powered learning companion',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Value proposition cards
          _buildFeatureCard(
            icon: Icons.auto_awesome,
            title: 'AI-Generated Courses',
            description:
                'Simply tell us what you want to learn, and we\'ll create a personalized course with structured lessons, quizzes, and reading materials tailored just for you.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 20),

          _buildFeatureCard(
            icon: Icons.timeline,
            title: 'Your Learning Timeline',
            description:
                'Set your own pace! Whether you have 1 week or 3 months, we\'ll break down complex topics into manageable daily lessons that fit your schedule.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 20),

          _buildFeatureCard(
            icon: Icons.quiz,
            title: 'Test Your Knowledge',
            description:
                'Reinforce what you\'ve learned with interactive quizzes after each lesson. Track your progress and identify areas that need more attention.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 20),

          _buildFeatureCard(
            icon: Icons.trending_up,
            title: 'Track Your Progress',
            description:
                'Watch your knowledge grow! Monitor completion rates, quiz scores, and learning streaks to stay motivated on your educational journey.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 40),

          // Call to action
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
                Icon(Icons.rocket_launch, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Ready to start learning?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your first course in under 2 minutes. Just tell us what you want to learn, and we\'ll handle the rest!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Logger.i(
                        _tag,
                        'User starting first course creation from onboarding',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateCourseScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Create My First Course',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
