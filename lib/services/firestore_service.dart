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
        print('ENROLLMENT FAILED: No user logged in');
        return false;
      }

      // Get user data to check role
      final userData = await getUserData();
      final userRole = userData?['role'] ?? 'student';
      final userName = userData?['name'] ?? 'Unknown';
      final userEmail = userData?['email'] ?? 'Unknown';
      
      // Check if already enrolled
      final enrollmentDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('enrollments')
          .doc(courseId)
          .get();

      if (enrollmentDoc.exists) {
        print('User is already enrolled in this course');
        return true;
      }

      // Create enrollment
      print('Creating new enrollment...');
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
      

      // Only increment student count if user is actually a STUDENT
      if (userRole == 'student') {
        print('Incrementing course student count...');
        await _firestore.collection('courses').doc(courseId).update({
          'students': FieldValue.increment(1),
        });
        print('Student count incremented');
      } else {
        print('User is $userRole - NOT incrementing student count');
      }

      return true;

    } catch (e) {
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

  // ✅ FIXED: Get enrolled students properly (ONLY STUDENTS, exclude teachers)
  Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId) async {
    try {
    
      // STEP 1: Get ALL users first (for debugging)
      QuerySnapshot allUsersSnapshot = await _firestore.collection('users').get();
      print('📊 Total users in database: ${allUsersSnapshot.docs.length}');
      
      // Check all users and their roles
      for (var userDoc in allUsersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('👤 User: ${userData['name']} | Role: ${userData['role']} | Email: ${userData['email']}');
      }
      
      print('───────────────────────────────────────────────');
      
      // STEP 2: Get ONLY users with role = 'student'
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      print('Total STUDENT users found: ${studentsSnapshot.docs.length}');
      
      if (studentsSnapshot.docs.isEmpty) {
        print('WARNING: No users with role="student" found in database!');
        print('This might mean:');
        print('1. Students are registered with a different role value');
        print('2. The role field is missing or misspelled');
        print('3. No students have been created yet');
      }

      List<Map<String, dynamic>> enrolledStudents = [];

      // STEP 3: Check each student's enrollment
      for (var userDoc in studentsSnapshot.docs) {
        try {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          print('🔍 Checking student: ${userData['name']} (${userDoc.id})');
          
          // Check if this student has enrollment for this course
          DocumentSnapshot enrollmentDoc = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('enrollments')
              .doc(courseId)
              .get();

          if (enrollmentDoc.exists) {
            Map<String, dynamic> enrollmentData = enrollmentDoc.data() as Map<String, dynamic>;
            print('Enrollment data: $enrollmentData');
            
            // Double check the role is student
            String userRole = userData['role'] ?? 'student';
            
            if (userRole == 'student') {
              print('MATCHED: Adding ${userData['name']} to enrolled students list');
              
              enrolledStudents.add({
                'userId': userDoc.id,
                'name': userData['name'] ?? 'Unknown Student',
                'email': userData['email'] ?? '',
                'studentId': userData['studentId'] ?? '',
                'role': userRole,
                'enrollment': UserEnrollment.fromMap(enrollmentData),
              });
            } else {
              print('SKIPPED: User role is "$userRole", not "student"');
            }
          } else {
            print('NOT ENROLLED: Student has no enrollment for this course');
          }
        } catch (e) {
          print('ERROR processing user ${userDoc.id}: $e');
          continue;
        }
      }

      if (enrolledStudents.isEmpty) {
        print('NO STUDENTS FOUND! Possible reasons:');
        print('1. Students enrolled but role field is wrong');
        print('2. Enrollment is in wrong collection path');
        print('3. Course ID mismatch');
      }
      
      return enrolledStudents;
    } catch (e) {
      print('CRITICAL ERROR getting enrolled students: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get actual student count for a course (excluding teachers)
  Future<int> getCourseStudentCount(String courseId) async {
    try {
      // Get only users with role = 'student'
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

  // Fix student count for a course (removes teachers from count)
  Future<bool> fixCourseStudentCount(String courseId) async {
    try {
      print('Fixing student count for course: $courseId');
      
      // Get actual student count (excluding teachers)
      final actualCount = await getCourseStudentCount(courseId);
      
      print('Actual student count: $actualCount');
      
      // Update the course with correct count
      await _firestore.collection('courses').doc(courseId).update({
        'students': actualCount,
      });
      
      print('Course student count updated to $actualCount');
      return true;
    } catch (e) {
      print('Error fixing student count: $e');
      return false;
    }
  }

  // ==================== ASSIGNMENT OPERATIONS ====================

  // Get assignments as List instead of Stream to avoid index error
  Future<List<Assignment>> getCourseAssignmentsList(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      List<Assignment> assignments = snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();

      // Sort by due date
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
          
          // Sort by due date
          assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          
          return assignments;
        });
  }

  Future<List<Assignment>> getUserAssignments() async {
    try {
      if (currentUserId == null) {
        return _getSampleAssignments();
      }

      await _createSampleAssignmentsIfNeeded();

      QuerySnapshot allAssignments = await _firestore
          .collection('assignments')
          .limit(10)
          .get();
      
      List<Assignment> assignments = [];
      for (var doc in allAssignments.docs) {
        try {
          Assignment assignment = Assignment.fromFirestore(doc);
          String? status = await getSubmissionStatus(assignment.id);
          
          assignments.add(Assignment(
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
          continue;
        }
      }
      
      // Sort by due date
      assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      
      if (assignments.isEmpty) {
        return _getSampleAssignments();
      }
      
      return assignments;
    } catch (e) {
      print('Error getting user assignments: $e');
      return _getSampleAssignments();
    }
  }

  List<Assignment> _getSampleAssignments() {
    return [
      Assignment(
        id: 'sample_1',
        courseId: 'sample_course_1',
        title: 'Flutter Basics Quiz',
        description: 'Complete the quiz on Flutter widgets and state management concepts.',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        totalMarks: 50,
        createdBy: 'teacher_1',
        status: 'pending',
      ),
      Assignment(
        id: 'sample_2',
        courseId: 'sample_course_2',
        title: 'Mobile App Design Project',
        description: 'Design a complete mobile app interface using Figma or similar tools.',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        totalMarks: 100,
        createdBy: 'teacher_2',
        status: 'pending',
      ),
      Assignment(
        id: 'sample_3',
        courseId: 'sample_course_1',
        title: 'Database Integration Task',
        description: 'Implement Firebase integration in your Flutter app with CRUD operations.',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        totalMarks: 75,
        createdBy: 'teacher_1',
        status: 'submitted',
      ),
    ];
  }

  Future<void> _createSampleAssignmentsIfNeeded() async {
    try {
      QuerySnapshot existingAssignments = await _firestore
          .collection('assignments')
          .limit(1)
          .get();
      
      if (existingAssignments.docs.isNotEmpty) return;
      
      List<Map<String, dynamic>> sampleAssignments = [
        {
          'courseId': 'sample_course_1',
          'title': 'Flutter Basics Quiz',
          'description': 'Complete the quiz on Flutter widgets and state management concepts.',
          'dueDate': DateTime.now().add(const Duration(days: 7)),
          'totalMarks': 50,
          'createdBy': 'teacher_1',
        },
      ];
      
      for (var assignmentData in sampleAssignments) {
        await _firestore.collection('assignments').add({
          ...assignmentData,
          'dueDate': Timestamp.fromDate(assignmentData['dueDate']),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating sample assignments: $e');
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