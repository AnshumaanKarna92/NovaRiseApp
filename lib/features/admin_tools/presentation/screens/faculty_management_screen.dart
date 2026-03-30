import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "teacher_profile_screen.dart";

class FacultyManagementScreen extends ConsumerWidget {
  const FacultyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffValue = ref.watch(allStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Internal Faculty Directory"),
        backgroundColor: const Color(0xFF003D5B),
        foregroundColor: Colors.white,
      ),
      body: AsyncValueView<List<AppUser>>(
        value: staffValue,
        data: (staff) {
          // De-duplicate by name to handle multiple branch assignments
          final uniqueStaff = <String, AppUser>{};
          for (var s in staff) {
            uniqueStaff[s.displayName.trim().toLowerCase()] = s;
          }
          final staffList = uniqueStaff.values.toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));

          if (staffList.isEmpty) {
            return const Center(child: Text("No faculty members found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final member = staffList[index];
              final isTeacher = member.role.name == "teacher";
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () {
                    debugPrint("FACULTY_SCREEN: Opening profile for ${member.displayName} (UID: ${member.uid})");
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TeacherProfileScreen(teacher: member)),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: (isTeacher ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.1),
                    child: Icon(
                      isTeacher ? Icons.school : Icons.admin_panel_settings,
                      color: isTeacher ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member.primarySubject ?? member.role.name.toUpperCase()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
