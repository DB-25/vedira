import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course.dart';
import '../models/lesson_plan.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';

class ApiService {
  // Base URL for the API
  final String baseUrl = AppConstants.apiBaseUrl;
  final String _tag = 'ApiService';
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all courses from API
  Future<List<Course>> getCourseList({
    String userId = AppConstants.defaultUserId,
  }) async {
    final endpoint = '/get-course-list?user_id=$userId';
    final url = '$baseUrl$endpoint';

    Logger.i(_tag, 'Fetching course list for user: $userId');

    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    try {
      final response = await http.get(Uri.parse(url));

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final courses =
            data.map((courseJson) => Course.fromJson(courseJson)).toList();
        Logger.d(_tag, 'Fetched ${courses.length} courses');
        return courses;
      } else {
        final error =
            '${AppConstants.errorLoadingCourses} Status: ${response.statusCode}';
        Logger.e(_tag, error);
        throw Exception(error);
      }
    } catch (e) {
      final error = '${AppConstants.errorLoadingCourses} Details: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Generate a new course plan
  Future<Course> generateCoursePlan({
    required String topic,
    required String timeline,
    required String difficulty,
    String? customInstructions,
    String userId = AppConstants.defaultUserId,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/generate-course-plan';
    final url = '$baseUrl$endpoint';

    final body = {
      'topic': topic,
      'timeline': timeline,
      'difficulty': difficulty,
      'custom_instructions': customInstructions ?? '',
      'user_id': userId,
    };

    Logger.i(_tag, 'Generating course plan for topic: $topic', data: body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: body,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final course = Course.fromJson(data);
        Logger.d(
          _tag,
          'Course plan generated successfully',
          data: {
            'id': course.courseID,
            'title': course.title,
            'sections': course.sections?.length ?? 0,
            'lessons': course.lessons?.length ?? 0,
          },
        );
        return course;
      } else {
        final error = 'Error generating course: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error generating course plan: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Get a specific course by ID using the lesson plan endpoint
  Future<Course> getCourse(
    String id, {
    String userId = AppConstants.defaultUserId,
  }) async {
    // Validate id parameter
    if (id.isEmpty) {
      Logger.e(_tag, 'Empty course ID provided to getCourse method');
      throw Exception('Course ID cannot be empty');
    }

    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/get-course-plan?course_id=$id&user_id=$userId';
    final url = '$baseUrl$endpoint';

    Logger.i(_tag, 'Fetching course details for ID: "$id", user ID: "$userId"');

    try {
      final response = await http.get(Uri.parse(url));

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Parse the response using LessonPlan model
        final lessonPlan = LessonPlan.fromJson(data);

        // Convert LessonPlan to Course for compatibility with existing UI
        final course = lessonPlan.toCourse();

        // Validate the resulting courseID
        if (course.courseID.isEmpty) {
          Logger.w(_tag, 'Parsed course has empty courseID after conversion');
        }

        Logger.d(
          _tag,
          'Course details fetched successfully',
          data: {
            'id': course.courseID,
            'title': course.title,
            'chapters': lessonPlan.chapters.length,
            'lessons': lessonPlan.chapters.fold<int>(
              0,
              (sum, chapter) => sum + chapter.lessons.length,
            ),
          },
        );

        return course;
      } else if (response.statusCode == 404) {
        final error = AppConstants.errorCourseNotFound;
        Logger.e(_tag, error);
        throw Exception(error);
      } else {
        final error = 'Error fetching course: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error fetching course details: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Delete a course
  Future<bool> deleteCourse(String id) async {
    // Placeholder implementation
    Logger.api('DELETE', '/delete-course/$id (PLACEHOLDER)');
    Logger.w(
      _tag,
      'deleteCourse method is a placeholder and does not make a real API call',
    );
    return true;
  }

  // Get lesson content from API - returns structured data for pagination
  Future<Map<String, String>> getLessonContent({
    required String courseId,
    required String chapterId,
    required String lessonId,
    String userId = AppConstants.defaultUserId,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint =
        '/get-lesson-content?course_id=$courseId&user_id=$userId&chapter_id=$chapterId&lesson_id=$lessonId';
    final url = '$baseUrl$endpoint';

    Logger.i(
      _tag,
      'Fetching lesson content',
      data: {
        'courseId': courseId,
        'chapterId': chapterId,
        'lessonId': lessonId,
        'userId': userId,
      },
    );

    try {
      final response = await http.get(Uri.parse(url));

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody:
            response.body.length > 100
                ? '${response.body.substring(0, 100)}...'
                : response.body,
      );

      if (response.statusCode == 200) {
        // The API returns lesson content as JSON with multiple key-value pairs for pagination
        try {
          final Map<String, dynamic> data = json.decode(response.body);

          if (data.isEmpty) {
            throw Exception('No lesson content found in response');
          }

          // Convert all values to strings and return the complete structure
          final Map<String, String> contentSections = {};
          data.forEach((key, value) {
            contentSections[key] = value.toString();
          });

          Logger.d(
            _tag,
            'Lesson content fetched successfully',
            data: {
              'sectionsCount': contentSections.length,
              'sectionKeys': contentSections.keys.toList(),
              'totalContentLength': contentSections.values.fold<int>(
                0,
                (sum, content) => sum + content.length,
              ),
            },
          );
          return contentSections;
        } catch (e) {
          // If JSON parsing fails, fall back to treating it as plain text with single section
          Logger.w(
            _tag,
            'Failed to parse lesson content as JSON, treating as plain text: $e',
          );
          final String content = response.body;
          Logger.d(
            _tag,
            'Lesson content fetched as plain text',
            data: {'contentLength': content.length},
          );
          return {'content': content};
        }
      } else {
        final error =
            'Error fetching lesson content: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error fetching lesson content: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Generate chapter content
  Future<Map<String, dynamic>> generateChapter({
    required String courseId,
    required String chapterId,
    String userId = AppConstants.defaultUserId,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/generate-chapter';
    final url = '$baseUrl$endpoint';

    final body = {
      'course_id': courseId,
      'user_id': userId,
      'chapter_id': chapterId,
    };

    Logger.i(
      _tag,
      'Triggering chapter content generation',
      data: {'courseId': courseId, 'chapterId': chapterId, 'userId': userId},
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Logger.api(
        'POST',
        endpoint,
        requestBody: body,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Logger.i(
          _tag,
          'Chapter generation triggered successfully',
          data: {
            'executionArn': result['executionArn'],
            'startDate': result['startDate'],
          },
        );
        return result;
      } else {
        final error =
            'Error triggering chapter generation: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error triggering chapter generation: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Check chapter generation status
  Future<Map<String, dynamic>> checkChapterGenerationStatus({
    required String executionArn,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = '${AppConstants.errorNoInternet}';
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint =
        '/check-chapter-generation-status?executionArn=$executionArn';
    final url = '$baseUrl$endpoint';

    Logger.d(
      _tag,
      'Checking chapter generation status',
      data: {'executionArn': executionArn},
    );

    try {
      final response = await http.get(Uri.parse(url));

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Logger.d(
          _tag,
          'Chapter generation status checked',
          data: {
            'status': result['status'],
            'isComplete': result['isComplete'],
            'isFailed': result['isFailed'],
          },
        );
        return result;
      } else {
        final error =
            'Error checking chapter generation status: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error checking chapter generation status: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Dispose service when no longer needed
  void dispose() {
    _connectivityService.dispose();
  }
}
