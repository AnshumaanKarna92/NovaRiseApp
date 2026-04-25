import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService(this._auth, this._functions, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_id');
      await prefs.remove('saved_password');
    } catch (_) {}
    return _auth.signOut();
  }

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
    required String phone,
    List<String> assignedClassIds = const [],
    List<String> linkedStudentIds = const [],
    String? primarySubject,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      // Create the user profile in Firestore
      await _ensureLocalProfileWithRole(user, role, displayName, phone: phone, assignedClassIds: assignedClassIds, linkedStudentIds: linkedStudentIds, primarySubject: primarySubject);
    }
  }

  Future<void> _ensureLocalProfileWithRole(User user, UserRole role, String displayName, {required String phone, List<String> assignedClassIds = const [], List<String> linkedStudentIds = const [], String? primarySubject}) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    await profileRef.set({
      'uid': user.uid,
      'schoolId': 'school_001', // Default school ID
      'role': role.name,
      'displayName': displayName,
      'email': user.email ?? '',
      'phone': phone,
      'linkedStudentIds': linkedStudentIds,
      'assignedClassIds': assignedClassIds,
      if (primarySubject != null && primarySubject.isNotEmpty) 'primarySubject': primarySubject,
      'status': 'active',
      'preferredLanguage': 'en',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureUserProfile({String? fcmToken}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint("AUTH_SERVICE: ensureUserProfile starting for ${user.uid}");
    // Refresh token to get latest claims with timeout
    try {
      await user.getIdToken(true).timeout(const Duration(seconds: 10));
      debugPrint("AUTH_SERVICE: ID Token refreshed.");
    } catch (e) {
      debugPrint("AUTH_SERVICE: ID Token refresh failed/timed out: $e. Using current token.");
    }

    final callable = _functions.httpsCallable('ensureUserProfile');
    try {
      debugPrint("AUTH_SERVICE: Calling Cloud Function...");
      await callable.call({
        if (fcmToken != null) 'fcmToken': fcmToken,
      }).timeout(const Duration(seconds: 20));
      debugPrint("AUTH_SERVICE: Cloud Function call returned.");
    } catch (e) {
      debugPrint("AUTH_SERVICE: ensureUserProfile failed/timed out: $e");
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updatePassword(newPassword);
  }

  Future<void> updateTeacherProfile({
    required String uid,
    required String displayName,
    required String phone,
    String? primarySubject,
    String? bloodGroup,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'phone': phone,
      if (primarySubject != null) 'primarySubject': primarySubject,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
