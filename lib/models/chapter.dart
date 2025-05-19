import 'lesson.dart';
import 'section.dart';

class Chapter {
  final String id;
  final String title;
  final String description;
  final String time;
  final List<Lesson> lessons;

  Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.lessons,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    List<Lesson> parsedLessons = [];

    // Parse lessons if available
    if (json['lessons'] != null) {
      try {
        parsedLessons =
            (json['lessons'] as List).map((lessonJson) {
              // Add sectionId (chapterId) to the lesson data if not present
              if (!lessonJson.containsKey('sectionId') &&
                  !lessonJson.containsKey('section_id')) {
                lessonJson['section_id'] = json['id'] ?? '';
              }

              return Lesson.fromJson(lessonJson);
            }).toList();
      } catch (e) {
        print('Error parsing chapter lessons: $e');
      }
    }

    return Chapter(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Chapter',
      description: json['description']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
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

  // Convert Chapter to Section for compatibility with existing code
  Section toSection() {
    return Section(
      id: id,
      title: title,
      description: description,
      time: time,
      lessons: lessons,
    );
  }
}
