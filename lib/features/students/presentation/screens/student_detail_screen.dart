import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/core/models/fee_invoice.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/attendance/presentation/controllers/attendance_controller.dart";
import "package:nova_rise_app/features/fees/presentation/controllers/fees_controller.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/profile/presentation/controllers/profile_update_controller.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({required this.student, super.key});
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesValue = ref.watch(feeInvoicesProvider);
    final attendanceValue = ref.watch(attendanceSummariesProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.cashCollector;
    final isParentOfStudent = user?.role == UserRole.parent && user!.linkedStudentIds.contains(student.studentId);
    
    final canEdit = isAdmin || isParentOfStudent;

    return Scaffold(
      appBar: AppBar(title: Text(student.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileHeader(student: student, canEdit: canEdit),
          const SizedBox(height: 32),
          
          Text(
            "Student Information",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: "Branch / Gender", 
                    value: student.branchId.toUpperCase(),
                    icon: student.branchId == "girls" ? Icons.female : Icons.male,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Blood Group", 
                    value: student.bloodGroup ?? "Not set",
                    onEdit: canEdit ? () => _showEditInfoSheet(context, ref, "Blood Group", student.bloodGroup, (val) => ref.read(profileUpdateControllerProvider.notifier).updateStudentProfile(studentId: student.studentId, bloodGroup: val)) : null,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Contact", 
                    value: student.parentPhone,
                    onEdit: canEdit ? () => _showEditInfoSheet(context, ref, "Parent Phone", student.parentPhone, (val) => ref.read(profileUpdateControllerProvider.notifier).updateStudentProfile(studentId: student.studentId, parentPhone: val)) : null,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Parent/Guardian", 
                    value: student.parentName,
                    onEdit: canEdit ? () => _showEditInfoSheet(context, ref, "Parent Name", student.parentName, (val) => ref.read(profileUpdateControllerProvider.notifier).updateStudentProfile(studentId: student.studentId, parentName: val)) : null,
                  ),
                ],
              ),
            ),
          ),
          
          Text(
            "Fees & Enrollment",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: "Roll Number", 
                    value: student.rollNo ?? "N/A",
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Monthly School Fees", 
                    value: "₹${student.monthlyFees.toStringAsFixed(0)}",
                    icon: Icons.currency_rupee,
                    onEdit: isAdmin ? () => _showEditInfoSheet(context, ref, "Monthly Fees", student.monthlyFees.toString(), (val) => ref.read(profileUpdateControllerProvider.notifier).updateStudentProfile(studentId: student.studentId, monthlyFees: double.tryParse(val))) : null,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Admission Date", 
                    value: student.admissionDate ?? "N/A",
                    icon: Icons.calendar_today_outlined,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: "Student Type", 
                    value: student.studentType.toUpperCase(),
                    icon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            "Attendance Overview",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AsyncValueView(
            value: attendanceValue,
            data: (summaries) {
              return _StatOverview(
                label: "Attendance",
                value: "92%",
                subtitle: "Overall presence",
                icon: Icons.fact_check_outlined,
                accent: const Color(0xFF00A86B),
              );
            },
          ),
          const SizedBox(height: 32),
          if (isAdmin) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Danger Zone",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.red.withOpacity(0.02),
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.red.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () => _confirmDeleteStudent(context, ref),
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                title: const Text("Permanently Delete Profile", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Delete student record, all fee logs, and associated parent linkages. This cannot be undone.", style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteStudent(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion?"),
        content: Text("Are you sure you want to permanently delete the profile of ${student.name}? ALL academic and fee records will be removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ref.read(profileUpdateControllerProvider.notifier).deleteStudent(student.studentId);
              if (context.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back from profile
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student profile deleted successfully.")));
              }
            },
            child: const Text("DELETE PROFILE"),
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
              child: const Text("Save Student Details"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.student, required this.canEdit});
  final Student student;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(profileUpdateControllerProvider);
    final classesMap = ref.watch(allClassesMapProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF003D5B),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: student.profileImageUrl.isNotEmpty
                      ? NetworkImage(student.profileImageUrl)
                      : null,
                  child: student.profileImageUrl.isEmpty
                      ? Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF003D5B)),
                        )
                      : null,
                ),
              ),
              if (canEdit)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => ref.read(profileUpdateControllerProvider.notifier).pickAndUploadStudentPhoto(student.studentId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                      child: updateState.isUploading
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            student.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "ID: ${student.studentId}",
            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Active Student Profile",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (canEdit)
                IconButton(
                  onPressed: () {
                    final controller = TextEditingController(text: student.name);
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: controller, decoration: const InputDecoration(labelText: "Student Name")),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                ref.read(profileUpdateControllerProvider.notifier).updateStudentProfile(studentId: student.studentId, name: controller.text.trim());
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderInfo(label: "SECTION", value: classesMap[student.classId] ?? "Grade ${student.classId}"),
              _HeaderInfo(label: "STATUS", value: student.status.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.icon, this.onEdit});
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
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

class _StatOverview extends StatelessWidget {
  const _StatOverview({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MiniStatCard(
        label: label,
        value: value,
        subtitle: subtitle,
        icon: icon,
        accent: accent,
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});
  final FeeInvoice invoice;

  @override
  Widget build(BuildContext context) {
    bool isPaid = invoice.paymentStatus.contains("paid") || invoice.paymentStatus.contains("verified");
    Color color = isPaid ? const Color(0xFF00A86B) : const Color(0xFFB34747);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isPaid ? Icons.check_circle_outline : Icons.error_outline, color: color),
        title: Text(invoice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Due: ${invoice.dueDate}"),
        trailing: Text("₹${invoice.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
