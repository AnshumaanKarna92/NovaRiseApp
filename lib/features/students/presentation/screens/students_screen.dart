import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../controllers/student_controller.dart";

import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/models/app_user.dart";

final _studentSearchProvider = StateProvider.autoDispose<String>((ref) => "");

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsValue = ref.watch(currentStudentsProvider);
    final searchQuery = ref.watch(_studentSearchProvider).toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Students")),
      body: AsyncValueView(
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
                eyebrow: "Roster View",
                title: "Directory",
                description: "Search and browse student records, class assignments, and guardian information.",
                icon: Icons.groups_2_outlined,
                accent: Color(0xFF003D5B),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (val) => ref.read(_studentSearchProvider.notifier).state = val,
                decoration: const InputDecoration(
                  labelText: "Search Students",
                  hintText: "Enter name or ID...",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 24),
              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("No students matching your search."),
                  ),
                )
              else
                for (final student in filtered)
                  Card(
                    child: ListTile(
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
                            StatusChip(label: "Class ${student.classId}", color: const Color(0xFF003D5B)),
                            StatusChip(label: "ID ${student.studentId}", color: const Color(0xFFD4AF37)),
                            StatusChip(label: student.parentName, color: const Color(0xFF00A86B)),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: ref.watch(userProfileProvider).value?.role == UserRole.admin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddStudentDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text("New Student"),
            )
          : null,
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
