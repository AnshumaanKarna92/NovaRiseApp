import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/student.dart";
import "../../../../core/services/school_data_service.dart";
import "../../../auth/presentation/controllers/session_controller.dart";

final schoolDataServiceProvider = Provider<SchoolDataService>((ref) {
  return SchoolDataService(ref.watch(firebaseFirestoreProvider));
});

final currentStudentsProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(schoolDataServiceProvider).watchStudentsForUser(user);
});

final currentClassIdsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  final students = ref.watch(currentStudentsProvider).valueOrNull ?? const <Student>[];
  if (user == null) {
    return const [];
  }
  if (user.status == "provisional" && user.assignedClassIds.isNotEmpty) {
    return user.assignedClassIds;
  }
  if (user.role.name == "parent") {
    return students.map((student) => student.classId).toSet().toList();
  }
  if (user.assignedClassIds.isNotEmpty) {
    return user.assignedClassIds;
  }
  return students.map((student) => student.classId).toSet().toList();
});
