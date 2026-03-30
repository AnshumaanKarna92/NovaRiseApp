import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/profile/presentation/controllers/profile_update_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({required this.teacher, super.key});
  final AppUser teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(teacher.displayName),
        backgroundColor: const Color(0xFF003D5B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileHeader(teacher: teacher, isAdmin: isAdmin),
          const SizedBox(height: 32),
          Text(
            "Faculty Member Details",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: "Expertise Hub (Subjects)",
                    value: teacher.subjects.isNotEmpty ? teacher.subjects.join(", ") : (teacher.primarySubject ?? "Not assigned"),
                    icon: Icons.book_outlined,
                    customValueWidget: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (teacher.subjects.isNotEmpty ? teacher.subjects : (teacher.primarySubject?.split(",") ?? ["Not assigned"]))
                            .map((s) => Chip(
                                  label: Text(s.trim(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                  backgroundColor: const Color(0xFF003D5B),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ),
                    onEdit: isAdmin ? () => _showEditInfoSheet(context, ref, "Subjects (comma separated)", teacher.subjects.join(", "), (val) {
                      final list = val.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      ref.read(profileUpdateControllerProvider.notifier).updateStaffProfile(uid: teacher.uid, subjects: list, primarySubject: list.isNotEmpty ? list.first : "");
                    }) : null,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Mobile Number",
                    value: teacher.phone ?? "Not set",
                    icon: Icons.phone_outlined,
                    onEdit: isAdmin ? () => _showEditInfoSheet(context, ref, "Phone Number", teacher.phone, (val) => ref.read(profileUpdateControllerProvider.notifier).updateStaffProfile(uid: teacher.uid, phone: val)) : null,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Internal UID",
                    value: teacher.uid,
                    icon: Icons.vpn_key_outlined,
                  ),
                  const Divider(),
          _DetailRow(
            label: "Account Status",
            value: "ACTIVE",
            icon: Icons.verified_user_outlined,
          ),
          const Divider(),
          _AssignedClassesRow(teacher: teacher, isAdmin: isAdmin),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ScreenIntroCard(
            title: "Administrative Access",
            description: "As an administrator, you can modify faculty profiles and assign teaching responsibilities. Changes are reflected in real-time.",
            icon: Icons.admin_panel_settings,
            accent: const Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  void _showEditInfoSheet(BuildContext context, WidgetRef ref, String label, String? currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Edit $label", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Update Faculty Profile"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.teacher, required this.isAdmin});
  final AppUser teacher;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher = teacher.role == UserRole.teacher;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF003D5B),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: teacher.profileImageUrl.isNotEmpty
                  ? NetworkImage(teacher.profileImageUrl)
                  : null,
              child: teacher.profileImageUrl.isEmpty
                  ? Text(
                      teacher.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF003D5B)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            teacher.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTeacher ? "Academic Faculty" : "Staff Member",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: () {
                    final controller = TextEditingController(text: teacher.displayName);
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: controller, decoration: const InputDecoration(labelText: "Display Name")),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                ref.read(profileUpdateControllerProvider.notifier).updateStaffProfile(uid: teacher.uid, displayName: controller.text.trim());
                                Navigator.pop(context);
                              },
                              child: const Text("Update Name"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

 class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.icon, this.onEdit, this.customValueWidget});
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onEdit;
  final Widget? customValueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: Colors.black45),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                if (customValueWidget != null)
                  customValueWidget!
                else
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD4AF37)),
            ),
        ],
      ),
    );
  }
}
class _AssignedClassesRow extends ConsumerWidget {
  const _AssignedClassesRow({required this.teacher, required this.isAdmin});
  final AppUser teacher;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClassesValue = ref.watch(schoolClassesProvider);
    final classesMap = ref.watch(allClassesMapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.class_outlined, size: 14, color: Colors.black45),
                const SizedBox(width: 8),
                const Text("Assigned Classes (Dashboard)", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
            if (isAdmin)
              IconButton(
                onPressed: () => _showManageClassesSheet(context, ref, allClassesValue),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD4AF37)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (teacher.assignedClassIds.isEmpty)
          const Text("No classes assigned for dashboard access", style: TextStyle(fontSize: 14, color: Colors.black38))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teacher.assignedClassIds.map((id) => Chip(
              label: Text(classesMap[id] ?? "Grade $id", style: const TextStyle(fontSize: 11)),
              backgroundColor: const Color(0xFF003D5B).withOpacity(0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )).toList(),
          ),
      ],
    );
  }

  void _showManageClassesSheet(BuildContext context, WidgetRef ref, AsyncValue<List<SchoolClass>> allClassesValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ManageAssignedClassesSheet(
        teacher: teacher,
        allClassesValue: allClassesValue,
      ),
    );
  }
}

class _ManageAssignedClassesSheet extends ConsumerStatefulWidget {
  const _ManageAssignedClassesSheet({required this.teacher, required this.allClassesValue});
  final AppUser teacher;
  final AsyncValue<List<SchoolClass>> allClassesValue;

  @override
  ConsumerState<_ManageAssignedClassesSheet> createState() => _ManageAssignedClassesSheetState();
}

class _ManageAssignedClassesSheetState extends ConsumerState<_ManageAssignedClassesSheet> {
  late List<String> _selectedIds;
  String _branchFilter = "all"; // all, boys, girls

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.teacher.assignedClassIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Manage Dashboard Assignments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Teachers will see these classes on their home dashboard and attendance screens.", style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(label: "All", selected: _branchFilter == "all", onSelected: () => setState(() => _branchFilter = "all")),
              const SizedBox(width: 8),
              _FilterChip(label: "Boys", selected: _branchFilter == "boys", onSelected: () => setState(() => _branchFilter = "boys")),
              const SizedBox(width: 8),
              _FilterChip(label: "Girls", selected: _branchFilter == "girls", onSelected: () => setState(() => _branchFilter = "girls")),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: widget.allClassesValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
              data: (classes) {
                final filtered = classes.where((c) {
                  if (_branchFilter == "all") return true;
                  return c.branchId == _branchFilter;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cls = filtered[index];
                    final isSelected = _selectedIds.contains(cls.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(cls.displayName),
                      subtitle: Text(cls.branchId.toUpperCase()),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(cls.id);
                          } else {
                            _selectedIds.remove(cls.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(profileUpdateControllerProvider.notifier).updateStaffProfile(
                uid: widget.teacher.uid,
                assignedClassIds: _selectedIds,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save Assignments"),
          ),
        ],
      ),
    );
  }
}
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFF003D5B),
      backgroundColor: Colors.grey.withOpacity(0.1),
      showCheckmark: false,
    );
  }
}
