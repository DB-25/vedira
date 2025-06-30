import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import '../utils/logger.dart';

class ProgressService {
  static const String _progressKeyPrefix = 'user_progress_';
  static const String _allCoursesKey = 'all_courses_progress';
  final String _tag = 'ProgressService';

  // Get progress for a specific course
  Future<UserProgress?> getCourseProgress(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('$_progressKeyPrefix$courseId');

      if (progressJson == null) return null;

      final progressMap = jsonDecode(progressJson) as Map<String, dynamic>;
      return UserProgress.fromJson(progressMap);
    } catch (e) {
      Logger.e(_tag, 'Error loading course progress for $courseId', error: e);
      return null;
    }
  }

  // Save progress for a specific course
  Future<bool> saveCourseProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(progress.toJson());

      // Save individual course progress
      await prefs.setString(
        '$_progressKeyPrefix${progress.courseId}',
        progressJson,
      );

      // Update the list of all courses
      await _updateCoursesList(progress.courseId, progress.courseName);

      Logger.i(_tag, 'Saved progress for course: ${progress.courseId}');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Error saving course progress', error: e);
      return false;
    }
  }

  // Get all courses with progress
  Future<List<UserProgress>> getAllCoursesProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_allCoursesKey);

      if (coursesJson == null) return [];

      final coursesList = jsonDecode(coursesJson) as List;
      List<UserProgress> allProgress = [];

      for (var courseInfo in coursesList) {
        final courseId = courseInfo['courseId'] as String;
        final progress = await getCourseProgress(courseId);
        if (progress != null) {
          allProgress.add(progress);
        }
      }

      return allProgress;
    } catch (e) {
      Logger.e(_tag, 'Error loading all courses progress', error: e);
      return [];
    }
  }

  // Mark lesson as completed
  Future<bool> markLessonCompleted({
    required String courseId,
    required String chapterId,
    required String lessonId,
    required String lessonName,
    required int studyTimeMinutes,
  }) async {
    try {
      var progress = await getCourseProgress(courseId);

      // Create new progress if doesn't exist
      if (progress == null) {
        progress = UserProgress(
          courseId: courseId,
          courseName: '', // Will be updated later
          lastStudied: DateTime.now(),
          totalStudyTimeMinutes: 0,
          chapterProgress: {},
          studySessions: [],
          stats: CourseStats(
            totalStudyDays: 0,
            currentStreak: 0,
            longestStreak: 0,
            weeklyActivity: {},
            achievements: [],
          ),
        );
      }

      // Update chapter progress
      final chapterProgress =
          progress.chapterProgress[chapterId] ??
          ChapterProgress(
            chapterId: chapterId,
            chapterName: '', // Will be updated later
            completedLessons: {},
            availableLessons: {},
            quizAttempts: {},
            flashcardAttempts: {},
            studyTimeMinutes: 0,
            isUnlocked: true,
          );

      final updatedChapterProgress = ChapterProgress(
        chapterId: chapterProgress.chapterId,
        chapterName: chapterProgress.chapterName,
        completedLessons: {...chapterProgress.completedLessons, lessonId},
        availableLessons: {...chapterProgress.availableLessons, lessonId},
        quizAttempts: chapterProgress.quizAttempts,
        flashcardAttempts: chapterProgress.flashcardAttempts,
        lastStudied: DateTime.now(),
        studyTimeMinutes: chapterProgress.studyTimeMinutes + studyTimeMinutes,
        isUnlocked: chapterProgress.isUnlocked,
      );

      // Add study session
      final studySession = StudySession(
        startTime: DateTime.now().subtract(Duration(minutes: studyTimeMinutes)),
        endTime: DateTime.now(),
        chapterId: chapterId,
        lessonId: lessonId,
        activity: 'reading',
        metadata: {'lessonName': lessonName},
      );

      final updatedProgress = progress.copyWith(
        lastStudied: DateTime.now(),
        totalStudyTimeMinutes:
            progress.totalStudyTimeMinutes + studyTimeMinutes,
        chapterProgress: {
          ...progress.chapterProgress,
          chapterId: updatedChapterProgress,
        },
        studySessions: [...progress.studySessions, studySession],
      );

      return await saveCourseProgress(updatedProgress);
    } catch (e) {
      Logger.e(_tag, 'Error marking lesson completed', error: e);
      return false;
    }
  }

  // Save quiz attempt
  Future<bool> saveQuizAttempt({
    required String courseId,
    required String chapterId,
    required String lessonId,
    required String lessonName,
    required QuizAttempt quizAttempt,
  }) async {
    try {
      var progress = await getCourseProgress(courseId);
      if (progress == null) return false;

      final chapterProgress = progress.chapterProgress[chapterId];
      if (chapterProgress == null) return false;

      // Add quiz attempt to existing attempts
      final existingAttempts = chapterProgress.quizAttempts[lessonId] ?? [];
      final updatedAttempts = [...existingAttempts, quizAttempt];

      final updatedChapterProgress = ChapterProgress(
        chapterId: chapterProgress.chapterId,
        chapterName: chapterProgress.chapterName,
        completedLessons: chapterProgress.completedLessons,
        availableLessons: chapterProgress.availableLessons,
        quizAttempts: {
          ...chapterProgress.quizAttempts,
          lessonId: updatedAttempts,
        },
        flashcardAttempts: chapterProgress.flashcardAttempts,
        lastStudied: DateTime.now(),
        studyTimeMinutes: chapterProgress.studyTimeMinutes,
        isUnlocked: chapterProgress.isUnlocked,
      );

      // Add study session for quiz
      final studySession = StudySession(
        startTime: quizAttempt.completedAt.subtract(
          Duration(seconds: quizAttempt.timeSpentSeconds),
        ),
        endTime: quizAttempt.completedAt,
        chapterId: chapterId,
        lessonId: lessonId,
        activity: 'quiz',
        metadata: {
          'score': quizAttempt.score,
          'totalQuestions': quizAttempt.totalQuestions,
          'scorePercentage': quizAttempt.scorePercentage,
        },
      );

      final updatedProgress = progress.copyWith(
        lastStudied: DateTime.now(),
        chapterProgress: {
          ...progress.chapterProgress,
          chapterId: updatedChapterProgress,
        },
        studySessions: [...progress.studySessions, studySession],
      );

      return await saveCourseProgress(updatedProgress);
    } catch (e) {
      Logger.e(_tag, 'Error saving quiz attempt', error: e);
      return false;
    }
  }

  // Save flashcard attempt
  Future<bool> saveFlashcardAttempt({
    required String courseId,
    required String chapterId,
    required String lessonId,
    required String lessonName,
    required FlashcardAttempt flashcardAttempt,
  }) async {
    try {
      var progress = await getCourseProgress(courseId);
      if (progress == null) return false;

      final chapterProgress = progress.chapterProgress[chapterId];
      if (chapterProgress == null) return false;

      // Add flashcard attempt to existing attempts
      final existingAttempts = chapterProgress.flashcardAttempts[lessonId] ?? [];
      final updatedAttempts = [...existingAttempts, flashcardAttempt];

      final updatedChapterProgress = ChapterProgress(
        chapterId: chapterProgress.chapterId,
        chapterName: chapterProgress.chapterName,
        completedLessons: chapterProgress.completedLessons,
        availableLessons: chapterProgress.availableLessons,
        quizAttempts: chapterProgress.quizAttempts,
        flashcardAttempts: {
          ...chapterProgress.flashcardAttempts,
          lessonId: updatedAttempts,
        },
        lastStudied: DateTime.now(),
        studyTimeMinutes: chapterProgress.studyTimeMinutes + flashcardAttempt.studyMinutes,
        isUnlocked: chapterProgress.isUnlocked,
      );

      // Add study session for flashcards
      final studySession = StudySession(
        startTime: flashcardAttempt.completedAt.subtract(
          Duration(seconds: flashcardAttempt.timeSpentSeconds),
        ),
        endTime: flashcardAttempt.completedAt,
        chapterId: chapterId,
        lessonId: lessonId,
        activity: 'flashcards',
        metadata: {
          'totalCards': flashcardAttempt.totalCards,
          'lessonName': flashcardAttempt.lessonName,
        },
      );

      final updatedProgress = progress.copyWith(
        lastStudied: DateTime.now(),
        totalStudyTimeMinutes: progress.totalStudyTimeMinutes + flashcardAttempt.studyMinutes,
        chapterProgress: {
          ...progress.chapterProgress,
          chapterId: updatedChapterProgress,
        },
        studySessions: [...progress.studySessions, studySession],
      );

      return await saveCourseProgress(updatedProgress);
    } catch (e) {
      Logger.e(_tag, 'Error saving flashcard attempt', error: e);
      return false;
    }
  }

  // Update available lessons for a chapter (when content is generated)
  Future<bool> updateAvailableLessons({
    required String courseId,
    required String chapterId,
    required Set<String> lessonIds,
  }) async {
    try {
      var progress = await getCourseProgress(courseId);
      if (progress == null) return false;

      final chapterProgress = progress.chapterProgress[chapterId];
      if (chapterProgress == null) return false;

      final updatedChapterProgress = ChapterProgress(
        chapterId: chapterProgress.chapterId,
        chapterName: chapterProgress.chapterName,
        completedLessons: chapterProgress.completedLessons,
        availableLessons: lessonIds,
        quizAttempts: chapterProgress.quizAttempts,
        flashcardAttempts: chapterProgress.flashcardAttempts,
        lastStudied: chapterProgress.lastStudied,
        studyTimeMinutes: chapterProgress.studyTimeMinutes,
        isUnlocked: chapterProgress.isUnlocked,
      );

      final updatedProgress = progress.copyWith(
        chapterProgress: {
          ...progress.chapterProgress,
          chapterId: updatedChapterProgress,
        },
      );

      return await saveCourseProgress(updatedProgress);
    } catch (e) {
      Logger.e(_tag, 'Error updating available lessons', error: e);
      return false;
    }
  }

  // Get study statistics for a course
  Future<Map<String, dynamic>> getStudyStats(String courseId) async {
    try {
      final progress = await getCourseProgress(courseId);
      if (progress == null) {
        return {
          'totalStudyTime': 0,
          'completedLessons': 0,
          'averageQuizScore': 0.0,
          'currentStreak': 0,
          'totalQuizzes': 0,
        };
      }

      return {
        'totalStudyTime': progress.totalStudyTimeMinutes,
        'completedLessons': progress.completedLessons,
        'averageQuizScore': progress.averageQuizScore,
        'currentStreak': progress.stats.currentStreak,
        'totalQuizzes': progress.totalQuizzesTaken,
        'totalFlashcardSessions': progress.totalFlashcardSessions,
        'overallProgress': progress.overallProgress,
      };
    } catch (e) {
      Logger.e(_tag, 'Error getting study stats', error: e);
      return {};
    }
  }

  // Clear all progress data (for testing/reset)
  Future<bool> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith(_progressKeyPrefix),
      );

      for (String key in keys) {
        await prefs.remove(key);
      }

      await prefs.remove(_allCoursesKey);
      Logger.i(_tag, 'Cleared all progress data');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Error clearing progress data', error: e);
      return false;
    }
  }

  // Helper to update the list of courses
  Future<void> _updateCoursesList(String courseId, String courseName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_allCoursesKey);

      List<Map<String, dynamic>> coursesList = [];
      if (coursesJson != null) {
        coursesList = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
      }

      // Remove existing entry if it exists
      coursesList.removeWhere((course) => course['courseId'] == courseId);

      // Add updated entry
      coursesList.add({
        'courseId': courseId,
        'courseName': courseName,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_allCoursesKey, jsonEncode(coursesList));
    } catch (e) {
      Logger.e(_tag, 'Error updating courses list', error: e);
    }
  }

  // Initialize or create progress for a new course
  Future<UserProgress> initializeCourseProgress({
    required String courseId,
    required String courseName,
    required Map<String, String> chapterNames, // chapterId -> chapterName
  }) async {
    var progress = await getCourseProgress(courseId);

    if (progress == null) {
      // Create new progress
      final chapterProgress = <String, ChapterProgress>{};

      for (var entry in chapterNames.entries) {
        chapterProgress[entry.key] = ChapterProgress(
          chapterId: entry.key,
          chapterName: entry.value,
          completedLessons: {},
          availableLessons: {},
          quizAttempts: {},
          flashcardAttempts: {},
          studyTimeMinutes: 0,
          isUnlocked: true, // For now, all chapters are unlocked
        );
      }

      progress = UserProgress(
        courseId: courseId,
        courseName: courseName,
        lastStudied: DateTime.now(),
        totalStudyTimeMinutes: 0,
        chapterProgress: chapterProgress,
        studySessions: [],
        stats: CourseStats(
          totalStudyDays: 0,
          currentStreak: 0,
          longestStreak: 0,
          weeklyActivity: {},
          achievements: [],
        ),
      );

      await saveCourseProgress(progress);
    }

    return progress;
  }
}
