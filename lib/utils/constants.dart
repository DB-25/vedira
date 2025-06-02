import 'package:flutter/material.dart';

class AppConstants {
  // API Constants
  static const String apiBaseUrl =
      'https://i7cicaxvzf.execute-api.us-east-1.amazonaws.com/prod';

  // App Theme Colors
  static const Color primaryColorLight = Colors.teal;
  static const Color primaryColorDark = Color(0xFF26D7AE);
  static const Color accentColorLight = Color(0xFF7E57C2);
  static const Color accentColorDark = Color(0xFFB388FF);
  static const Color backgroundColorLight = Color(0xFFFAFAFA);
  static const Color backgroundColorDark = Color(0xFF121212);
  static const Color cardColorLight = Color(0xFFF5F5F5);
  static const Color cardColorDark = Color(0xFF1E1E1E);
  static const Color textColorLight = Color(0xFF212121);
  static const Color textColorDark = Color(0xFFECECEC);
  static const Color textColorSecondaryLight = Color(0xFF616161);
  static const Color textColorSecondaryDark = Color(0xFFB0B0B0);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStyle = TextStyle(fontSize: 16);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  // Layout Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Error Messages
  static const String errorLoadingCourses =
      'Unable to load courses. Please check your connection and try again.';
  static const String errorCourseNotFound = 'Course not found.';
  static const String errorGeneratingCourse =
      'Error generating course. Please try again later.';
  static const String errorGeneratingChapter =
      'Error generating chapter. Please try again later.';
  static const String errorChapterGenerationTimeout =
      'Chapter generation timed out. Please try again.';
  static const String errorChapterGenerationFailed =
      'Chapter generation failed. Please try again.';
  static const String noCoursesAvailable =
      'No courses available at the moment.';
  static const String noLessonsAvailable =
      'No lessons available for this course.';
  static const String errorNoInternet =
      'No internet connection. Please check your connection and try again.';

  // Route Names
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String courseDetailsRoute = '/course-details';
  static const String lessonRoute = '/lesson';
  static const String createCourseRoute = '/create-course';
  static const String lessonViewRoute = '/lesson-view';

  // Feature Flags
  static const bool enableCreateCourse =
      false; // Set to true when create course feature is implemented
  static const bool enableUserAuthentication =
      true; // Authentication is now implemented
  static const bool useBackwardUserId =
      true; // For testing: when true, adds user_id=rs to API calls

  // Course Generation
  static const String generatingCourseMessage = 'Generating course plan...';
  static const String generatingCourseSubMessage =
      'This may take a few minutes.';
  static const String generatingCourseCancelMessage = 'Cancel';

  // Chapter Generation Polling
  static const Duration chapterPollingInterval = Duration(seconds: 5);
  static const Duration chapterGenerationTimeout = Duration(minutes: 15);
  static const String generatingChapterMessage = 'Generating chapter...';
  static const String generatingChapterSubMessage =
      'This may take a few minutes.';
  static const String chapterGeneratedSuccessMessage =
      'Chapter generated successfully!';
  static const String chapterGenerationFailedMessage =
      'Chapter generation failed. Please try again.';

  // Reading Progress Indicator
  static const Color progressBarActiveColor = Colors.blue;
  static const Color progressBarBackgroundColor = Colors.grey;
  static const double progressBarHeight = 4.0;
  static const double scrollIndicatorWidth = 6.0;
  static const double scrollIndicatorThumbHeight = 20.0;
  static const Duration progressAnimationDuration = Duration(milliseconds: 100);
}
