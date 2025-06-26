import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // API Constants
  static const String apiBaseUrl =
      'https://i7cicaxvzf.execute-api.us-east-1.amazonaws.com/prod';

  // =========================
  // CENTRALIZED COLOR PALETTES - ACCESSIBILITY FOCUSED
  // =========================

  // Current Color Palette - WCAG AA Compliant
  static const Color palettePrimary =
      Color(0xFF4CAF50); // app bar, with tint for bg
  static const Color paletteSecondary =
      Color(0xFFF66194); // primary buttons, primary action,
  static const Color paletteTertiary = Color(0xFFFFB74D); // secondary actions
  static const Color paletteAction =
      Color(0xFF1B5E20); // star, start learning all primary buttons

  // Neutral Scale // use for text - to demonstrate hierarchy
  static const Color paletteNeutral000 = Color(0xFFFFFFFF);
  static const Color paletteNeutral100 = Color(0xFFE8E8E8);
  static const Color paletteNeutral200 = Color(0xFFD2D2D2);
  static const Color paletteNeutral300 = Color(0xFFBBBBBB);
  static const Color paletteNeutral400 = Color(0xFFA4A4A4);
  static const Color paletteNeutral500 = Color(0xFF8E8E8E);
  static const Color paletteNeutral600 = Color(0xFF777777);
  static const Color paletteNeutral700 = Color(0xFF606060);
  static const Color paletteNeutral800 = Color(0xFF4A4A4A);
  static const Color paletteNeutral900 = Color(0xFF333333);

  static const Color darkSurfaceGreen = Color(0xFF1E2B22);


  // Error Colors
  static const Color paletteErrorLight = Color(0xFFF69393);
  static const Color paletteErrorMain = Color(0xFFE75B5B);
  static const Color paletteErrorDark = Color(0xFFD32F2F);

  // Warning Colors
  static const Color paletteWarningLight = Color(0xFFFFFFC4);
  static const Color paletteWarningMedium = Color(0xFFFFFF9C);
  static const Color paletteWarningDark = Color(0xFFF3F63D);

  // Success Colors
  static const Color paletteSuccessLight = Color(0xFFA5FAAA);
  static const Color paletteSuccessMedium = Color(0xFF7AD07F);
  static const Color paletteSuccessDark = Color(0xFF329C39);

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
