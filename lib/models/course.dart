import 'lesson.dart';
import 'section.dart';
import 'chapter_status.dart';
import 'dart:developer' as developer;

class Course {
  final String courseID;
  final String title;
  final String description;
  final String author;
  final List<Lesson>? lessons;
  final List<Section>? sections;
  final DateTime? createdAt;
  final bool isGenerating;
  final Map<String, ChapterStatus> chaptersStatus;

  Course({
    required this.courseID,
    required this.title,
    required this.description,
    required this.author,
    this.lessons,
    this.sections,
    this.createdAt,
    this.isGenerating = false,
    this.chaptersStatus = const {},
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Debug the courseID field
    final rawCourseId =
        json['CourseID'] ?? json['courseID'] ?? json['course_id'] ?? '';
    developer.log(
      'Parsing Course.fromJson - Raw Course ID: $rawCourseId',
      name: 'Course',
    );

    if (rawCourseId == '') {
      developer.log(
        'WARNING: Empty Course ID detected in Course.fromJson',
        name: 'Course',
      );
      developer.log(
        'JSON keys available: ${json.keys.toList()}',
        name: 'Course',
      );
      developer.log('Full JSON: $json', name: 'Course');
    }

    List<Lesson>? parsedLessons;
    List<Section>? parsedSections;

    // Parse lessons if available
    if (json['lessons'] != null) {
      try {
        parsedLessons =
            (json['lessons'] as List)
                .map((lesson) => Lesson.fromJson(lesson))
                .toList();
      } catch (e) {
        developer.log('Error parsing lessons: $e', name: 'Course');
        parsedLessons = [];
      }
    }

    // Parse sections if available
    if (json['sections'] != null) {
      try {
        parsedSections =
            (json['sections'] as List)
                .map((section) => Section.fromJson(section))
                .toList();
      } catch (e) {
        developer.log('Error parsing sections: $e', name: 'Course');
        parsedSections = [];
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
          name: 'Course',
        );
      } catch (e) {
        developer.log('Error parsing chapters_status: $e', name: 'Course');
      }
    }

    return Course(
      courseID: rawCourseId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author:
          json['author'] ??
          json['UserID'] ??
          json['userID'] ??
          json['user_id'] ??
          'Unknown',
      lessons: parsedLessons,
      sections: parsedSections,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      isGenerating: json['isGenerating'] ?? json['is_generating'] ?? false,
      chaptersStatus: parsedChaptersStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseID': courseID,
      'title': title,
      'description': description,
      'author': author,
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
      'sections': sections?.map((section) => section.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'isGenerating': isGenerating,
      'chapters_status': chaptersStatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  // Create a copy of this course with modified fields
  Course copyWith({
    String? courseID,
    String? title,
    String? description,
    String? author,
    List<Lesson>? lessons,
    List<Section>? sections,
    DateTime? createdAt,
    bool? isGenerating,
    Map<String, ChapterStatus>? chaptersStatus,
  }) {
    return Course(
      courseID: courseID ?? this.courseID,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      lessons: lessons ?? this.lessons,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      isGenerating: isGenerating ?? this.isGenerating,
      chaptersStatus: chaptersStatus ?? this.chaptersStatus,
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
}
