import 'package:diacritic/diacritic.dart';
import '../models/course_model.dart';

class SearchService {
  static List<Assignment> searchAssignments(List<Assignment> assignments, String query) {
    if (query.isEmpty) return assignments;
    
    final normalizedQuery = removeDiacritics(query.toLowerCase());
    
    return assignments.where((assignment) {
      final title = removeDiacritics(assignment.title.toLowerCase());
      final description = removeDiacritics(assignment.description.toLowerCase());
      final status = removeDiacritics(assignment.status.toLowerCase());
      
      return title.contains(normalizedQuery) ||
             description.contains(normalizedQuery) ||
             status.contains(normalizedQuery);
    }).toList();
  }
  
  static List<Course> searchCourses(List<Course> courses, String query) {
    if (query.isEmpty) return courses;
    
    final normalizedQuery = removeDiacritics(query.toLowerCase());
    
    return courses.where((course) {
      final title = removeDiacritics(course.title.toLowerCase());
      final description = removeDiacritics(course.description.toLowerCase());
      final instructor = removeDiacritics(course.instructor.toLowerCase());
      final category = removeDiacritics(course.category.toLowerCase());
      
      return title.contains(normalizedQuery) ||
             description.contains(normalizedQuery) ||
             instructor.contains(normalizedQuery) ||
             category.contains(normalizedQuery);
    }).toList();
  }
  
  static List<String> getSearchSuggestions(List<Assignment> assignments, String query) {
    if (query.isEmpty) return [];
    
    final suggestions = <String>{};
    final normalizedQuery = removeDiacritics(query.toLowerCase());
    
    for (final assignment in assignments) {
      final words = assignment.title.split(' ');
      for (final word in words) {
        final normalizedWord = removeDiacritics(word.toLowerCase());
        if (normalizedWord.startsWith(normalizedQuery) && normalizedWord != normalizedQuery) {
          suggestions.add(word);
        }
      }
    }
    
    return suggestions.take(5).toList();
  }
}