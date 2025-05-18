import 'lesson.dart';

class Course {
  final String courseID;
  final String title;
  final String description;
  final String author;
  final List<Lesson>? lessons;
  final DateTime? createdAt;

  Course({
    required this.courseID,
    required this.title,
    required this.description,
    required this.author,
    this.lessons,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseID: json['courseID'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: json['author'] ?? 'Unknown',
      lessons:
          json['lessons'] != null
              ? (json['lessons'] as List)
                  .map((lesson) => Lesson.fromJson(lesson))
                  .toList()
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseID': courseID,
      'title': title,
      'description': description,
      'author': author,
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
