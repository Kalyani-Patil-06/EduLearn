import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String duration;
  final int lessons;
  final int students;
  final String category;
  final String level;
  final String iconName; // Store icon name as string
  final String colorValue; // Store color as hex string
  final String? imageUrl; // Add image URL field (optional)

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.duration,
    required this.lessons,
    required this.students,
    required this.category,
    required this.level,
    required this.iconName,
    required this.colorValue,
    this.imageUrl, // Optional image
  });

  // Convert Course to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'duration': duration,
      'lessons': lessons,
      'students': students,
      'category': category,
      'level': level,
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }

  // Create Course from Firestore document
  factory Course.fromMap(Map<String, dynamic> map, String documentId) {
    return Course(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      duration: map['duration'] ?? '',
      lessons: map['lessons'] ?? 0,
      students: map['students'] ?? 0,
      category: map['category'] ?? '',
      level: map['level'] ?? '',
      iconName: map['iconName'] ?? 'school',
      colorValue: map['colorValue'] ?? 'FF6C63FF',
    );
  }

  // Create Course from Firestore DocumentSnapshot
  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course.fromMap(data, doc.id);
  }
}

class UserEnrollment {
  final String courseId;
  final DateTime enrolledAt;
  final double progress;
  final int completedLessons;
  final DateTime? lastAccessedAt;

  UserEnrollment({
    required this.courseId,
    required this.enrolledAt,
    this.progress = 0.0,
    this.completedLessons = 0,
    this.lastAccessedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'progress': progress,
      'completedLessons': completedLessons,
      'lastAccessedAt': lastAccessedAt != null 
          ? Timestamp.fromDate(lastAccessedAt!) 
          : null,
    };
  }

  factory UserEnrollment.fromMap(Map<String, dynamic> map) {
    return UserEnrollment(
      courseId: map['courseId'] ?? '',
      enrolledAt: (map['enrolledAt'] as Timestamp).toDate(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      completedLessons: map['completedLessons'] ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? (map['lastAccessedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int totalMarks;
  final String status; // pending, submitted, graded

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.totalMarks,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'totalMarks': totalMarks,
      'status': status,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, String documentId) {
    return Assignment(
      id: documentId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      totalMarks: map['totalMarks'] ?? 0,
      status: map['status'] ?? 'pending',
    );
  }

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Assignment.fromMap(data, doc.id);
  }
}