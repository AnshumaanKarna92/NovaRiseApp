enum UserRole { admin, teacher, parent, cashCollector, unknown }

class AppUser {
  const AppUser({
    required this.uid,
    required this.schoolId,
    required this.role,
    required this.displayName,
    required this.email,
    required this.phone,
    this.linkedStudentIds = const [],
    this.assignedClassIds = const [],
    this.status = "active",
    this.profileImageUrl = "",
    this.bloodGroup,
    this.primarySubject,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      schoolId: data["schoolId"] as String? ?? "",
      role: parseUserRole(data["role"] as String?),
      displayName: data["displayName"] as String? ?? "User",
      email: data["email"] as String? ?? "",
      phone: data["phone"] as String? ?? "",
      linkedStudentIds: List<String>.from(data["linkedStudentIds"] as List? ?? const []),
      assignedClassIds: List<String>.from(data["assignedClassIds"] as List? ?? const []),
      status: data["status"] as String? ?? "active",
      profileImageUrl: data["profileImageUrl"] as String? ?? "",
      bloodGroup: data["bloodGroup"] as String?,
      primarySubject: data["primarySubject"] as String?,
    );
  }

  final String uid;
  final String schoolId;
  final UserRole role;
  final String displayName;
  final String email;
  final String phone;
  final List<String> linkedStudentIds;
  final List<String> assignedClassIds;
  final String status;
  final String profileImageUrl;
  final String? bloodGroup;
  final String? primarySubject;
}

UserRole parseUserRole(String? value) {
  switch (value) {
    case "admin":
      return UserRole.admin;
    case "teacher":
      return UserRole.teacher;
    case "parent":
      return UserRole.parent;
    case "cash_collector":
      return UserRole.cashCollector;
    default:
      return UserRole.unknown;
  }
}
