import 'package:flutter/material.dart';

class UserProgress {
  final String courseId;
  final String courseName;
  final DateTime lastStudied;
  final int totalStudyTimeMinutes;
  final Map<String, ChapterProgress> chapterProgress;
  final List<StudySession> studySessions;
  final CourseStats stats;

  UserProgress({
    required this.courseId,
    required this.courseName,
    required this.lastStudied,
    required this.totalStudyTimeMinutes,
    required this.chapterProgress,
    required this.studySessions,
    required this.stats,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      lastStudied:
          DateTime.tryParse(json['lastStudied'] ?? '') ?? DateTime.now(),
      totalStudyTimeMinutes: json['totalStudyTimeMinutes'] ?? 0,
      chapterProgress: (json['chapterProgress'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, ChapterProgress.fromJson(value))),
      studySessions:
          (json['studySessions'] as List? ?? [])
              .map((session) => StudySession.fromJson(session))
              .toList(),
      stats: CourseStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'lastStudied': lastStudied.toIso8601String(),
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
      'chapterProgress': chapterProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'studySessions':
          studySessions.map((session) => session.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }

  // Helper methods
  double get overallProgress {
    if (chapterProgress.isEmpty) return 0.0;

    double totalProgress = chapterProgress.values
        .map((chapter) => chapter.completionPercentage)
        .reduce((a, b) => a + b);

    return totalProgress / chapterProgress.length;
  }

  int get completedLessons {
    return chapterProgress.values
        .map((chapter) => chapter.completedLessons.length)
        .fold(0, (sum, count) => sum + count);
  }

  int get totalQuizzesTaken {
    return chapterProgress.values
        .map((chapter) => chapter.quizAttempts.length)
        .fold(0, (sum, count) => sum + count);
  }

  int get totalFlashcardSessions {
    return chapterProgress.values
        .map((chapter) => chapter.getTotalFlashcardSessions())
        .fold(0, (sum, count) => sum + count);
  }

  double get averageQuizScore {
    List<double> bestScores = [];

    for (var chapter in chapterProgress.values) {
      for (var lessonId in chapter.quizAttempts.keys) {
        final attempts = chapter.quizAttempts[lessonId]!;
        if (attempts.isNotEmpty) {
          // Find the best score for this lesson
          final bestScore = attempts
              .map((attempt) => attempt.scorePercentage)
              .reduce((a, b) => a > b ? a : b);
          bestScores.add(bestScore);
        }
      }
    }

    if (bestScores.isEmpty) return 0.0;
    return bestScores.reduce((a, b) => a + b) / bestScores.length;
  }

  UserProgress copyWith({
    String? courseId,
    String? courseName,
    DateTime? lastStudied,
    int? totalStudyTimeMinutes,
    Map<String, ChapterProgress>? chapterProgress,
    List<StudySession>? studySessions,
    CourseStats? stats,
  }) {
    return UserProgress(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      lastStudied: lastStudied ?? this.lastStudied,
      totalStudyTimeMinutes:
          totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      chapterProgress: chapterProgress ?? this.chapterProgress,
      studySessions: studySessions ?? this.studySessions,
      stats: stats ?? this.stats,
    );
  }
}

class ChapterProgress {
  final String chapterId;
  final String chapterName;
  final Set<String> completedLessons;
  final Set<String> availableLessons;
  final Map<String, List<QuizAttempt>> quizAttempts; // lessonId -> attempts
  final Map<String, List<FlashcardAttempt>> flashcardAttempts; // lessonId -> attempts
  final DateTime? lastStudied;
  final int studyTimeMinutes;
  final bool isUnlocked;

  ChapterProgress({
    required this.chapterId,
    required this.chapterName,
    required this.completedLessons,
    required this.availableLessons,
    required this.quizAttempts,
    required this.flashcardAttempts,
    this.lastStudied,
    required this.studyTimeMinutes,
    required this.isUnlocked,
  });

  factory ChapterProgress.fromJson(Map<String, dynamic> json) {
    return ChapterProgress(
      chapterId: json['chapterId'] ?? '',
      chapterName: json['chapterName'] ?? '',
      completedLessons: Set<String>.from(json['completedLessons'] ?? []),
      availableLessons: Set<String>.from(json['availableLessons'] ?? []),
      quizAttempts: (json['quizAttempts'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((attempt) => QuizAttempt.fromJson(attempt))
              .toList(),
        ),
      ),
      flashcardAttempts: (json['flashcardAttempts'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((attempt) => FlashcardAttempt.fromJson(attempt))
              .toList(),
        ),
      ),
      lastStudied:
          json['lastStudied'] != null
              ? DateTime.tryParse(json['lastStudied'])
              : null,
      studyTimeMinutes: json['studyTimeMinutes'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'chapterName': chapterName,
      'completedLessons': completedLessons.toList(),
      'availableLessons': availableLessons.toList(),
      'quizAttempts': quizAttempts.map(
        (key, value) =>
            MapEntry(key, value.map((attempt) => attempt.toJson()).toList()),
      ),
      'flashcardAttempts': flashcardAttempts.map(
        (key, value) =>
            MapEntry(key, value.map((attempt) => attempt.toJson()).toList()),
      ),
      'lastStudied': lastStudied?.toIso8601String(),
      'studyTimeMinutes': studyTimeMinutes,
      'isUnlocked': isUnlocked,
    };
  }

  double get completionPercentage {
    if (availableLessons.isEmpty) return 0.0;
    return (completedLessons.length / availableLessons.length) * 100;
  }

  QuizAttempt? getBestQuizScore(String lessonId) {
    final attempts = quizAttempts[lessonId];
    if (attempts == null || attempts.isEmpty) return null;

    return attempts.reduce(
      (best, current) =>
          current.scorePercentage > best.scorePercentage ? current : best,
    );
  }

  bool isLessonCompleted(String lessonId) {
    return completedLessons.contains(lessonId);
  }

  bool hasQuizAttempt(String lessonId) {
    return quizAttempts.containsKey(lessonId) &&
        quizAttempts[lessonId]!.isNotEmpty;
  }

  bool hasFlashcardAttempt(String lessonId) {
    return flashcardAttempts.containsKey(lessonId) &&
        flashcardAttempts[lessonId]!.isNotEmpty;
  }

  FlashcardAttempt? getLatestFlashcardAttempt(String lessonId) {
    final attempts = flashcardAttempts[lessonId];
    if (attempts == null || attempts.isEmpty) return null;

    return attempts.reduce(
      (latest, current) =>
          current.completedAt.isAfter(latest.completedAt) ? current : latest,
    );
  }

  int getTotalFlashcardSessions() {
    return flashcardAttempts.values
        .map((attempts) => attempts.length)
        .fold(0, (sum, count) => sum + count);
  }
}

class QuizAttempt {
  final String lessonId;
  final String lessonName;
  final int score;
  final int totalQuestions;
  final double scorePercentage;
  final DateTime completedAt;
  final int timeSpentSeconds;
  final Map<int, int> answers; // questionIndex -> selectedOption
  final Map<int, bool> correctAnswers; // questionIndex -> isCorrect

  QuizAttempt({
    required this.lessonId,
    required this.lessonName,
    required this.score,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.completedAt,
    required this.timeSpentSeconds,
    required this.answers,
    required this.correctAnswers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      lessonId: json['lessonId'] ?? '',
      lessonName: json['lessonName'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      scorePercentage: (json['scorePercentage'] ?? 0).toDouble(),
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      answers: (json['answers'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
      correctAnswers: (json['correctAnswers'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(int.parse(key), value as bool)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'score': score,
      'totalQuestions': totalQuestions,
      'scorePercentage': scorePercentage,
      'completedAt': completedAt.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
      'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      'correctAnswers': correctAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  String get gradeString {
    if (scorePercentage >= 90) return 'A';
    if (scorePercentage >= 80) return 'B';
    if (scorePercentage >= 70) return 'C';
    if (scorePercentage >= 60) return 'D';
    return 'F';
  }

  Color get gradeColor {
    if (scorePercentage >= 90) return const Color(0xFF4CAF50); // Green
    if (scorePercentage >= 80) return const Color(0xFF8BC34A); // Light Green
    if (scorePercentage >= 70) return const Color(0xFFFF9800); // Orange
    if (scorePercentage >= 60) return const Color(0xFFFF5722); // Deep Orange
    return const Color(0xFFF44336); // Red
  }
}

class FlashcardAttempt {
  final String lessonId;
  final String lessonName;
  final int totalCards;
  final DateTime completedAt;
  final int timeSpentSeconds;
  final Map<String, dynamic> metadata; // Extra data like cards reviewed, etc.

  FlashcardAttempt({
    required this.lessonId,
    required this.lessonName,
    required this.totalCards,
    required this.completedAt,
    required this.timeSpentSeconds,
    required this.metadata,
  });

  factory FlashcardAttempt.fromJson(Map<String, dynamic> json) {
    return FlashcardAttempt(
      lessonId: json['lessonId'] ?? '',
      lessonName: json['lessonName'] ?? '',
      totalCards: json['totalCards'] ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'totalCards': totalCards,
      'completedAt': completedAt.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
      'metadata': metadata,
    };
  }

  int get studyMinutes {
    return (timeSpentSeconds / 60).ceil();
  }
}

class StudySession {
  final DateTime startTime;
  final DateTime endTime;
  final String chapterId;
  final String lessonId;
  final String activity; // 'reading', 'quiz', 'flashcards', 'review'
  final Map<String, dynamic> metadata; // Extra data like quiz score, etc.

  StudySession({
    required this.startTime,
    required this.endTime,
    required this.chapterId,
    required this.lessonId,
    required this.activity,
    required this.metadata,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      chapterId: json['chapterId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      activity: json['activity'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'chapterId': chapterId,
      'lessonId': lessonId,
      'activity': activity,
      'metadata': metadata,
    };
  }

  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}

class CourseStats {
  final int totalStudyDays;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final Map<String, int> weeklyActivity; // 'Mon' -> minutes
  final List<Achievement> achievements;

  CourseStats({
    required this.totalStudyDays,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    required this.weeklyActivity,
    required this.achievements,
  });

  factory CourseStats.fromJson(Map<String, dynamic> json) {
    return CourseStats(
      totalStudyDays: json['totalStudyDays'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastStudyDate:
          json['lastStudyDate'] != null
              ? DateTime.tryParse(json['lastStudyDate'])
              : null,
      weeklyActivity: Map<String, int>.from(json['weeklyActivity'] ?? {}),
      achievements:
          (json['achievements'] as List? ?? [])
              .map((achievement) => Achievement.fromJson(achievement))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudyDays': totalStudyDays,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'weeklyActivity': weeklyActivity,
      'achievements':
          achievements.map((achievement) => achievement.toJson()).toList(),
    };
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final bool isSecret;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    required this.isSecret,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'trophy',
      unlockedAt: DateTime.tryParse(json['unlockedAt'] ?? '') ?? DateTime.now(),
      isSecret: json['isSecret'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'unlockedAt': unlockedAt.toIso8601String(),
      'isSecret': isSecret,
    };
  }
}
