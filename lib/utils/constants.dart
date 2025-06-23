import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // API Constants
  static const String apiBaseUrl =
      'https://i7cicaxvzf.execute-api.us-east-1.amazonaws.com/prod';

  // =========================
  // CENTRALIZED COLOR PALETTES - ACCESSIBILITY FOCUSED
  // =========================
  
  // Palette 1 (Secondary) - Cool Green Theme - WCAG AA Compliant
  static const Color palette1Primary = Color(0xFF1B5E20); // darker green for better contrast
  static const Color palette1PrimaryLight = Color(0xFF4CAF50); // lighter variant for accents
  static const Color palette1Secondary = Color(0xFFE91E63); // stronger pink for better contrast
  static const Color palette1Accent = Color(0xFFD32F2F); // stronger red for alerts
  static const Color palette1Background = Color(0xFF2E2E2E); // better contrast dark background
  static const Color palette1Surface = Color(0xFF424242); // mid-tone for cards
  static const Color palette1Success = Color(0xFF4CAF50); // standard green for success
  static const Color palette1Warning = Color(0xFFFF9800); // standard orange for warnings
  
  // Palette 2 (Primary, Default) - Electric Blue Theme - WCAG AA Compliant
  static const Color palette2Primary = Color(0xFF1976D2); // darker blue for better contrast
  static const Color palette2PrimaryLight = Color(0xFF2196F3); // lighter variant for accents
  static const Color palette2Secondary = Color(0xFF424242); // proper gray instead of pure black
  static const Color palette2Accent = Color(0xFFFF9800); // orange instead of gold for better contrast
  static const Color palette2Danger = Color(0xFFD32F2F); // standard red for errors
  static const Color palette2Background = Color(0xFF1E1E1E); // proper dark background
  static const Color palette2Surface = Color(0xFF2E2E2E); // mid-tone for cards
  static const Color palette2Highlight = Color(0xFFFFC107); // amber instead of yellow for better contrast

  // Text Styles - Using Google Fonts
  static final TextStyle headingStyle = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle subheadingStyle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodyStyle = GoogleFonts.poppins(fontSize: 16);

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
  static const String mcqQuizRoute = '/mcq-quiz';

  // Feature Flags
  static const bool enableCreateCourse =
      false; // Set to true when create course feature is implemented
  static const bool enableUserAuthentication =
      true; // Authentication is now implemented
  static const bool useBackwardUserId =
      false; // For testing: when true, adds user_id=rs to API calls

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
  static const double progressBarHeight = 4.0;
  static const double scrollIndicatorWidth = 6.0;
  static const double scrollIndicatorThumbHeight = 20.0;
  static const Duration progressAnimationDuration = Duration(milliseconds: 100);

  // Image processing
  /// Converts an S3 URI to the get-image endpoint URL
  /// Example: s3://bucket/key -> https://api.com/get-image?s3Url=s3://bucket/key
  static String getImageUrl(String s3Uri) {
    if (s3Uri.isEmpty || !s3Uri.startsWith('s3://')) {
      return '';
    }

    // URL encode the S3 URI to handle special characters
    final encodedUri = Uri.encodeQueryComponent(s3Uri);
    return '$apiBaseUrl/get-image?s3Url=$encodedUri';
  }
}
