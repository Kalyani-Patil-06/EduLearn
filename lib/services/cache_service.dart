import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';

class CacheService {
  static const String _assignmentsKey = 'cached_assignments';
  static const String _coursesKey = 'cached_courses';
  static const String _userStatsKey = 'cached_user_stats';
  static const String _lastSyncKey = 'last_sync_time';
  
  static Future<void> cacheAssignments(List<Assignment> assignments) async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = assignments.map((a) => a.toMap()).toList();
    await prefs.setString(_assignmentsKey, jsonEncode(assignmentsJson));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }
  
  static Future<List<Assignment>?> getCachedAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsString = prefs.getString(_assignmentsKey);
    
    if (assignmentsString == null) return null;
    
    try {
      final List<dynamic> assignmentsJson = jsonDecode(assignmentsString);
      return assignmentsJson.map((json) => Assignment.fromMap(json, json['id'])).toList();
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> cacheCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = courses.map((c) => c.toMap()).toList();
    await prefs.setString(_coursesKey, jsonEncode(coursesJson));
  }
  
  static Future<List<Course>?> getCachedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesString = prefs.getString(_coursesKey);
    
    if (coursesString == null) return null;
    
    try {
      final List<dynamic> coursesJson = jsonDecode(coursesString);
      return coursesJson.map((json) => Course.fromMap(json, json['id'])).toList();
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> cacheUserStats(Map<String, int> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStatsKey, jsonEncode(stats));
  }
  
  static Future<Map<String, int>?> getCachedUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsString = prefs.getString(_userStatsKey);
    
    if (statsString == null) return null;
    
    try {
      final Map<String, dynamic> statsJson = jsonDecode(statsString);
      return statsJson.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return null;
    }
  }
  
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    
    if (lastSyncString == null) return null;
    
    try {
      return DateTime.parse(lastSyncString);
    } catch (e) {
      return null;
    }
  }
  
  static Future<bool> isCacheExpired({Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }
  
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_assignmentsKey);
    await prefs.remove(_coursesKey);
    await prefs.remove(_userStatsKey);
    await prefs.remove(_lastSyncKey);
  }
}