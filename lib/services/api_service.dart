import '../models/course.dart';

class ApiService {
  final String baseUrl = 'https://api.example.com'; // Placeholder URL

  // Get all courses
  Future<List<Course>> getCourses() async {
    // This is just a placeholder implementation
    // In a real app, this would make an actual API call

    // Mock response
    final response = {
      'courses': [
        {
          'id': '1',
          'title': 'Flutter Basics',
          'description': 'Learn the basics of Flutter development',
          'author': 'John Doe',
          'createdAt': DateTime.now().toIso8601String(),
          'lessons': [
            {
              'id': '1',
              'title': 'Introduction to Flutter',
              'content': 'Flutter is a UI toolkit...',
              'resources': ['https://flutter.dev'],
              'order': 1,
              'sectionId': '1',
            },
          ],
        },
      ],
    };

    // Convert the mock response to Course objects
    List<Course> courses =
        (response['courses'] as List)
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

    return courses;
  }

  // Get a specific course
  Future<Course> getCourse(String id) async {
    // Placeholder implementation
    return getCourses().then(
      (courses) => courses.firstWhere((course) => course.id == id),
    );
  }

  // Create a new course
  Future<Course> createCourse(Course course) async {
    // Placeholder implementation
    return course;
  }

  // Update a course
  Future<Course> updateCourse(Course course) async {
    // Placeholder implementation
    return course;
  }

  // Delete a course
  Future<bool> deleteCourse(String id) async {
    // Placeholder implementation
    return true;
  }
}
