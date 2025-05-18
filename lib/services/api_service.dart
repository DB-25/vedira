import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/lesson.dart';

class ApiService {
  // Base URL for the API
  final String baseUrl =
      'https://rgml14alw6.execute-api.us-east-1.amazonaws.com';

  // API endpoints
  String get courseListEndpoint => '$baseUrl/get-course-list';

  // Get all courses from API
  Future<List<Course>> getCourseList({String userId = 'rs'}) async {
    try {
      final response = await http.get(
        Uri.parse('$courseListEndpoint?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((courseJson) => Course.fromJson(courseJson)).toList();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  // Get all courses (mock implementation kept for reference)
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
    // In a real implementation, you would fetch a single course from the API
    // For now, we'll get all courses and find the one we need
    final courses = await getCourseList();
    try {
      return courses.firstWhere((course) => course.courseID == id);
    } catch (e) {
      throw Exception('Course not found with ID: $id');
    }
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
