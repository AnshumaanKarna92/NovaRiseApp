enum UserRole { admin, teacher, parent, cashCollector }

class AppUser {
  const AppUser({
    required this.uid,
    required this.schoolId,
    required this.role,
    required this.displayName,
    required this.phone,
    this.linkedStudentIds = const [],
    this.assignedClassIds = const [],
    this.status = 'active',
  });

  final String uid;
  final String schoolId;
  final UserRole role;
  final String displayName;
  final String phone;
  final List<String> linkedStudentIds;
  final List<String> assignedClassIds;
  final String status;
}
