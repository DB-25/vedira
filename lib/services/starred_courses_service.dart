import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class StarredCoursesService {
  static const String _tag = 'StarredCoursesService';
  static const String _starredCoursesKey = 'starred_courses';
  
  // Singleton pattern
  static StarredCoursesService? _instance;
  static StarredCoursesService get instance {
    _instance ??= StarredCoursesService._internal();
    return _instance!;
  }
  
  StarredCoursesService._internal();
  
  /// Get all starred course IDs
  Future<Set<String>> getStarredCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredList = prefs.getStringList(_starredCoursesKey) ?? [];
      Logger.d(_tag, 'Retrieved ${starredList.length} starred courses');
      return starredList.toSet();
    } catch (e) {
      Logger.e(_tag, 'Error retrieving starred courses', error: e);
      return <String>{};
    }
  }
  
  /// Check if a course is starred
  Future<bool> isStarred(String courseId) async {
    if (courseId.isEmpty) {
      Logger.w(_tag, 'Empty courseId provided to isStarred');
      return false;
    }
    
    try {
      final starredCourses = await getStarredCourses();
      final isStarred = starredCourses.contains(courseId);
      Logger.v(_tag, 'Course $courseId is${isStarred ? '' : ' not'} starred');
      return isStarred;
    } catch (e) {
      Logger.e(_tag, 'Error checking if course is starred', error: e);
      return false;
    }
  }
  
  /// Star a course
  Future<bool> starCourse(String courseId) async {
    if (courseId.isEmpty) {
      Logger.w(_tag, 'Empty courseId provided to starCourse');
      return false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCourses = await getStarredCourses();
      
      if (starredCourses.contains(courseId)) {
        Logger.i(_tag, 'Course $courseId is already starred');
        return true; // Already starred
      }
      
      starredCourses.add(courseId);
      final success = await prefs.setStringList(_starredCoursesKey, starredCourses.toList());
      
      if (success) {
        Logger.i(_tag, 'Successfully starred course: $courseId');
      } else {
        Logger.e(_tag, 'Failed to save starred course: $courseId');
      }
      
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error starring course: $courseId', error: e);
      return false;
    }
  }
  
  /// Unstar a course
  Future<bool> unstarCourse(String courseId) async {
    if (courseId.isEmpty) {
      Logger.w(_tag, 'Empty courseId provided to unstarCourse');
      return false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final starredCourses = await getStarredCourses();
      
      if (!starredCourses.contains(courseId)) {
        Logger.i(_tag, 'Course $courseId is not starred');
        return true; // Already not starred
      }
      
      starredCourses.remove(courseId);
      final success = await prefs.setStringList(_starredCoursesKey, starredCourses.toList());
      
      if (success) {
        Logger.i(_tag, 'Successfully unstarred course: $courseId');
      } else {
        Logger.e(_tag, 'Failed to save unstarred course: $courseId');
      }
      
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error unstarring course: $courseId', error: e);
      return false;
    }
  }
  
  /// Toggle star status of a course
  Future<bool> toggleStar(String courseId) async {
    if (courseId.isEmpty) {
      Logger.w(_tag, 'Empty courseId provided to toggleStar');
      return false;
    }
    
    try {
      final isCurrentlyStarred = await isStarred(courseId);
      
      if (isCurrentlyStarred) {
        Logger.d(_tag, 'Unstarring course: $courseId');
        return await unstarCourse(courseId);
      } else {
        Logger.d(_tag, 'Starring course: $courseId');
        return await starCourse(courseId);
      }
    } catch (e) {
      Logger.e(_tag, 'Error toggling star for course: $courseId', error: e);
      return false;
    }
  }
  
  /// Get count of starred courses
  Future<int> getStarredCoursesCount() async {
    try {
      final starredCourses = await getStarredCourses();
      final count = starredCourses.length;
      Logger.d(_tag, 'Total starred courses: $count');
      return count;
    } catch (e) {
      Logger.e(_tag, 'Error getting starred courses count', error: e);
      return 0;
    }
  }
  
  /// Clear all starred courses (for testing or user preference)
  Future<bool> clearAllStarredCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_starredCoursesKey);
      
      if (success) {
        Logger.i(_tag, 'Successfully cleared all starred courses');
      } else {
        Logger.e(_tag, 'Failed to clear starred courses');
      }
      
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error clearing starred courses', error: e);
      return false;
    }
  }
} 