import 'dart:convert';

import '../models/mcq_question.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';
import 'api_client.dart';

class McqService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final String _tag = 'McqService';
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiClient _apiClient = ApiClient.instance;

  // Fetch MCQ questions for a specific lesson
  Future<List<McqQuestion>> fetchQuestions({
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

    final endpoint = '/questions';
    String url =
        '$baseUrl$endpoint?course_id=$courseId&chapter_id=$chapterId&lesson_id=$lessonId';

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      url += '&user_id=rs';
    }

    Logger.i(
      _tag,
      'Fetching MCQ questions',
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
            response.body.length > 500
                ? '${response.body.substring(0, 500)}...'
                : response.body,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          Logger.w(_tag, 'No MCQ questions found for the lesson');
          return [];
        }

        final questions =
            data
                .map((questionJson) => McqQuestion.fromJson(questionJson))
                .where(
                  (question) => question.isValid,
                ) // Only include valid questions
                .toList();

        Logger.d(
          _tag,
          'MCQ questions fetched successfully',
          data: {
            'totalQuestions': data.length,
            'validQuestions': questions.length,
            'invalidQuestions': data.length - questions.length,
          },
        );

        return questions;
      } else if (response.statusCode == 404) {
        Logger.w(_tag, 'No MCQ questions found for this lesson');
        return [];
      } else {
        final error =
            'Error fetching MCQ questions: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error fetching MCQ questions: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Check if MCQs are available for a lesson (without fetching them)
  Future<bool> areMcqsAvailable({
    required String courseId,
    required String chapterId,
    required String lessonId,
  }) async {
    try {
      final questions = await fetchQuestions(
        courseId: courseId,
        chapterId: chapterId,
        lessonId: lessonId,
      );
      return questions.isNotEmpty;
    } catch (e) {
      Logger.w(_tag, 'Error checking MCQ availability: $e');
      return false;
    }
  }

  // Dispose service when no longer needed
  void dispose() {
    _connectivityService.dispose();
  }
}
