import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String instructorId;
  final String duration;
  final int lessons;
  final int students;
  final String category;
  final String level;
  final String iconName;
  final String colorValue;
  final String? imageUrl; // Optional - can be null
  final double averageRating;
  final int totalRatings;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.instructorId,
    required this.duration,
    required this.lessons,
    required this.students,
    required this.category,
    required this.level,
    required this.iconName,
    required this.colorValue,
    this.imageUrl, // Optional
    this.averageRating = 0.0,
    this.totalRatings = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'instructorId': instructorId,
      'duration': duration,
      'lessons': lessons,
      'students': students,
      'category': category,
      'level': level,
      'iconName': iconName,
      'colorValue': colorValue,
      'imageUrl': imageUrl, // Can be null
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String documentId) {
    return Course(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      instructorId: map['instructorId'] ?? '',
      duration: map['duration'] ?? '',
      lessons: map['lessons'] ?? 0,
      students: map['students'] ?? 0,
      category: map['category'] ?? '',
      level: map['level'] ?? '',
      iconName: map['iconName'] ?? 'school',
      colorValue: map['colorValue'] ?? '6C63FF',
      imageUrl: map['imageUrl'], // Can be null
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
    );
  }

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course.fromMap(data, doc.id);
  }
}

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final String duration;
  final int order;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'order': order,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map, String documentId) {
    return Lesson(
      id: documentId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      duration: map['duration'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lesson.fromMap(data, doc.id);
  }
}

class UserEnrollment {
  final String courseId;
  final DateTime enrolledAt;
  final double progress;
  final int completedLessons;
  final DateTime? lastAccessedAt;
  final List<String> completedLessonIds;

  UserEnrollment({
    required this.courseId,
    required this.enrolledAt,
    this.progress = 0.0,
    this.completedLessons = 0,
    this.lastAccessedAt,
    this.completedLessonIds = const [],
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
      'completedLessonIds': completedLessonIds,
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
      completedLessonIds: List<String>.from(map['completedLessonIds'] ?? []),
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
  final String createdBy;
  final String status;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.totalMarks,
    required this.createdBy,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'totalMarks': totalMarks,
      'createdBy': createdBy,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
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
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Assignment.fromMap(data, doc.id);
  }
}

class Submission {
  final String id;
  final String userId;
  final String assignmentId;
  final String courseId;
  final String submissionText;
  final DateTime submittedAt;
  final String status;
  final int? marks;
  final String? feedback;
  final String studentName;
  final String studentEmail;

  Submission({
    required this.id,
    required this.userId,
    required this.assignmentId,
    required this.courseId,
    required this.submissionText,
    required this.submittedAt,
    this.status = 'pending',
    this.marks,
    this.feedback,
    this.studentName = '',
    this.studentEmail = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'assignmentId': assignmentId,
      'courseId': courseId,
      'submissionText': submissionText,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'marks': marks,
      'feedback': feedback,
      'studentName': studentName,
      'studentEmail': studentEmail,
    };
  }

  factory Submission.fromMap(Map<String, dynamic> map, String documentId) {
    return Submission(
      id: documentId,
      userId: map['userId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      courseId: map['courseId'] ?? '',
      submissionText: map['submissionText'] ?? '',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      marks: map['marks'],
      feedback: map['feedback'],
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
    );
  }

  factory Submission.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Submission.fromMap(data, doc.id);
  }
}