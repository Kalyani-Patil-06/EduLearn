import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUserId == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String name, String studentId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('users').doc(currentUserId).update({
        'name': name,
        'studentId': studentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // ==================== COURSE OPERATIONS ====================

  // Get all courses
  Stream<List<Course>> getCoursesStream() {
    return _firestore
        .collection('courses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList());
  }

  // Get courses by category
  Stream<List<Course>> getCoursesByCategory(String category) {
    if (category == 'All') {
      return getCoursesStream();
    }
    
    return _firestore
        .collection('courses')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList());
  }

  // Get single course
  Future<Course?> getCourse(String courseId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      
      if (doc.exists) {
        return Course.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  // ==================== ENROLLMENT OPERATIONS ====================

  // Enroll in course
  Future<bool> enrollInCourse(String courseId) async {
    try {
      if (currentUserId == null) return false;

      UserEnrollment enrollment = UserEnrollment(
        courseId: courseId,
        enrolledAt: DateTime.now(),
        progress: 0.0,
        completedLessons: 0,
        lastAccessedAt: DateTime.now(),
      );

      // Use a batch write to ensure both operations succeed or fail together
      WriteBatch batch = _firestore.batch();

      // Add to user's enrollments subcollection
      DocumentReference enrollmentRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId);
      
      batch.set(enrollmentRef, enrollment.toMap());

      // Increment student count in course
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      batch.update(courseRef, {
        'students': FieldValue.increment(1),
      });

      // Commit the batch
      await batch.commit();

      print('Successfully enrolled in course: $courseId');
      return true;
    } catch (e) {
      print('Error enrolling in course: $e');
      return false;
    }
  }

  // Check if enrolled in course
  Future<bool> isEnrolledInCourse(String courseId) async {
    try {
      if (currentUserId == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  // Get user's enrollments
  Stream<List<UserEnrollment>> getUserEnrollmentsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('enrollments')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserEnrollment.fromMap(doc.data()))
            .toList());
  }

  // Get enrollment for specific course
  Future<UserEnrollment?> getCourseEnrollment(String courseId) async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .get();

      if (doc.exists) {
        return UserEnrollment.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting enrollment: $e');
      return null;
    }
  }

  // Update course progress
  Future<bool> updateCourseProgress(
    String courseId,
    double progress,
    int completedLessons,
  ) async {
    try {
      if (currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .update({
        'progress': progress,
        'completedLessons': completedLessons,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating progress: $e');
      return false;
    }
  }

  // Get enrolled courses with details
  Future<List<Map<String, dynamic>>> getEnrolledCoursesWithDetails() async {
    try {
      if (currentUserId == null) return [];

      // Get all enrollments
      QuerySnapshot enrollmentSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .get();

      List<Map<String, dynamic>> enrolledCourses = [];

      for (var enrollDoc in enrollmentSnapshot.docs) {
        UserEnrollment enrollment = UserEnrollment.fromMap(
          enrollDoc.data() as Map<String, dynamic>,
        );

        // Get course details
        Course? course = await getCourse(enrollment.courseId);
        
        if (course != null) {
          enrolledCourses.add({
            'course': course,
            'enrollment': enrollment,
          });
        }
      }

      return enrolledCourses;
    } catch (e) {
      print('Error getting enrolled courses: $e');
      return [];
    }
  }

  // ==================== ASSIGNMENT OPERATIONS ====================

  // Get assignments for a course
  Stream<List<Assignment>> getCourseAssignmentsStream(String courseId) {
    return _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Assignment.fromFirestore(doc))
            .toList());
  }

  // Get all assignments for enrolled courses
  Future<List<Assignment>> getUserAssignments() async {
    try {
      if (currentUserId == null) return [];

      // Get user's enrolled course IDs
      QuerySnapshot enrollmentSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .get();

      List<String> courseIds = enrollmentSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      if (courseIds.isEmpty) return [];

      // Get assignments for these courses
      QuerySnapshot assignmentSnapshot = await _firestore
          .collection('assignments')
          .where('courseId', whereIn: courseIds)
          .get();

      return assignmentSnapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user assignments: $e');
      return [];
    }
  }

  // Submit assignment
  Future<bool> submitAssignment(String assignmentId, String submissionText) async {
    try {
      if (currentUserId == null) return false;

      await _firestore
          .collection('submissions')
          .doc('${currentUserId}_$assignmentId')
          .set({
        'userId': currentUserId,
        'assignmentId': assignmentId,
        'submissionText': submissionText,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      return true;
    } catch (e) {
      print('Error submitting assignment: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      if (currentUserId == null) {
        return {'enrolled': 0, 'completed': 0, 'hours': 0};
      }

      QuerySnapshot enrollmentSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .get();

      int enrolled = enrollmentSnapshot.docs.length;
      int completed = 0;
      int totalHours = 0;

      for (var doc in enrollmentSnapshot.docs) {
        UserEnrollment enrollment = UserEnrollment.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        
        if (enrollment.progress >= 1.0) {
          completed++;
        }

        // Estimate hours (each completed lesson = 1 hour)
        totalHours += enrollment.completedLessons;
      }

      return {
        'enrolled': enrolled,
        'completed': completed,
        'hours': totalHours,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {'enrolled': 0, 'completed': 0, 'hours': 0};
    }
  }
}