import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course.dart';
import '../models/lesson_plan.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class ApiService {
  // Base URL for the API
  final String baseUrl = AppConstants.apiBaseUrl;
  final String _tag = 'ApiService';

  // Get all courses from API
  Future<List<Course>> getCourseList({
    String userId = AppConstants.defaultUserId,
  }) async {
    final endpoint = '/get-course-list?user_id=$userId';
    final url = '$baseUrl$endpoint';

    Logger.i(_tag, 'Fetching course list for user: $userId');

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
    final endpoint = '/generate-lesson-plan';
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

    final endpoint = '/get-lesson-plan?course_id=$id&user_id=$userId';
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
}
