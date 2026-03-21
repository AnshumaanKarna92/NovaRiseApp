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
import "student_detail_screen.dart";

final _studentSearchProvider = StateProvider.autoDispose<String>((ref) => "");

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;
    final studentsValue = ref.watch(currentStudentsProvider);
    final staffValue = ref.watch(currentStaffProvider);
    final searchQuery = ref.watch(_studentSearchProvider).toLowerCase();

    final content = TabBarView(
      children: [
        AsyncValueView(
          value: studentsValue,
          data: (items) {
            final filtered = items.where((s) {
              return s.name.toLowerCase().contains(searchQuery) ||
                  s.studentId.toLowerCase().contains(searchQuery);
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ScreenIntroCard(
                  eyebrow: "Student Roster",
                  title: "Directory",
                  description: "Search and browse student records, class assignments, and guardian information.",
                  icon: Icons.groups_2_outlined,
                  accent: Color(0xFF003D5B),
                ),
                const SizedBox(height: 20),
                _SearchBar(ref: ref),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No students match your search.")))
                else
                  for (final student in filtered)
                    _StudentCard(student: student),
              ],
            );
          },
        ),
        if (isAdmin)
          AsyncValueView(
            value: ref.watch(schoolClassesProvider),
            data: (classes) => AsyncValueView(
              value: staffValue,
              data: (staffItems) => AsyncValueView(
                value: studentsValue,
                data: (studentItems) {
                  return ListView(
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
                      for (final cls in classes)
                        _ClassSummaryTile(
                          classId: cls.id,
                          students: studentItems.where((s) => s.classId == cls.id).toList(),
                          teacher: staffItems.firstWhere((s) => s.uid == cls.classTeacherId, orElse: () => staffItems.firstWhere((s) => s.assignedClassIds.contains(cls.id), orElse: () => const AppUser(uid: "unknown", schoolId: "", role: UserRole.unknown, displayName: "No Teacher", email: "", phone: "", assignedClassIds: []))),
                          allStaff: staffItems,
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
               // Staff view code...
               // [Existing StaffView logic remains but I'll update it for clarity]
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (val) => ref.read(_studentSearchProvider.notifier).state = val,
      decoration: const InputDecoration(
        labelText: "Search directory",
        hintText: "Enter name, ID or email...",
        prefixIcon: Icon(Icons.search),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF003D5B).withValues(alpha: 0.1),
          child: Text(
            student.name.isEmpty ? "S" : student.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Color(0xFF003D5B), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: classesMap[student.classId] ?? "Grade ${student.classId}", color: const Color(0xFF003D5B)),
              StatusChip(label: "Active Student", color: const Color(0xFFD4AF37)),
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
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.class_outlined, color: Color(0xFFD4AF37)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(classesMap[classId] ?? "Grade $classId", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text("${students.length} Students enrolled", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, size: 16, color: Colors.black45),
                const SizedBox(width: 8),
                Text("Class Teacher: ", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                Expanded(
                  child: Text(teacher.uid == "unknown" ? "Not Assigned" : teacher.displayName, 
                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
                ),
                TextButton.icon(
                  onPressed: () => _pickTeacher(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(teacher.uid == "unknown" ? "Assign" : "Change", style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.book_outlined, size: 16, color: Colors.black45),
                const SizedBox(width: 8),
                const Text("Subjects: ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _manageSubjects(context, ref),
                  icon: const Icon(Icons.settings_outlined, size: 14),
                  label: const Text("Manage Subjects", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _manageSubjects(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManageSubjectsBottomSheet(classId: classId, allStaff: allStaff),
    );
  }

  void _pickTeacher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final teachers = allStaff.where((s) => s.role == UserRole.teacher).toList();
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Class Teacher for ${ref.read(allClassesMapProvider)[classId] ?? classId}", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              if (teachers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No teachers found in the staff directory."),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final t = teachers[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(t.displayName[0])),
                        title: Text(t.displayName),
                        subtitle: Text(t.email),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(adminToolsControllerProvider.notifier).assignClassTeacher(classId, t.uid);
                          ref.read(adminSummaryProvider); // Refresh summary
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffTabBody extends StatelessWidget {
  const _StaffTabBody({
    required this.items,
    required this.searchQuery,
    required this.ref,
  });

  final List<AppUser> items;
  final String searchQuery;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((s) {
      return s.displayName.toLowerCase().contains(searchQuery) ||
          s.email.toLowerCase().contains(searchQuery);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenIntroCard(
          eyebrow: "Staff Directory",
          title: "Faculty & Team",
          description: "View school staff members, their roles, and assigned class responsibilities.",
          icon: Icons.badge_outlined,
          accent: Color(0xFF00A86B),
        ),
        const SizedBox(height: 20),
        _SearchBar(ref: ref),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No staff members match your search.")))
        else
          for (final staff in filtered)
            _StaffCard(staff: staff),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});
  final AppUser staff;

  @override
  Widget build(BuildContext context) {
    final roleColor = staff.role == UserRole.teacher ? const Color(0xFF00A86B) : const Color(0xFF003D5B);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.1),
          child: Text(
            staff.displayName.isEmpty ? "T" : staff.displayName.substring(0, 1).toUpperCase(),
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(staff.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(staff.email, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: staff.role.name.toUpperCase(), color: roleColor),
                  if (staff.role == UserRole.teacher && staff.primarySubject != null)
                    StatusChip(label: staff.primarySubject!, color: const Color(0xFFD4AF37)),
                  if (staff.assignedClassIds.isNotEmpty)
                    StatusChip(label: "Class Assignments: ${staff.assignedClassIds.length}", color: const Color(0xFF003D5B)),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _AddStudentSheet extends ConsumerStatefulWidget {
  const _AddStudentSheet();

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add New Student Record", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: "Student ID (e.g. STU_105)"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Student Full Name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _classController,
            decoration: const InputDecoration(labelText: "Class ID"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parentNameController,
            decoration: const InputDecoration(labelText: "Parent/Guardian Name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parentPhoneController,
            decoration: const InputDecoration(labelText: "Parent Phone Number"),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? "Saving..." : "Create Record"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final schoolId = ref.read(userProfileProvider).value?.schoolId ?? "school_001";
      await ref.read(firebaseFirestoreProvider).collection("students").doc(_idController.text.trim()).set({
        "studentId": _idController.text.trim(),
        "schoolId": schoolId,
        "name": _nameController.text.trim(),
        "classId": _classController.text.trim(),
        "parentName": _parentNameController.text.trim(),
        "parentPhone": _parentPhoneController.text.trim(),
        "parentUserIds": [],
        "status": "active",
        "createdAt": DateTime.now().toIso8601String(), // Simple string for now, backend uses serverTimestamp
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ManageSubjectsBottomSheet extends ConsumerStatefulWidget {
  const _ManageSubjectsBottomSheet({required this.classId, required this.allStaff});
  final String classId;
  final List<AppUser> allStaff;

  @override
  ConsumerState<_ManageSubjectsBottomSheet> createState() => _ManageSubjectsBottomSheetState();
}

class _ManageSubjectsBottomSheetState extends ConsumerState<_ManageSubjectsBottomSheet> {
  final _subjectController = TextEditingController();
  String? _selectedTeacherUid;

  @override
  Widget build(BuildContext context) {
    final classesValue = ref.watch(schoolClassesProvider);
    final classesMap = ref.watch(allClassesMapProvider);
    final state = ref.watch(adminToolsControllerProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueView(
          value: classesValue,
          data: (classes) {
            final schoolClass = classes.firstWhere((c) => c.id == widget.classId, orElse: () => SchoolClass(id: widget.classId, schoolId: "", name: ""));
            final subjects = schoolClass.subjects;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Subjects in ${classesMap[widget.classId] ?? widget.classId}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (subjects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text("No subjects assigned yet.")),
                  )
                else
                  ...subjects.entries.map((e) {
                    final t = widget.allStaff.firstWhere((s) => s.uid == e.value, orElse: () => const AppUser(uid: "unknown", schoolId: "", role: UserRole.unknown, displayName: "Unknown", email: "", phone: "", assignedClassIds: []));
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.displayName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          final newSubjects = Map<String, String>.from(subjects)..remove(e.key);
                          ref.read(adminToolsControllerProvider.notifier).updateClassSubjects(widget.classId, newSubjects);
                        },
                      ),
                    );
                  }),
                const Divider(height: 32),
                const Text("Add New Subject", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: "Subject Name (e.g. Science)"),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Subject Teacher", prefixIcon: Icon(Icons.person_pin_outlined)),
                  value: _selectedTeacherUid,
                  items: widget.allStaff
                      .where((s) => s.role == UserRole.teacher)
                      .map((s) => DropdownMenuItem(value: s.uid, child: Text("${s.displayName} (${s.primarySubject ?? 'No Subject'})")))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTeacherUid = val;
                      final teacher = widget.allStaff.firstWhere((s) => s.uid == val);
                      if (teacher.primarySubject != null) {
                        _subjectController.text = teacher.primarySubject!;
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.isSubmitting || _selectedTeacherUid == null || _subjectController.text.isEmpty
                      ? null
                      : () async {
                          final newSubjects = Map<String, String>.from(subjects)..[_subjectController.text.trim()] = _selectedTeacherUid!;
                          await ref.read(adminToolsControllerProvider.notifier).updateClassSubjects(widget.classId, newSubjects);
                          _subjectController.clear();
                          setState(() => _selectedTeacherUid = null);
                        },
                  icon: state.isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                  label: const Text("Add Subject Assignment"),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}
