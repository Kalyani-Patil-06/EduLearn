import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'studentId': studentId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'enrolledCourses': [],
      });

      // Update display name
      await userCredential.user!.updateDisplayName(name.trim());

      notifyListeners();
      return {'success': true, 'message': 'Registration successful!'};
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }
      
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      notifyListeners();
      return {'success': true, 'message': 'Login successful!'};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? 'Login failed';
      }
      
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String studentId,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': name.trim(),
        'studentId': studentId.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await currentUser!.updateDisplayName(name.trim());
      
      notifyListeners();
      return {'success': true, 'message': 'Profile updated successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  // Enroll in a course
  Future<void> enrollInCourse(String courseId) async {
    try {
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
    }
  }

  // Check if user is enrolled in a course
  Future<bool> isEnrolledInCourse(String courseId) async {
    try {
      if (currentUser == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List enrolledCourses = data['enrolledCourses'] ?? [];
        return enrolledCourses.contains(courseId);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking enrollment: $e');
      return false;
    }
  }
}