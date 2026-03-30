import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/services/school_data_service.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/core/models/app_user.dart";

// schoolDataServiceProvider moved to lib/core/providers/school_providers.dart

import "package:nova_rise_app/core/providers/filter_providers.dart";

final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final students = ref.watch(currentStudentsProvider).valueOrNull ?? [];
  final filter = ref.watch(globalSchoolFilterProvider);

  return students.where((s) {
    final matchesGender = filter.gender == GenderFilter.all || 
        (filter.gender == GenderFilter.boys && s.branchId == "boys") ||
        (filter.gender == GenderFilter.girls && s.branchId == "girls");
    
    final matchesLevel = filter.level == LevelFilter.all ||
        (filter.level == LevelFilter.junior && s.isJunior) ||
        (filter.level == LevelFilter.senior && !s.isJunior);

    return matchesGender && matchesLevel;
  }).toList();
});

final currentStaffProvider = StreamProvider<List<AppUser>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null || user.role != UserRole.admin) {
    return Stream.value(const []);
  }
  return ref.watch(schoolDataServiceProvider).watchStaff(user.schoolId);
});

// currentClassIdsProvider moved to lib/core/providers/school_providers.dart

final allClassesMapProvider = Provider<Map<String, String>>((ref) {
  final classes = ref.watch(schoolClassesProvider).valueOrNull ?? const [];
  return {for (final c in classes) c.id: c.displayName};
});
