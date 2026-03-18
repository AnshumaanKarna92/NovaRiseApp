import '../models/app_user.dart';

class DemoSessionService {
  const DemoSessionService();

  AppUser buildParent() {
    return const AppUser(
      uid: 'parent_1',
      schoolId: 'school_001',
      role: UserRole.parent,
      displayName: 'Suresh Sharma',
      phone: '+91xxxxxxxxxx',
      linkedStudentIds: ['S2026_001'],
    );
  }

  AppUser buildTeacher() {
    return const AppUser(
      uid: 'teacher_1',
      schoolId: 'school_001',
      role: UserRole.teacher,
      displayName: 'Mr. Kumar',
      phone: '+91yyyyyyyyyy',
      assignedClassIds: ['5A', '6B'],
    );
  }

  AppUser buildAdmin() {
    return const AppUser(
      uid: 'admin_1',
      schoolId: 'school_001',
      role: UserRole.admin,
      displayName: 'Principal',
      phone: '+91zzzzzzzzzz',
    );
  }
}
