import 'dart:convert';

import '../models/flashcard.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';
import 'api_client.dart';

class FlashcardService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final String _tag = 'FlashcardService';
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiClient _apiClient = ApiClient.instance;

  // Fetch flashcards for a specific lesson
  Future<List<Flashcard>> fetchFlashcards({
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

    final endpoint = '/flashcards';
    String url =
        '$baseUrl$endpoint?courseId=$courseId&chapterId=$chapterId&lessonId=$lessonId';

    // Conditionally append user_id for testing
    if (AppConstants.useBackwardUserId) {
      url += '&user_id=rs';
    }

    Logger.i(
      _tag,
      'Fetching flashcards',
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
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> flashcardsData = responseData['flashcards'] ?? [];

        if (flashcardsData.isEmpty) {
          Logger.w(_tag, 'No flashcards found for the lesson');
          return [];
        }

        final flashcards =
            flashcardsData
                .map((flashcardJson) => Flashcard.fromJson(flashcardJson))
                .where(
                  (flashcard) => flashcard.isValid,
                ) // Only include valid flashcards
                .toList();

        Logger.d(
          _tag,
          'Flashcards fetched successfully',
          data: {
            'totalFlashcards': flashcardsData.length,
            'validFlashcards': flashcards.length,
            'invalidFlashcards': flashcardsData.length - flashcards.length,
            'count': responseData['count'],
            'courseId': responseData['courseId'],
            'chapterId': responseData['chapterId'],
            'lessonId': responseData['lessonId'],
          },
        );

        return flashcards;
      } else if (response.statusCode == 404) {
        Logger.w(_tag, 'No flashcards found for this lesson');
        return [];
      } else {
        final error =
            'Error fetching flashcards: Status ${response.statusCode}';
        Logger.e(_tag, error, error: response.body);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error fetching flashcards: $e';
      Logger.e(_tag, error, error: e, stackTrace: StackTrace.current);
      throw Exception(error);
    }
  }

  // Check if flashcards are available for a lesson (without fetching them)
  Future<bool> areFlashcardsAvailable({
    required String courseId,
    required String chapterId,
    required String lessonId,
  }) async {
    try {
      final flashcards = await fetchFlashcards(
        courseId: courseId,
        chapterId: chapterId,
        lessonId: lessonId,
      );
      return flashcards.isNotEmpty;
    } catch (e) {
      Logger.w(_tag, 'Error checking flashcard availability: $e');
      return false;
    }
  }

  // Dispose service when no longer needed
  void dispose() {
    _connectivityService.dispose();
  }
} 