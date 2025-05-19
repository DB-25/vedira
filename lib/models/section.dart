import 'lesson.dart';

class Section {
  final String id;
  final String title;
  final String description;
  final String time;
  final List<Lesson> lessons;

  Section({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.lessons,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    List<Lesson> parsedLessons = [];

    // Parse lessons if available
    if (json['lessons'] != null) {
      try {
        parsedLessons =
            (json['lessons'] as List)
                .map((lessonJson) => Lesson.fromJson(lessonJson))
                .toList();
      } catch (e) {
        print('Error parsing section lessons: $e');
      }
    }

    return Section(
      id: json['id']?.toString() ?? json['section_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Section',
      description: json['description']?.toString() ?? '',
      time: json['time']?.toString() ?? json['duration']?.toString() ?? '',
      lessons: parsedLessons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    };
  }

  // Create a copy of this section with modified fields
  Section copyWith({
    String? id,
    String? title,
    String? description,
    String? time,
    List<Lesson>? lessons,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      lessons: lessons ?? this.lessons,
    );
  }
}
