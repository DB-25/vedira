import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../models/course.dart';
import '../screens/create_course_screen.dart';
import '../screens/login_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/starred_courses_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../widgets/course_card.dart';
import '../widgets/theme_selector.dart';

class HomeScreen extends StatefulWidget {
  final Future<List<Course>>? preloadedCourses;

  const HomeScreen({super.key, this.preloadedCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService.instance;
  final StarredCoursesService _starredService = StarredCoursesService.instance;
  late Future<List<Course>> _coursesFuture;
  bool _isLoading = false;
  final String _tag = 'HomeScreen';

  // Local state for smooth animations
  List<Course>? _currentCourses;
  Set<String> _starredCourseIds = {};

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Screen initialized');
    _loadStarredCourses();

    if (widget.preloadedCourses != null) {
      Logger.i(
          _tag, 'Using preloaded courses from splash screen, will sort them');
      _coursesFuture = _sortPreloadedCourses(widget.preloadedCourses!);
    } else {
      Logger.i(_tag, 'No preloaded courses, loading course list');
      _loadCourses();
    }
  }

  Future<void> _loadStarredCourses() async {
    try {
      final starredIds = await _starredService.getStarredCourses();
      setState(() {
        _starredCourseIds = starredIds;
      });
    } catch (e) {
      Logger.e(_tag, 'Error loading starred courses', error: e);
    }
  }

  Future<void> _handleStarToggle(String courseId, bool newStarState) async {
    if (_currentCourses == null) return;

    Logger.d(
        _tag, 'Handling star toggle for course $courseId to $newStarState');

    // Update starred state in storage
    try {
      if (newStarState) {
        await _starredService.starCourse(courseId);
      } else {
        await _starredService.unstarCourse(courseId);
      }
    } catch (e) {
      Logger.e(_tag, 'Error updating star state in storage', error: e);
    }

    // Update local starred state and re-sort the entire list
    setState(() {
      if (newStarState) {
        _starredCourseIds.add(courseId);
      } else {
        _starredCourseIds.remove(courseId);
      }

      // Re-sort the current courses list with updated star states
      _currentCourses!.sort((a, b) {
        final aIsStarred = _starredCourseIds.contains(a.courseID);
        final bIsStarred = _starredCourseIds.contains(b.courseID);

        if (aIsStarred && !bIsStarred) {
          return -1; // a comes first
        } else if (!aIsStarred && bIsStarred) {
          return 1; // b comes first
        } else {
          return 0; // maintain original order for courses with same star status
        }
      });
    });

    final starredCount = _starredCourseIds.length;
    final totalCourses = _currentCourses?.length ?? 0;
    Logger.d(_tag,
        'Updated star state for course $courseId to $newStarState and re-sorted list. Starred: $starredCount/$totalCourses courses');
  }

  @override
  void dispose() {
    Logger.i(_tag, 'Screen disposed');
    super.dispose();
  }

  Future<void> _loadCourses() async {
    Logger.i(_tag, 'Loading course list');
    setState(() {
      _coursesFuture = _loadAndSortCourses();
    });
  }

  Future<List<Course>> _loadAndSortCourses() async {
    try {
      // Load courses from API
      final courses = await _apiService.getCourseList();

      // Get starred course IDs
      final starredCourseIds = await _starredService.getStarredCourses();

      if (starredCourseIds.isEmpty) {
        Logger.d(_tag, 'No starred courses, returning original order');
        return courses;
      }

      // Sort courses: starred first, then others
      final sortedCourses = [...courses];
      sortedCourses.sort((a, b) {
        final aIsStarred = starredCourseIds.contains(a.courseID);
        final bIsStarred = starredCourseIds.contains(b.courseID);

        if (aIsStarred && !bIsStarred) {
          return -1; // a comes first
        } else if (!aIsStarred && bIsStarred) {
          return 1; // b comes first
        } else {
          return 0; // maintain original order for courses with same star status
        }
      });

      final starredCount = starredCourseIds.length;
      Logger.i(_tag,
          'Sorted ${courses.length} courses with $starredCount starred courses at the top');

      return sortedCourses;
    } catch (e) {
      Logger.e(_tag, 'Error loading and sorting courses', error: e);
      rethrow;
    }
  }

  Future<List<Course>> _sortPreloadedCourses(
      Future<List<Course>> coursesFuture) async {
    try {
      final courses = await coursesFuture;

      // Get starred course IDs
      final starredCourseIds = await _starredService.getStarredCourses();

      if (starredCourseIds.isEmpty) {
        Logger.d(_tag,
            'No starred courses, returning preloaded courses in original order');
        return courses;
      }

      // Sort courses: starred first, then others
      final sortedCourses = [...courses];
      sortedCourses.sort((a, b) {
        final aIsStarred = starredCourseIds.contains(a.courseID);
        final bIsStarred = starredCourseIds.contains(b.courseID);

        if (aIsStarred && !bIsStarred) {
          return -1; // a comes first
        } else if (!aIsStarred && bIsStarred) {
          return 1; // b comes first
        } else {
          return 0; // maintain original order for courses with same star status
        }
      });

      final starredCount = starredCourseIds.length;
      Logger.i(_tag,
          'Sorted ${courses.length} preloaded courses with $starredCount starred courses at the top');

      return sortedCourses;
    } catch (e) {
      Logger.e(_tag, 'Error sorting preloaded courses', error: e);
      rethrow;
    }
  }

  Future<void> _refreshCourses() async {
    Logger.i(_tag, 'Refreshing course list');
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _loadAndSortCourses();
      setState(() {
        _coursesFuture = Future.value(courses);
        _currentCourses = List.from(courses);
        _isLoading = false;
      });
      Logger.i(_tag, 'Course list refreshed successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Logger.e(_tag, 'Error refreshing courses', error: e);
      rethrow;
    }
  }

  void _handleLogout() async {
    Logger.i(_tag, 'User initiated logout');
    try {
      await _authService.logout();
      if (mounted) {
        Logger.i(_tag, 'Logout successful, navigating to login screen');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Error during logout', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildHomeAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomSliverAppBar(
      title: 'Vedira',
      showLogo: true,
      centerTitle: false,
      floating: true,
      snap: true,
      actions: [
        const ThemeSelector(),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          offset: const Offset(0, 50),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'privacy',
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Privacy Policy',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the body background from theme manager
    final bodyBackgroundColor = colorScheme.bodyBackground;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            Logger.d(_tag, 'Loading courses...');
            return RefreshIndicator(
              onRefresh: _refreshCourses,
              child: CustomScrollView(
                slivers: [
                  _buildHomeAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            final error = snapshot.error;
            Logger.e(
              _tag,
              'Error loading courses',
              error: error,
              stackTrace: StackTrace.current,
            );
            return RefreshIndicator(
              onRefresh: _refreshCourses,
              child: CustomScrollView(
                slivers: [
                  _buildHomeAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: theme.colorScheme.error,
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
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            Logger.w(_tag, 'No courses available');
            return RefreshIndicator(
              onRefresh: _refreshCourses,
              child: CustomScrollView(
                slivers: [
                  _buildHomeAppBar(),
                  SliverFillRemaining(
                    child: _buildOnboardingExperience(),
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data!;
          Logger.i(_tag, 'Loaded ${courses.length} courses');

          // Update local state when data loads
          if (_currentCourses == null ||
              _currentCourses!.length != courses.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _currentCourses = List.from(courses);
              });
            });
          }

          // Use local state if available, otherwise use snapshot data
          final displayCourses = _currentCourses ?? courses;

          return RefreshIndicator(
            onRefresh: _refreshCourses,
            child: CustomScrollView(
              slivers: [
                _buildHomeAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= displayCourses.length)
                          return const SizedBox.shrink();

                        final course = displayCourses[index];
                        final isStarred =
                            _starredCourseIds.contains(course.courseID);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: index == 0
                                ? 0
                                : 4.0, // Reduced top margin for cards
                            bottom: 4.0, // Reduced bottom margin
                          ),
                          child: CourseCard(
                            key: ValueKey(course.courseID),
                            course: course,
                            isStarred: isStarred,
                            onDeleted: () {
                              Logger.i(_tag,
                                  'Course deleted, refreshing course list');
                              _refreshCourses();
                            },
                            onStarToggle: (newStarState) {
                              _handleStarToggle(course.courseID, newStarState);
                            },
                          ),
                        );
                      },
                      childCount: displayCourses.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: _currentCourses != null && _currentCourses!.isNotEmpty,
        child: FloatingActionButton.extended(
          onPressed: () {
            Logger.i(_tag, 'User navigating to create course screen');
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateCourseScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Course'),
          backgroundColor: colorScheme
              .primary, // Use action color for primary action buttons
          foregroundColor: AppConstants.paletteNeutral000,
        ),
      ),
    );
  }

  Widget _buildOnboardingExperience() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppConstants.paletteNeutral900,
                  AppConstants.paletteNeutral800,
                  Color.alphaBlend(
                    AppConstants.palettePrimary.withOpacity(0.1),
                    AppConstants.paletteNeutral800,
                  ),
                ]
              : [
                  AppConstants.paletteNeutral000,
                  Color.alphaBlend(
                    AppConstants.palettePrimary.withOpacity(0.05),
                    AppConstants.paletteNeutral000,
                  ),
                  Color.alphaBlend(
                    AppConstants.palettePrimary.withOpacity(0.08),
                    AppConstants.paletteNeutral100,
                  ),
                ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo section - matching login/splash design
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/assets/full_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Welcome header with personalized greeting
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.palettePrimary.withOpacity(0.15),
                    AppConstants.paletteSecondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.palettePrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_getGreeting()}!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.palettePrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to Vedira',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your AI-powered learning companion',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Value proposition cards with enhanced design
            _buildEnhancedFeatureCard(
              icon: Icons.auto_awesome,
              title: 'AI-Generated Courses',
              description:
                  'Simply tell us what you want to learn, and we\'ll create a personalized course with structured lessons, quizzes, and reading materials.',
              color: AppConstants.palettePrimary,
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 16),

            _buildEnhancedFeatureCard(
              icon: Icons.schedule,
              title: 'Your Learning Timeline',
              description:
                  'Set your own pace! Whether you have 1 week or 3 months, we\'ll break down complex topics into manageable daily lessons.',
              color: AppConstants.paletteSecondary,
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 16),

            _buildEnhancedFeatureCard(
              icon: Icons.quiz,
              title: 'Interactive Learning',
              description:
                  'Reinforce what you\'ve learned with interactive quizzes and track your progress to stay motivated.',
              color: AppConstants.paletteTertiary,
              colorScheme: colorScheme,
              theme: theme,
            ),

            const SizedBox(height: 32),
            // Trust indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTrustIndicator(
                  icon: Icons.flash_on,
                  text: 'Quick Setup',
                  color: AppConstants.palettePrimary,
                ),
                const SizedBox(width: 24),
                _buildTrustIndicator(
                  icon: Icons.psychology,
                  text: 'AI Powered',
                  color: AppConstants.paletteSecondary,
                ),
                const SizedBox(width: 24),
                _buildTrustIndicator(
                  icon: Icons.trending_up,
                  text: 'Track Progress',
                  color: AppConstants.paletteTertiary,
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Enhanced call to action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.paletteAction.withOpacity(0.9),
                    AppConstants.palettePrimary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.paletteAction.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to start learning?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first course in under 2 minutes',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Logger.i(_tag,
                            'User navigating to create course from onboarding');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateCourseScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.add_rounded,
                          color: AppConstants.paletteAction),
                      label: Text(
                        'Create My First Course',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppConstants.paletteAction,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.paletteAction,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildTrustIndicator({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
