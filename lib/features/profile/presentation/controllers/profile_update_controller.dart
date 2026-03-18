import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

class ProfileUpdateState {
  const ProfileUpdateState({this.isUploading = false, this.error});
  final bool isUploading;
  final String? error;
}

final profileUpdateControllerProvider = StateNotifierProvider<ProfileUpdateController, ProfileUpdateState>((ref) {
  return ProfileUpdateController(
    ref.watch(firebaseFirestoreProvider),
    FirebaseStorage.instance,
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
      final ref = _storage.ref().child('profiles').child('${user.uid}.jpg');
      
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
}
