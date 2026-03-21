import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/student.dart";
import "../../../../core/services/school_data_service.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/models/app_user.dart";
import "../../../admin_tools/presentation/controllers/admin_tools_controller.dart";

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

final currentStaffProvider = StreamProvider<List<AppUser>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null || user.role != UserRole.admin) {
    return Stream.value(const []);
  }
  return ref.watch(schoolDataServiceProvider).watchStaff(user.schoolId);
});

final currentClassIdsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return const [];
  
  if (user.role == UserRole.teacher) {
    final classesValue = ref.watch(teacherClassesProvider);
    return classesValue.maybeWhen(
      data: (classes) => classes.map((c) => c.id).toList(),
      orElse: () => user.assignedClassIds,
    );
  }

  final students = ref.watch(currentStudentsProvider).valueOrNull ?? const <Student>[];
  if (user.role == UserRole.parent) {
    return students.map((student) => student.classId).toSet().toList();
  }
  
  return user.assignedClassIds.isNotEmpty 
      ? user.assignedClassIds 
      : students.map((student) => student.classId).toSet().toList();
});

final allClassesMapProvider = Provider<Map<String, String>>((ref) {
  final classes = ref.watch(schoolClassesProvider).valueOrNull ?? const [];
  return {for (final c in classes) c.id: c.displayName};
});
