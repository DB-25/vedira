import 'dart:convert';

import '../models/course.dart';
import '../models/lesson_plan.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';
import 'api_client.dart';

class ApiService {
  // Base URL for the API
  final String baseUrl = AppConstants.apiBaseUrl;
  final String _tag = 'ApiService';
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiClient _apiClient = ApiClient.instance;

  // Get all courses from API
  Future<List<Course>> getCourseList() async {
    final endpoint = '/get-course-list';
    String url = '$baseUrl$endpoint';

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      url += '?user_id=rs';
    }

    Logger.i(_tag, 'Fetching course list');

    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
      Logger.e(_tag, error);
      throw Exception(error);
    }

    try {
      final response = await _apiClient.get(url);

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
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
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
    };

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      body['user_id'] = 'rs';
    }

    Logger.i(_tag, 'Generating course plan for topic: $topic', data: body);

    try {
      final response = await _apiClient.post(url, body: body);

      Logger.api(
        'POST',
        endpoint,
        requestBody: body,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // ====== COMPREHENSIVE COURSE GENERATION RESPONSE LOGGING ======
        Logger.i(_tag, '🔍 COMPLETE /generate-course-plan API RESPONSE:');
        Logger.i(_tag, '📋 Raw Response Body Length: ${response.body.length} characters');
        
        // Log the complete response structure
        final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
        Logger.i(_tag, '📄 Complete Response Structure:\n$prettyJson');
        
        // Log all top-level keys
        if (data is Map<String, dynamic>) {
          Logger.i(_tag, '🔑 Top-level keys in generate response: ${data.keys.toList()}');
          
          // Check for any new or unknown keys in generation response
          final knownGenerationKeys = ['courseID', 'title', 'description', 'sections', 'lessons'];
          final allKeys = data.keys.toSet();
          final unknownKeys = allKeys.difference(knownGenerationKeys.toSet());
          
          if (unknownKeys.isNotEmpty) {
            Logger.i(_tag, '🆕 NEW/UNKNOWN GENERATION KEYS DETECTED: $unknownKeys');
            
            // Log details of unknown keys
            for (final key in unknownKeys) {
              final value = data[key];
              Logger.i(_tag, '🔍 Unknown generation key "$key" type: ${value.runtimeType}');
              if (value is List) {
                Logger.i(_tag, '🔍 Unknown generation key "$key" list length: ${value.length}');
              } else if (value is Map) {
                Logger.i(_tag, '🔍 Unknown generation key "$key" map keys: ${(value as Map).keys.toList()}');
              } else {
                Logger.i(_tag, '🔍 Unknown generation key "$key" value: $value');
              }
            }
          } else {
            Logger.i(_tag, '✅ All generation keys are known and expected');
          }
        }
        // ===== END COMPREHENSIVE LOGGING =====

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

  // Generate a course plan from uploaded document
  Future<Course> generateCoursePlanFromDocument({
    required String topic,
    required String timeline,
    required String difficulty,
    required String documentType,
    required String documentContent,
    String? customInstructions,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
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
      'document_type': documentType,
      'document_content': documentContent,
    };

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      body['user_id'] = 'rs';
    }

    Logger.i(_tag, 'Generating course plan from document for topic: $topic', 
      data: {
        'topic': topic,
        'timeline': timeline,
        'difficulty': difficulty,
        'document_type': documentType,
        'document_size': '${documentContent.length} chars',
        'has_custom_instructions': customInstructions?.isNotEmpty ?? false,
      });

    try {
      final response = await _apiClient.post(url, body: body);

      Logger.api(
        'POST',
        endpoint,
        requestBody: {
          ...body,
          'document_content': '[BASE64_CONTENT_${documentContent.length}_CHARS]'
        },
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // ====== COMPREHENSIVE DOCUMENT COURSE GENERATION RESPONSE LOGGING ======
        Logger.i(_tag, '🔍 COMPLETE /generate-course-plan (FROM DOCUMENT) API RESPONSE:');
        Logger.i(_tag, '📋 Raw Response Body Length: ${response.body.length} characters');
        
        // Log the complete response structure
        final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
        Logger.i(_tag, '📄 Complete Document Generation Response Structure:\n$prettyJson');
        
        // Log all top-level keys
        if (data is Map<String, dynamic>) {
          Logger.i(_tag, '🔑 Top-level keys in document generation response: ${data.keys.toList()}');
          
          // Check for any new or unknown keys in document generation response
          final knownDocumentGenerationKeys = ['courseID', 'title', 'description', 'sections', 'lessons'];
          final allKeys = data.keys.toSet();
          final unknownKeys = allKeys.difference(knownDocumentGenerationKeys.toSet());
          
          if (unknownKeys.isNotEmpty) {
            Logger.i(_tag, '🆕 NEW/UNKNOWN DOCUMENT GENERATION KEYS DETECTED: $unknownKeys');
            
            // Log details of unknown keys
            for (final key in unknownKeys) {
              final value = data[key];
              Logger.i(_tag, '🔍 Unknown document generation key "$key" type: ${value.runtimeType}');
              if (value is List) {
                Logger.i(_tag, '🔍 Unknown document generation key "$key" list length: ${value.length}');
              } else if (value is Map) {
                Logger.i(_tag, '🔍 Unknown document generation key "$key" map keys: ${(value as Map).keys.toList()}');
              } else {
                Logger.i(_tag, '🔍 Unknown document generation key "$key" value: $value');
              }
            }
          } else {
            Logger.i(_tag, '✅ All document generation keys are known and expected');
          }
        }
        // ===== END COMPREHENSIVE LOGGING =====

        final course = Course.fromJson(data);
        Logger.d(
          _tag,
          'Course plan generated successfully from document',
          data: {
            'id': course.courseID,
            'title': course.title,
            'sections': course.sections?.length ?? 0,
            'lessons': course.lessons?.length ?? 0,
          },
        );
        return course;
      } else {
        final error = 'Error generating course from document: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error generating course plan from document: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Get a specific course by ID using the lesson plan endpoint
  Future<Course> getCourse(String id) async {
    // Validate id parameter
    if (id.isEmpty) {
      Logger.e(_tag, 'Empty course ID provided to getCourse method');
      throw Exception('Course ID cannot be empty');
    }

    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/get-course-plan';
    String url = '$baseUrl$endpoint?course_id=$id';

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      url += '&user_id=rs';
    }

    Logger.i(_tag, 'Fetching course details for ID: "$id"');

    try {
      final response = await _apiClient.get(url);

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // ====== COMPREHENSIVE API RESPONSE LOGGING ======
        Logger.i(_tag, '🔍 COMPLETE /get-course-plan API RESPONSE:');
        Logger.i(_tag, '📋 Raw Response Body Length: ${response.body.length} characters');
        
        // Log the complete response structure
        final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
        Logger.i(_tag, '📄 Complete Response Structure:\n$prettyJson');
        
        // Log all top-level keys
        if (data is Map<String, dynamic>) {
          Logger.i(_tag, '🔑 Top-level keys in response: ${data.keys.toList()}');
          
          // Check for any new or unknown keys
          final knownKeys = ['course_id', 'course_title', 'chapters', 'sections', 'lessons'];
          final allKeys = data.keys.toSet();
          final unknownKeys = allKeys.difference(knownKeys.toSet());
          
          if (unknownKeys.isNotEmpty) {
            Logger.i(_tag, '🆕 NEW/UNKNOWN KEYS DETECTED: $unknownKeys');
            
            // Log details of unknown keys
            for (final key in unknownKeys) {
              final value = data[key];
              Logger.i(_tag, '🔍 Unknown key "$key" type: ${value.runtimeType}');
              if (value is List) {
                Logger.i(_tag, '🔍 Unknown key "$key" list length: ${value.length}');
              } else if (value is Map) {
                Logger.i(_tag, '🔍 Unknown key "$key" map keys: ${(value as Map).keys.toList()}');
              } else {
                Logger.i(_tag, '🔍 Unknown key "$key" value: $value');
              }
            }
          } else {
            Logger.i(_tag, '✅ All keys are known and expected');
          }
          
          // Log details of known keys for comparison
          for (final key in knownKeys) {
            if (data.containsKey(key)) {
              final value = data[key];
              Logger.i(_tag, '✅ Known key "$key": ${value.runtimeType}, ${value is List ? 'length ${value.length}' : value is Map ? 'map with ${(value as Map).keys.length} keys' : 'value: $value'}');
            } else {
              Logger.i(_tag, '❌ Expected key "$key" is missing');
            }
          }
        }
        // ===== END COMPREHENSIVE LOGGING =====

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
  Future<bool> deleteCourse(String courseId) async {
    // Validate courseId parameter
    if (courseId.isEmpty) {
      Logger.e(_tag, 'Empty course ID provided to deleteCourse method');
      throw Exception('Course ID cannot be empty');
    }

    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/delete-course';
    final url = '$baseUrl$endpoint?course_id=$courseId';

    Logger.i(_tag, 'Deleting course with ID: $courseId');

    try {
      final response = await _apiClient.delete(url);

      Logger.api(
        'DELETE',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        Logger.i(_tag, 'Course deleted successfully', data: {'courseId': courseId});
        return true;
      } else if (response.statusCode == 404) {
        final error = 'Course not found';
        Logger.e(_tag, error);
        throw Exception(error);
      } else {
        final error = 'Error deleting course: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error deleting course: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Get lesson content from API - returns structured data for pagination
  Future<Map<String, String>> getLessonContent({
    required String courseId,
    required String chapterId,
    required String lessonId,
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/get-lesson-content';
    String url =
        '$baseUrl$endpoint?course_id=$courseId&chapter_id=$chapterId&lesson_id=$lessonId';

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      url += '&user_id=rs';
    }

    Logger.i(
      _tag,
      'Fetching lesson content',
      data: {
        'courseId': courseId,
        'chapterId': chapterId,
        'lessonId': lessonId,
      },
    );

    try {
      final response = await _apiClient.get(url);

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
  }) async {
    // Check if internet is available
    bool isConnected = await _connectivityService.isInternetAvailable();
    if (!isConnected) {
      final error = AppConstants.errorNoInternet;
      Logger.e(_tag, error);
      throw Exception(error);
    }

    final endpoint = '/generate-chapter';
    final url = '$baseUrl$endpoint';

    final body = {'course_id': courseId, 'chapter_id': chapterId};

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      body['user_id'] = 'rs';
    }

    Logger.i(
      _tag,
      'Triggering chapter content generation',
      data: {'courseId': courseId, 'chapterId': chapterId},
    );

    try {
      final response = await _apiClient.post(url, body: body);

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
      final response = await _apiClient.get(url);

      Logger.api(
        'GET',
        endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Handle new API format with step_function_details and chapter_generation_status
        final stepFunctionDetails =
            result['step_function_details'] as Map<String, dynamic>?;
        final chapterGenerationStatus =
            result['chapter_generation_status'] as Map<String, dynamic>?;

        // Extract status from step function details for backward compatibility
        final status = stepFunctionDetails?['status'] ?? 'UNKNOWN';
        final isComplete = status == 'SUCCEEDED';
        final isFailed =
            status == 'FAILED' || status == 'TIMED_OUT' || status == 'ABORTED';

        // Prepare enhanced response
        final enhancedResult = {
          'status': status,
          'isComplete': isComplete,
          'isFailed': isFailed,
          'step_function_details': stepFunctionDetails,
          'chapter_generation_status': chapterGenerationStatus,
        };

        Logger.d(
          _tag,
          'Chapter generation status checked',
          data: {
            'status': status,
            'isComplete': isComplete,
            'isFailed': isFailed,
            'hasChapterStatus': chapterGenerationStatus != null,
          },
        );

        return enhancedResult;
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
