import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/providers/school_providers.dart";

class ProfileUpdateState {
  const ProfileUpdateState({this.isUploading = false, this.error});
  final bool isUploading;
  final String? error;
}

final profileUpdateControllerProvider = StateNotifierProvider<ProfileUpdateController, ProfileUpdateState>((ref) {
  return ProfileUpdateController(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
    ref,
  );
});

class ProfileUpdateController extends StateNotifier<ProfileUpdateState> {
  ProfileUpdateController(this._firestore, this._storage, this._ref) : super(const ProfileUpdateState());

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Ref _ref;

  Future<void> pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    state = const ProfileUpdateState(isUploading: true);
    try {
      final user = _ref.read(userProfileProvider).value;
      if (user == null) throw "User not logged in";

      final file = File(result.files.single.path!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('profiles').child('${user.uid}_$timestamp.jpg');
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const ProfileUpdateState(isUploading: false);
    } catch (e) {
      state = ProfileUpdateState(isUploading: false, error: e.toString());
    }
  }

  Future<void> updateProfile({String? displayName, String? bloodGroup, String? phone}) async {
    try {
      final user = _ref.read(userProfileProvider).value;
      if (user == null) throw "User not logged in";

      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (phone != null) updates['phone'] = phone;
      
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      state = ProfileUpdateState(error: e.toString());
    }
  }

  Future<void> pickAndUploadStudentPhoto(String studentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    state = const ProfileUpdateState(isUploading: true);
    try {
      final file = File(result.files.single.path!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('students').child('${studentId}_$timestamp.jpg');
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('students').doc(studentId).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const ProfileUpdateState(isUploading: false);
    } catch (e) {
      state = ProfileUpdateState(isUploading: false, error: e.toString());
    }
  }

  Future<void> updateStudentProfile({
    required String studentId,
    String? name,
    String? bloodGroup,
    String? parentName,
    String? parentPhone,
    String? marksData,
    String? rollNo,
    double? monthlyFees,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (parentName != null) updates['parentName'] = parentName;
      if (parentPhone != null) updates['parentPhone'] = parentPhone;
      if (marksData != null) updates['marksData'] = marksData;
      if (rollNo != null) updates['rollNo'] = rollNo;
      if (monthlyFees != null) updates['monthlyFees'] = monthlyFees;
      
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('students').doc(studentId).update(updates);
    } catch (e) {
      state = ProfileUpdateState(error: e.toString());
    }
  }

  Future<void> updateStaffProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? bloodGroup,
    String? primarySubject,
    List<String>? subjects,
    List<String>? assignedClassIds,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (phone != null) updates['phone'] = phone;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (primarySubject != null) updates['primarySubject'] = primarySubject;
      if (subjects != null) updates['subjects'] = subjects;
      if (assignedClassIds != null) updates['assignedClassIds'] = assignedClassIds;
      
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      state = ProfileUpdateState(error: e.toString());
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
      // Also check if any parent users are linked to this student and remove them? 
      // For now, simple delete of the student record
    } catch (e) {
      state = ProfileUpdateState(error: e.toString());
    }
  }

  Future<void> deleteStaff(String uid) async {
    try {
      // 1. Nullify classTeacherId in any classes they manage
      final classes = await _firestore.collection('classes').where('classTeacherId', isEqualTo: uid).get();
      for (var doc in classes.docs) {
        await doc.reference.update({'classTeacherId': 'unknown'});
      }
      
      // 2. Delete the user document
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      state = ProfileUpdateState(error: e.toString());
    }
  }
}
