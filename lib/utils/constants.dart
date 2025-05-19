import 'package:flutter/material.dart';

class AppConstants {
  // API Constants
  static const String apiBaseUrl =
      'https://rgml14alw6.execute-api.us-east-1.amazonaws.com';
  static const String defaultUserId = 'rs';

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
  static const String noCoursesAvailable =
      'No courses available at the moment.';
  static const String noLessonsAvailable =
      'No lessons available for this course.';

  // Route Names
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String courseDetailsRoute = '/course-details';
  static const String lessonRoute = '/lesson';
  static const String createCourseRoute = '/create-course';

  // Feature Flags
  static const bool enableCreateCourse =
      false; // Set to true when create course feature is implemented
  static const bool enableUserAuthentication =
      false; // Set to true when authentication is implemented

  // Course Generation
  static const String generatingCourseMessage = 'Generating course plan...';
  static const String generatingCourseSubMessage =
      'This may take a few minutes.';
  static const String generatingCourseCancelMessage = 'Cancel';
}
