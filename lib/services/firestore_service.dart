import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================
  
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

  Future<bool> updateUserProfile(String name, String? studentId) async {
    try {
      if (currentUserId == null) return false;

      Map<String, dynamic> updateData = {
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (studentId != null && studentId.isNotEmpty) {
        updateData['studentId'] = studentId;
      }

      await _firestore.collection('users').doc(currentUserId).update(updateData);

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // ==================== COURSE OPERATIONS ====================

  Stream<List<Course>> getCoursesStream() {
    return _firestore
        .collection('courses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList());
  }

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

  Stream<List<Course>> getTeacherCoursesStream(String teacherId) {
    return _firestore
        .collection('courses')
        .where('instructorId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList());
  }

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

  Future<String?> createCourse(Course course) async {
    try {
      if (currentUserId == null) return null;

      DocumentReference docRef = await _firestore.collection('courses').add({
        ...course.toMap(),
        'instructorId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating course: $e');
      return null;
    }
  }

  Future<bool> updateCourse(String courseId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
      return true;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }

  // ==================== ENROLLMENT OPERATIONS ====================

  Future<bool> enrollInCourse(String courseId) async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return false;
      }

      // Get user data to check role
      final userData = await getUserData();
      final userRole = userData?['role'] ?? 'student';
      
      print('🔍 Enrolling user in course (Role: $userRole)');

      // Check if already enrolled
      final enrollmentDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .get();

      if (enrollmentDoc.exists) {
        print('✅ Already enrolled');
        return true;
      }

      // Create enrollment
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .set({
        'courseId': courseId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0.0,
        'completedLessons': 0,
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'completedLessonIds': [],
      });

      // Only increment student count if user is a STUDENT
      if (userRole == 'student') {
        await _firestore.collection('courses').doc(courseId).update({
          'students': FieldValue.increment(1),
        });
        print('✅ Student enrolled and count incremented');
      } else {
        print('✅ Teacher enrolled (count not incremented)');
      }

      return true;

    } catch (e) {
      print('❌ Enrollment error: $e');
      return false;
    }
  }

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

  // ✅ NEW: Get all enrollments for current user (for "My Courses" feature)
  Future<List<UserEnrollment>> getUserEnrollments() async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return [];
      }

      print('🔍 Getting enrollments for user: $currentUserId');

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .get();

      List<UserEnrollment> enrollments = [];
      
      for (var doc in snapshot.docs) {
        try {
          enrollments.add(UserEnrollment.fromMap(doc.data() as Map<String, dynamic>));
        } catch (e) {
          print('Error parsing enrollment: $e');
        }
      }

      print('✅ Found ${enrollments.length} enrollments');
      return enrollments;
    } catch (e) {
      print('❌ Error getting user enrollments: $e');
      return [];
    }
  }

  // ✅ Get enrolled students (ONLY STUDENTS, exclude teachers)
  Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId) async {
    try {
      print('🔍 Getting enrolled students for course: $courseId');
      
      // Get ONLY users with role = 'student'
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      print('👥 Found ${studentsSnapshot.docs.length} total student users');

      List<Map<String, dynamic>> enrolledStudents = [];

      for (var userDoc in studentsSnapshot.docs) {
        try {
          // Check if this student has enrollment for this course
          DocumentSnapshot enrollmentDoc = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('enrollments')
              .doc(courseId)
              .get();

          if (enrollmentDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            Map<String, dynamic> enrollmentData = enrollmentDoc.data() as Map<String, dynamic>;
            
            String userRole = userData['role'] ?? 'student';
            
            if (userRole == 'student') {
              enrolledStudents.add({
                'userId': userDoc.id,
                'name': userData['name'] ?? 'Unknown Student',
                'email': userData['email'] ?? '',
                'studentId': userData['studentId'] ?? '',
                'role': userRole,
                'enrollment': UserEnrollment.fromMap(enrollmentData),
              });
            }
          }
        } catch (e) {
          print('⚠️ Error processing user ${userDoc.id}: $e');
          continue;
        }
      }

      print('✅ Found ${enrolledStudents.length} enrolled students');
      return enrolledStudents;
    } catch (e) {
      print('❌ Error getting enrolled students: $e');
      return [];
    }
  }

  // Get actual student count for a course (excluding teachers)
  Future<int> getCourseStudentCount(String courseId) async {
    try {
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      int studentCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        DocumentSnapshot enrollmentDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('enrollments')
            .doc(courseId)
            .get();

        if (enrollmentDoc.exists) {
          studentCount++;
        }
      }

      return studentCount;
    } catch (e) {
      print('Error getting student count: $e');
      return 0;
    }
  }

  // Fix student count for a course
  Future<bool> fixCourseStudentCount(String courseId) async {
    try {
      print('🔧 Fixing student count for course: $courseId');
      
      final actualCount = await getCourseStudentCount(courseId);
      
      print('📊 Actual student count: $actualCount');
      
      await _firestore.collection('courses').doc(courseId).update({
        'students': actualCount,
      });
      
      print('✅ Course student count updated to $actualCount');
      return true;
    } catch (e) {
      print('❌ Error fixing student count: $e');
      return false;
    }
  }

  // ==================== ASSIGNMENT OPERATIONS ====================

  Future<List<Assignment>> getCourseAssignmentsList(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      List<Assignment> assignments = snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();

      assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      return assignments;
    } catch (e) {
      print('Error getting course assignments: $e');
      return [];
    }
  }

  Stream<List<Assignment>> getCourseAssignmentsStream(String courseId) {
    return _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          List<Assignment> assignments = snapshot.docs
              .map((doc) => Assignment.fromFirestore(doc))
              .toList();
          
          assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          
          return assignments;
        });
  }

  // ✅ FIXED: Get ONLY assignments from courses the student is enrolled in
  Future<List<Assignment>> getUserAssignments() async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return [];
      }

      print('🔍 Getting assignments for enrolled courses...');

      // Get all enrollments for current user
      QuerySnapshot enrollmentSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .get();

      if (enrollmentSnapshot.docs.isEmpty) {
        print('⚠️ User is not enrolled in any courses');
        return [];
      }

      // Get course IDs user is enrolled in
      List<String> enrolledCourseIds = enrollmentSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['courseId'] as String)
          .toList();

      print('📚 User is enrolled in ${enrolledCourseIds.length} courses');

      // Get assignments ONLY from enrolled courses
      List<Assignment> allAssignments = [];
      
      for (String courseId in enrolledCourseIds) {
        try {
          QuerySnapshot assignmentsSnapshot = await _firestore
              .collection('assignments')
              .where('courseId', isEqualTo: courseId)
              .get();

          for (var doc in assignmentsSnapshot.docs) {
            try {
              Assignment assignment = Assignment.fromFirestore(doc);
              String? status = await getSubmissionStatus(assignment.id);
              
              allAssignments.add(Assignment(
                id: assignment.id,
                courseId: assignment.courseId,
                title: assignment.title,
                description: assignment.description,
                dueDate: assignment.dueDate,
                totalMarks: assignment.totalMarks,
                createdBy: assignment.createdBy,
                status: status ?? 'pending',
              ));
            } catch (e) {
              print('Error processing assignment: $e');
            }
          }
        } catch (e) {
          print('Error getting assignments for course $courseId: $e');
        }
      }

      // Sort by due date
      allAssignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      print('✅ Found ${allAssignments.length} assignments from enrolled courses');
      
      return allAssignments;
    } catch (e) {
      print('❌ Error getting user assignments: $e');
      return [];
    }
  }

  Future<String?> createAssignment(Assignment assignment) async {
    try {
      if (currentUserId == null) return null;

      DocumentReference docRef = await _firestore.collection('assignments').add({
        'courseId': assignment.courseId,
        'title': assignment.title,
        'description': assignment.description,
        'dueDate': Timestamp.fromDate(assignment.dueDate),
        'totalMarks': assignment.totalMarks,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating assignment: $e');
      return null;
    }
  }

  Future<bool> updateAssignment(String assignmentId, Map<String, dynamic> updates) async {
    try {
      Map<String, dynamic> updateData = {...updates};
      
      if (updates.containsKey('dueDate') && updates['dueDate'] is DateTime) {
        updateData['dueDate'] = Timestamp.fromDate(updates['dueDate'] as DateTime);
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('assignments').doc(assignmentId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating assignment: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).delete();
      
      QuerySnapshot submissions = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in submissions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }

  Future<bool> submitAssignment(String assignmentId, String submissionText) async {
    try {
      if (currentUserId == null) return false;

      Map<String, dynamic>? userData = await getUserData();
      
      DocumentSnapshot assignmentDoc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();
      
      if (!assignmentDoc.exists) return false;
      
      Map<String, dynamic> assignmentData = assignmentDoc.data() as Map<String, dynamic>;

      String submissionId = '${currentUserId}_$assignmentId';

      await _firestore.collection('submissions').doc(submissionId).set({
        'userId': currentUserId,
        'assignmentId': assignmentId,
        'courseId': assignmentData['courseId'],
        'submissionText': submissionText,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'studentName': userData?['name'] ?? '',
        'studentEmail': userData?['email'] ?? '',
      });

      return true;
    } catch (e) {
      print('Error submitting assignment: $e');
      return false;
    }
  }

  Future<String?> getSubmissionStatus(String assignmentId) async {
    try {
      if (currentUserId == null) return null;

      String submissionId = '${currentUserId}_$assignmentId';
      
      DocumentSnapshot doc = await _firestore
          .collection('submissions')
          .doc(submissionId)
          .get();

      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['status'];
      }
      return null;
    } catch (e) {
      print('Error getting submission status: $e');
      return null;
    }
  }

  Future<List<Submission>> getAssignmentSubmissions(String assignmentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      return snapshot.docs.map((doc) => Submission.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting submissions: $e');
      return [];
    }
  }

  Future<bool> gradeSubmission(String submissionId, int marks, String feedback) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'status': 'graded',
        'marks': marks,
        'feedback': feedback,
        'gradedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error grading submission: $e');
      return false;
    }
  }

  // ==================== LESSON OPERATIONS ====================

  Stream<List<Lesson>> getCourseLessonsStream(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('syllabus')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Lesson.fromFirestore(doc))
            .toList());
  }

  Future<bool> markLessonComplete(String courseId, String lessonId) async {
    try {
      if (currentUserId == null) return false;

      DocumentReference enrollmentRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId);

      DocumentSnapshot enrollmentDoc = await enrollmentRef.get();
      
      if (!enrollmentDoc.exists) return false;

      UserEnrollment enrollment = UserEnrollment.fromMap(
        enrollmentDoc.data() as Map<String, dynamic>
      );

      if (!enrollment.completedLessonIds.contains(lessonId)) {
        List<String> completedIds = List.from(enrollment.completedLessonIds)..add(lessonId);
        
        Course? course = await getCourse(courseId);
        int totalLessons = course?.lessons ?? 1;
        
        double newProgress = completedIds.length / totalLessons;

        await enrollmentRef.update({
          'completedLessonIds': completedIds,
          'completedLessons': completedIds.length,
          'progress': newProgress,
          'lastAccessedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error marking lesson complete: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

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

  Future<Map<String, int>> getTeacherStats() async {
    try {
      if (currentUserId == null) {
        return {'courses': 0, 'students': 0, 'assignments': 0};
      }

      QuerySnapshot coursesSnapshot = await _firestore
          .collection('courses')
          .where('instructorId', isEqualTo: currentUserId)
          .get();

      int totalCourses = coursesSnapshot.docs.length;

      int totalStudents = 0;
      for (var doc in coursesSnapshot.docs) {
        Course course = Course.fromFirestore(doc);
        totalStudents += course.students;
      }

      QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('assignments')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      int totalAssignments = assignmentsSnapshot.docs.length;

      return {
        'courses': totalCourses,
        'students': totalStudents,
        'assignments': totalAssignments,
      };
    } catch (e) {
      print('Error getting teacher stats: $e');
      return {'courses': 0, 'students': 0, 'assignments': 0};
    }
  }

  // ==================== COURSE RATING SYSTEM ====================

  Future<bool> rateCourse(String courseId, double rating, String? review) async {
    try {
      if (currentUserId == null) return false;

      String ratingId = '${currentUserId}_$courseId';
      
      await _firestore.collection('course_ratings').doc(ratingId).set({
        'userId': currentUserId,
        'courseId': courseId,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateCourseAverageRating(courseId);
      
      return true;
    } catch (e) {
      print('Error rating course: $e');
      return false;
    }
  }

  Future<void> _updateCourseAverageRating(String courseId) async {
    try {
      QuerySnapshot ratingsSnapshot = await _firestore
          .collection('course_ratings')
          .where('courseId', isEqualTo: courseId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int count = ratingsSnapshot.docs.length;

      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0.0;
      }

      double averageRating = totalRating / count;

      await _firestore.collection('courses').doc(courseId).update({
        'averageRating': averageRating,
        'totalRatings': count,
      });
    } catch (e) {
      print('Error updating course rating: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserCourseRating(String courseId) async {
    try {
      if (currentUserId == null) return null;

      String ratingId = '${currentUserId}_$courseId';
      
      DocumentSnapshot doc = await _firestore
          .collection('course_ratings')
          .doc(ratingId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCourseReviews(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('course_ratings')
          .where('courseId', isEqualTo: courseId)
          .where('review', isNotEqualTo: null)
          .limit(10)
          .get();

      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> ratingData = doc.data() as Map<String, dynamic>;
        
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(ratingData['userId'])
            .get();
        
        Map<String, dynamic> userData = userDoc.exists 
            ? userDoc.data() as Map<String, dynamic>
            : {};
        
        reviews.add({
          'rating': ratingData['rating'],
          'review': ratingData['review'],
          'userName': userData['name'] ?? 'Anonymous',
          'createdAt': ratingData['createdAt'],
        });
      }
      
      return reviews;
    } catch (e) {
      print('Error getting course reviews: $e');
      return [];
    }
  }
}