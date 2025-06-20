import 'chapter.dart';
import 'course.dart';
import 'chapter_status.dart';
import 'dart:developer' as developer;

class LessonPlan {
  final String courseID;
  final String title;
  final String description;
  final String userID;
  final String? coverImageUrl;
  final List<Chapter> chapters;
  final Map<String, ChapterStatus> chaptersStatus;

  LessonPlan({
    required this.courseID,
    required this.title,
    required this.description,
    required this.userID,
    this.coverImageUrl,
    required this.chapters,
    this.chaptersStatus = const {},
  });

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    // Debug the courseID field
    final rawCourseId =
        json['CourseID'] ?? json['courseID'] ?? json['course_id'] ?? '';
    developer.log(
      'Parsing LessonPlan.fromJson - Raw Course ID: $rawCourseId',
      name: 'LessonPlan',
    );

    if (rawCourseId == '') {
      developer.log(
        'WARNING: Empty Course ID detected in LessonPlan.fromJson',
        name: 'LessonPlan',
      );
      developer.log(
        'JSON keys available: ${json.keys.toList()}',
        name: 'LessonPlan',
      );
    }

    List<Chapter> parsedChapters = [];

    // Parse chapters if available
    if (json['chapters'] != null) {
      try {
        parsedChapters =
            (json['chapters'] as List)
                .map((chapter) => Chapter.fromJson(chapter))
                .toList();
      } catch (e) {
        developer.log('Error parsing chapters: $e', name: 'LessonPlan');
      }
    }

    // Parse chapters_status if available
    Map<String, ChapterStatus> parsedChaptersStatus = {};
    if (json['chapters_status'] != null && json['chapters_status'] is Map) {
      try {
        final statusMap = json['chapters_status'] as Map<String, dynamic>;
        statusMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            parsedChaptersStatus[key] = ChapterStatus.fromJson(value);
          }
        });
        developer.log(
          'Parsed chapters_status for ${parsedChaptersStatus.length} chapters',
          name: 'LessonPlan',
        );
      } catch (e) {
        developer.log('Error parsing chapters_status: $e', name: 'LessonPlan');
      }
    }

    return LessonPlan(
      courseID: rawCourseId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      userID: json['UserID'] ?? json['userID'] ?? json['user_id'] ?? '',
      coverImageUrl:
          json['cover_image_url']?.toString().isEmpty == true
              ? null
              : json['cover_image_url']?.toString(),
      chapters: parsedChapters,
      chaptersStatus: parsedChaptersStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CourseID': courseID,
      'title': title,
      'description': description,
      'UserID': userID,
      'cover_image_url': coverImageUrl,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'chapters_status': chaptersStatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  // Convert LessonPlan to Course for compatibility with existing code
  Course toCourse() {
    // Debug the courseID during conversion
    developer.log(
      'Converting LessonPlan to Course - CourseID: $courseID',
      name: 'LessonPlan',
    );

    if (courseID.isEmpty) {
      developer.log(
        'WARNING: Empty CourseID detected during LessonPlan.toCourse() conversion',
        name: 'LessonPlan',
      );
    }

    return Course(
      courseID: courseID,
      title: title,
      description: description,
      author: userID,
      coverImageUrl: coverImageUrl,
      sections: chapters.map((chapter) => chapter.toSection()).toList(),
      chaptersStatus: chaptersStatus,
    );
  }

  // Get status for a specific chapter
  ChapterStatus? getChapterStatus(String chapterId) {
    return chaptersStatus[chapterId];
  }

  // Check if any chapters are currently generating
  bool get hasGeneratingChapters {
    return chaptersStatus.values.any((status) => status.isGenerating);
  }

  // Create a copy with updated fields
  LessonPlan copyWith({
    String? courseID,
    String? title,
    String? description,
    String? userID,
    String? coverImageUrl,
    List<Chapter>? chapters,
    Map<String, ChapterStatus>? chaptersStatus,
  }) {
    return LessonPlan(
      courseID: courseID ?? this.courseID,
      title: title ?? this.title,
      description: description ?? this.description,
      userID: userID ?? this.userID,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      chapters: chapters ?? this.chapters,
      chaptersStatus: chaptersStatus ?? this.chaptersStatus,
    );
  }
}
