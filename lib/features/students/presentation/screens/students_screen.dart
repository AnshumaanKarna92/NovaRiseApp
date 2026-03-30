import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/features/admin_tools/presentation/controllers/admin_tools_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/shared/widgets/filter_bar.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
import "package:nova_rise_app/features/admin_tools/presentation/screens/teacher_profile_screen.dart";
import "student_detail_screen.dart";

final _studentSearchProvider = StateProvider.autoDispose<String>((ref) => "");

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.cashCollector;
    final studentsValue = ref.watch(currentStudentsProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);
    final staffValue = ref.watch(currentStaffProvider);
    final searchQuery = ref.watch(_studentSearchProvider).toLowerCase();
    final filter = ref.watch(globalSchoolFilterProvider);

    final finalStudents = filteredStudents.where((s) {
      return s.name.toLowerCase().contains(searchQuery) ||
          s.studentId.toLowerCase().contains(searchQuery);
    }).toList();

    final content = TabBarView(
      children: [
        AsyncValueView(
          value: studentsValue,
          data: (allItems) {
            return Column(
              children: [
                if (isAdmin)
                  const GlobalFilterBar(),
                _SearchBar(ref: ref),
                Expanded(
                  child: finalStudents.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No students match your criteria.")))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: finalStudents.length,
                          itemBuilder: (context, index) => _StudentCard(student: finalStudents[index]),
                        ),
                ),
              ],
            );
          },
        ),
        if (isAdmin)
          AsyncValueView<List<SchoolClass>>(
            value: ref.watch(schoolClassesProvider),
            data: (allClasses) => AsyncValueView(
              value: staffValue,
              data: (staffItems) => AsyncValueView(
                value: studentsValue,
                data: (studentItems) {
                  final filter = ref.watch(globalSchoolFilterProvider);
                  final filteredClasses = allClasses.where((c) {
                    final genderMatch = filter.gender == GenderFilter.all || c.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
                    final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? c.isJunior : !c.isJunior);
                    return genderMatch && levelMatch;
                  }).toList()..sort((a, b) => a.classWeight.compareTo(b.classWeight));

                  return Column(
                    children: [
                      const GlobalFilterBar(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const ScreenIntroCard(
                              eyebrow: "School Structure",
                              title: "Classes & Faculty",
                              description: "Manage school sections, assigned teachers, and subjects for each grade level.",
                              icon: Icons.class_outlined,
                              accent: Color(0xFFD4AF37),
                            ),
                            const SizedBox(height: 24),
                            if (filteredClasses.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No classes match the filters."))),
                            for (final cls in filteredClasses)
                              _ClassSummaryTile(
                                classId: cls.id,
                                students: studentItems.where((s) => s.classId == cls.id).toList(),
                                teacher: staffItems.firstWhere((s) => s.uid == cls.classTeacherId, orElse: () => staffItems.firstWhere((s) => s.assignedClassIds.contains(cls.id), orElse: () => const AppUser(uid: "unknown", schoolId: "", role: UserRole.unknown, displayName: "No Teacher", email: "", phone: "", assignedClassIds: []))),
                                allStaff: staffItems,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        if (isAdmin)
          AsyncValueView(
            value: staffValue,
            data: (items) {
               return _StaffTabBody(items: items, searchQuery: searchQuery, ref: ref);
            },
          ),
      ],
    );

    return DefaultTabController(
      length: isAdmin ? 3 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? "School Directory" : "Students"),
          bottom: isAdmin
              ? const TabBar(
                  tabs: [
                    Tab(text: "Students"),
                    Tab(text: "Classes"),
                    Tab(text: "Staff"),
                  ],
                )
              : null,
        ),
        body: content,
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                heroTag: "students_fab",
                onPressed: () => _showAddStudentDialog(context, ref),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text("New Student"),
              )
            : null,
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddStudentSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onSelected, this.icon});
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: icon != null ? Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.black45) : null,
      selectedColor: const Color(0xFF003D5B),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (val) => ref.read(_studentSearchProvider.notifier).state = val,
        decoration: const InputDecoration(
          labelText: "Search directory",
          hintText: "Enter name, ID or email...",
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesMap = ref.watch(allClassesMapProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)),
        ),
        leading: CircleAvatar(
          backgroundColor: student.branchId == "girls" 
              ? Colors.pink.withOpacity(0.1) 
              : const Color(0xFF003D5B).withOpacity(0.1),
          child: Icon(
            student.branchId == "girls" ? Icons.female : Icons.male,
            color: student.branchId == "girls" ? Colors.pink : const Color(0xFF003D5B),
          ),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: "ID: ${student.studentId}", color: const Color(0xFFD4AF37)),
              StatusChip(label: classesMap[student.classId] ?? "Grade ${student.classId}", color: const Color(0xFF003D5B)),
              StatusChip(label: student.isJunior ? "Junior" : "Senior", color: student.isJunior ? Colors.orange : Colors.indigo),
              StatusChip(label: student.parentName, color: const Color(0xFF00A86B)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        isThreeLine: true,
      ),
    );
  }
}

class _ClassSummaryTile extends ConsumerWidget {
  const _ClassSummaryTile({
    required this.classId,
    required this.students,
    required this.teacher,
    required this.allStaff,
    super.key,
  });

  final String classId;
  final List<Student> students;
  final AppUser teacher;
  final List<AppUser> allStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesMap = ref.watch(allClassesMapProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_outlined, color: Color(0xFFD4AF37), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classesMap[classId] ?? "Grade $classId", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF003D5B))
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.people_alt_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text("${students.length} Students enrolled", style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Colors.black12),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Class Teacher", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: teacher.uid == "unknown" ? null : () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => TeacherProfileScreen(teacher: teacher))),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user, size: 14, color: teacher.uid == "unknown" ? Colors.black26 : const Color(0xFF00A86B)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                teacher.uid == "unknown" ? "Not Assigned" : teacher.displayName,
                                style: TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w700, 
                                  color: teacher.uid == "unknown" ? Colors.black45 : const Color(0xFF003D5B),
                                  decoration: teacher.uid == "unknown" ? null : TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showManageSubjects(context, ref),
                      icon: const Icon(Icons.auto_stories, size: 14),
                      label: const Text("Subjects", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFF003D5B)),
                        foregroundColor: const Color(0xFF003D5B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _pickTeacher(context, ref, true),
                      icon: const Icon(Icons.swap_horiz, size: 14),
                      label: Text(teacher.uid == "unknown" ? "Assign CT" : "Change CT", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickTeacher(BuildContext context, WidgetRef ref, bool forClassTeacher, {String? subjectName}) {
    showDialog(
      context: context,
      builder: (ctx) => _TeacherSelectionDialog(
        allStaff: allStaff,
        onTeacherSelected: (newTeacher) {
          if (forClassTeacher) {
            ref.read(adminToolsControllerProvider.notifier).assignClassTeacher(classId, newTeacher.uid);
          } else if (subjectName != null) {
             final updatedSubjects = Map<String, String>.from(ref.read(schoolClassesProvider).value!.firstWhere((c) => c.id == classId).subjects);
             updatedSubjects[subjectName] = newTeacher.uid;
             ref.read(adminToolsControllerProvider.notifier).updateClassSubjects(classId, updatedSubjects);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showManageSubjects(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManageSubjectsSheet(
        classId: classId,
        allStaff: allStaff,
      ),
    );
  }
}

class _TeacherSelectionDialog extends StatelessWidget {
  const _TeacherSelectionDialog({required this.allStaff, required this.onTeacherSelected});
  final List<AppUser> allStaff;
  final Function(AppUser) onTeacherSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Teacher"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: allStaff.length,
          itemBuilder: (context, index) {
            final teacher = allStaff[index];
            return ListTile(
              leading: CircleAvatar(child: Text(teacher.displayName[0])),
              title: Text(teacher.displayName),
              subtitle: Text(teacher.primarySubject ?? "Faculty"),
              onTap: () => onTeacherSelected(teacher),
            );
          },
        ),
      ),
    );
  }
}

class _ManageSubjectsSheet extends ConsumerWidget {
  const _ManageSubjectsSheet({required this.classId, required this.allStaff});
  final String classId;
  final List<AppUser> allStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = ref.watch(schoolClassesProvider).value!.firstWhere((c) => c.id == classId);
    final subjects = cls.subjects;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Assign Subject Teachers", style: Theme.of(context).textTheme.headlineSmall),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in subjects.entries)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(allStaff.firstWhere((s) => s.uid == entry.value, orElse: () => const AppUser(uid: "unknown", schoolId: "", role: UserRole.unknown, displayName: "Not Assigned", email: "", phone: "")).displayName),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => _TeacherSelectionDialog(
                      allStaff: allStaff,
                      onTeacherSelected: (newTeacher) {
                        final updated = Map<String, String>.from(subjects);
                        updated[entry.key] = newTeacher.uid;
                        ref.read(adminToolsControllerProvider.notifier).updateClassSubjects(classId, updated);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffTabBody extends StatelessWidget {
  const _StaffTabBody({required this.items, required this.searchQuery, required this.ref});
  final List<AppUser> items;
  final String searchQuery;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // Deduplicate by UID
    final uniqueItems = <String, AppUser>{};
    for (var u in items) {
      if (u.role == UserRole.teacher || u.role == UserRole.admin) {
        uniqueItems[u.displayName.trim().toLowerCase()] = u;
      }
    }
    
    final filtered = uniqueItems.values.where((s) => 
        s.displayName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
        
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenIntroCard(
          eyebrow: "Faculty Directory",
          title: "Staff Members",
          description: "Browse teaching and administrative personnel, view assignments, and contact details.",
          icon: Icons.badge_outlined,
          accent: Color(0xFF00A86B),
        ),
        const SizedBox(height: 24),
        if (filtered.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No staff members match your search."))),
        for (final user in filtered) _StaffCard(user: user),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfileScreen(teacher: user))),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF00A86B))),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.role.name.toUpperCase()),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
      ),
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet();
  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  // Mock simple state for adding student dialog
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(24), child: const Text("Add Student Form Placeholder"));
  }
}
