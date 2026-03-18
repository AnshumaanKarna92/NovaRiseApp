import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService(this._auth, this._functions, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  
  Future<void> signOut() => _auth.signOut();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Force refresh token to ensure custom claims are loaded
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    List<String> assignedClassIds = const [],
    List<String> linkedStudentIds = const [],
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      // Create the user profile in Firestore
      await _ensureLocalProfileWithRole(user, role, displayName, assignedClassIds: assignedClassIds, linkedStudentIds: linkedStudentIds);
    }
  }

  Future<void> _ensureLocalProfileWithRole(User user, UserRole role, String displayName, {List<String> assignedClassIds = const [], List<String> linkedStudentIds = const []}) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    await profileRef.set({
      'uid': user.uid,
      'schoolId': 'school_001', // Default school ID
      'role': role.name,
      'displayName': displayName,
      'phone': user.phoneNumber ?? '',
      'linkedStudentIds': linkedStudentIds,
      'assignedClassIds': assignedClassIds,
      'status': 'active',
      'preferredLanguage': 'en',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureUserProfile({String? fcmToken}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Refresh token to get latest claims
    await user.getIdToken(true);

    final callable = _functions.httpsCallable('ensureUserProfile');
    try {
      await callable.call({
        if (fcmToken != null) 'fcmToken': fcmToken,
      });
    } catch (e) {
      // If the function fails (e.g., cold start or deployment delay), 
      // we've already created a local profile in createUser as a fallback.
      print('ensureUserProfile failed: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updatePassword(newPassword);
  }
}
