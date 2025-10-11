import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  String? _userRole;
  String? get userRole => _userRole;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize and get user role
  Future<void> initialize() async {
    if (currentUser != null) {
      await _loadUserRole();
    }
  }

  Future<void> _loadUserRole() async {
    if (currentUser == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'student';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    required String role, // 'student' or 'teacher'
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role == 'student' && studentId != null) {
        userData['studentId'] = studentId.trim();
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      await userCredential.user!.updateDisplayName(name.trim());

      _userRole = role;
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
      
      await _loadUserRole();
      
      return {'success': true, 'message': 'Login successful!', 'role': _userRole};
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
    _userRole = null;
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
    String? studentId,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      Map<String, dynamic> updateData = {
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (studentId != null) {
        updateData['studentId'] = studentId.trim();
      }

      await _firestore.collection('users').doc(currentUser!.uid).update(updateData);
      await currentUser!.updateDisplayName(name.trim());
      
      notifyListeners();
      return {'success': true, 'message': 'Profile updated successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }
}