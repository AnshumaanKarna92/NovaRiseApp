import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/core/services/auth_service.dart";
import "package:nova_rise_app/core/services/notification_service.dart";
import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/core/services/school_data_service.dart";
import "package:nova_rise_app/features/admin_tools/data/import_submission_service.dart";

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firebaseMessagingProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<AppUser?>.value(null);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore.collection("users").doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(snapshot.id, snapshot.data()!);
  });
});

final schoolDataServiceProvider = Provider<SchoolDataService>((ref) {
  return SchoolDataService(ref.watch(firebaseFirestoreProvider));
});

final schoolClassesProvider = StreamProvider<List<SchoolClass>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection("classes")
      .where("schoolId", isEqualTo: user.schoolId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => SchoolClass.fromMap(doc.id, doc.data())).toList();
  });
});

final currentStudentsProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(schoolDataServiceProvider).watchStudentsForUser(user);
});

final allClassesMapProvider = Provider<Map<String, String>>((ref) {
  final classes = ref.watch(schoolClassesProvider).value ?? [];
  return {
    for (final c in classes) 
      c.id: "${c.displayName}${c.branchId.isNotEmpty ? ' (${c.branchId.toUpperCase()})' : ''}"
  };
});

final currentClassIdsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return const [];
  if (user.role == UserRole.admin) {
    return ref.watch(schoolClassesProvider).valueOrNull?.map((c) => c.id).toList() ?? const [];
  }
  if (user.role == UserRole.teacher) {
    final schoolClasses = ref.watch(schoolClassesProvider).valueOrNull ?? [];
    final ownedClasses = schoolClasses.where((c) => c.classTeacherId == user.uid).map((c) => c.id).toList();
    return {...user.assignedClassIds, ...ownedClasses}.toList();
  }
  if (user.role == UserRole.parent) {
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? [];
    return students.map((s) => s.classId).toSet().toList();
  }
  return const [];
});

final importSubmissionServiceProvider = Provider<ImportSubmissionService>((ref) {
  return ImportSubmissionService(
    storage: ref.watch(firebaseStorageProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
});

final allStaffProvider = StreamProvider<List<AppUser>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchStaff(user.schoolId);
});

final teacherClassesProvider = StreamProvider<List<SchoolClass>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchClassesForTeacher(user.uid, user.schoolId, user.assignedClassIds);
});

