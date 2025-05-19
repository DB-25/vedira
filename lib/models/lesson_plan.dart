import 'chapter.dart';
import 'course.dart';
import 'dart:developer' as developer;

class LessonPlan {
  final String courseID;
  final String title;
  final String description;
  final String userID;
  final List<Chapter> chapters;

  LessonPlan({
    required this.courseID,
    required this.title,
    required this.description,
    required this.userID,
    required this.chapters,
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

    return LessonPlan(
      courseID: rawCourseId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      userID: json['UserID'] ?? json['userID'] ?? json['user_id'] ?? '',
      chapters: parsedChapters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CourseID': courseID,
      'title': title,
      'description': description,
      'UserID': userID,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
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
      sections: chapters.map((chapter) => chapter.toSection()).toList(),
    );
  }
}
