import 'lesson.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;
  final String author;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.author,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lessons:
          (json['lessons'] as List)
              .map((lesson) => Lesson.fromJson(lesson))
              .toList(),
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
