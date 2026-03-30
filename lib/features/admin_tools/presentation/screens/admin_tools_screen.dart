import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/shared/widgets/receipt_view.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/features/admin_tools/presentation/controllers/admin_tools_controller.dart";
import "package:nova_rise_app/features/admin_tools/presentation/screens/fee_verification_screen.dart";
import "package:nova_rise_app/features/admin_tools/presentation/screens/faculty_management_screen.dart";
import "package:nova_rise_app/shared/widgets/filter_bar.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
import "package:nova_rise_app/features/admin_tools/presentation/screens/class_management_screen.dart";

class AdminToolsScreen extends ConsumerWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final pendingPayments = ref.watch(pendingFeePaymentsProvider);
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
    final studentNames = {for (final student in students) student.studentId: student.name};
    final importJobs = ref.watch(importJobsProvider);
    final importSubmission = ref.watch(importSubmissionControllerProvider);

    final isTab = !Navigator.of(context).canPop();

    ref.listen<AdminActionState>(adminToolsControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(adminToolsControllerProvider.notifier).clear();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });
    ref.listen<ImportSubmissionState>(importSubmissionControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(importSubmissionControllerProvider.notifier).clear();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Operations")),
      body: Column(
        children: [
          const GlobalFilterBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ScreenIntroCard(
            title: "School Operations",
            description: "Manage fee verifications, student record imports, and monitor communication activity across the school.",
            icon: Icons.admin_panel_settings_outlined,
            accent: Color(0xFFD4AF37),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _StatBox(
                  label: "Queue",
                  value: "${summary["pendingFees"]}",
                  subtitle: "Unverified",
                  icon: Icons.payments_outlined,
                  accent: const Color(0xFFD4AF37),
                ),
                _StatBox(
                  label: "Notices",
                  value: "${summary["notices"]}",
                  subtitle: "Published",
                  icon: Icons.campaign_outlined,
                  accent: const Color(0xFF003D5B),
                ),
                _StatBox(
                  label: "Comm Vol",
                  value: "${summary["messages"]}",
                  subtitle: "Total Entries",
                  icon: Icons.forum_outlined,
                  accent: const Color(0xFF00A86B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Pending Fee Reviews",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AsyncValueView(
            value: pendingPayments,
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Color(0xFF00A86B)),
                    title: Text("All payments verified."),
                    subtitle: Text("Verification queue is currently empty."),
                  ),
                );
              }
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payments, color: Color(0xFFD4AF37)),
                  title: Text("${items.length} payments pending review", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Tap to open verification queue"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeVerificationScreen()));
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "Bulk Fee Operations",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showDeployFeesDialog(context, ref),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text("Deploy Monthly Fees"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(adminToolsControllerProvider.notifier).sendFeeReminders(),
                      icon: const Icon(Icons.notification_add_outlined),
                      label: const Text("Send Reminders"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Daily Financial Operations",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecordCashDialog(context, ref),
                      icon: const Icon(Icons.currency_rupee),
                      label: const Text("Record Manual Fees"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Staff & Teacher Roster",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddStaffDialog(context, ref, UserRole.teacher),
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text("Add Teacher"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddStaffDialog(context, ref, UserRole.admin),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text("Add Admin"),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyManagementScreen()));
                          },
                          icon: const Icon(Icons.badge_outlined),
                          label: const Text("Faculty Directory"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen()));
                          },
                          icon: const Icon(Icons.class_outlined),
                          label: const Text("Manage Classes"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            "Maintenance & Integration",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[50],
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Colors.black45),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Infrequent operations. Use Student CSV sync for bulk institutional database updates.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importSubmission.isSubmitting
                          ? null
                          : () => _showCsvFormatDialog(context, ref),
                      icon: const Icon(Icons.sync_alt),
                      label: Text(importSubmission.isSubmitting ? "Processing..." : "Sync Institutional CSV"),
                    ),
                  ),
                  if (importJobs.valueOrNull?.isNotEmpty ?? false) ...[
                    const Divider(height: 32),
                    AsyncValueView(
                      value: importJobs,
                      data: (items) => Column(
                        children: items.take(2).map((job) => ListTile(
                          dense: true,
                          leading: Icon(
                            job.status == "completed" ? Icons.check_circle_outline : Icons.pending_outlined,
                            size: 18,
                            color: job.status == "completed" ? Colors.green : Colors.orange,
                          ),
                          title: Text(job.type == "students" ? "Student Directory Sync" : job.type, style: const TextStyle(fontSize: 12)),
                          subtitle: Text("Processed: ${job.successCount} | Errors: ${job.failureCount}", style: const TextStyle(fontSize: 10)),
                        )).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
);
  }

  void _showAddStaffDialog(BuildContext context, WidgetRef ref, UserRole role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StaffEntrySheet(role: role),
    );
  }

  Future<void> _verifyPayment(WidgetRef ref, String paymentId, String decision) async {
    await ref.read(adminToolsControllerProvider.notifier).verify(
          paymentId: paymentId,
          decision: decision,
          notes: decision == "verified" ? "Verified from admin tools" : "Rejected from admin tools",
        );
  }

  void _showRecordCashDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CashEntrySheet(),
    );
  }

  void _showDeployFeesDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DeployFeesSheet(),
    );
  }

  void _showCsvFormatDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Student Import Template"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("To synchronize your central database, please prepare a CSV file with the following columns exactly as shown below:"),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text(
                    "studentId, name, dob, classId, parentName, parentPhone, address, enrollmentDate",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Requirements for School Admins:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("• studentId should be the unique admission number."),
                const Text("• dob must follow YYYY-MM-DD (e.g. 2014-08-15)."),
                const Text("• classId should be your standard grade codes (e.g. 8C)."),
                const Text("• Siblings should use the same parentPhone to link accounts."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(importSubmissionControllerProvider.notifier).submitCsv();
              },
              child: const Text("Select & Import File"),
            ),
          ],
        );
      },
    );
  }
}

class _CashEntrySheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CashEntrySheet> createState() => _CashEntrySheetState();
}

class _CashEntrySheetState extends ConsumerState<_CashEntrySheet> {
  String? _selectedClass;
  String? _selectedStudentId;
  final _amountController = TextEditingController();
  final _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminToolsControllerProvider);
    final classes = ref.watch(currentClassIdsProvider);
    final allStudents = ref.watch(currentStudentsProvider).value ?? const [];

    final classStudents = _selectedClass == null ? [] : allStudents.where((s) => s.classId == _selectedClass).toList();
    if (_selectedStudentId != null && !classStudents.any((s) => s.studentId == _selectedStudentId)) {
      _selectedStudentId = null;
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Record Manual Cash", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: const InputDecoration(labelText: "Select Class", prefixIcon: Icon(Icons.class_outlined)),
            items: classes.map((c) => DropdownMenuItem(value: c, child: Text("Class $c"))).toList(),
            onChanged: (val) => setState(() {
              _selectedClass = val;
              _selectedStudentId = null;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStudentId,
            decoration: const InputDecoration(labelText: "Select Student", prefixIcon: Icon(Icons.person_outline)),
            items: classStudents.map((s) => DropdownMenuItem<String>(value: s.studentId, child: Text(s.name))).toList(),
            onChanged: classStudents.isEmpty ? null : (val) => setState(() => _selectedStudentId = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _monthController,
            decoration: const InputDecoration(labelText: "Billing Month (YYYY-MM)", prefixIcon: Icon(Icons.calendar_month)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Amount Collected (INR)", prefixText: "₹ "),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting || _selectedStudentId == null || _amountController.text.isEmpty
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      final adminUser = ref.read(userProfileProvider).value;
                      final monthStr = _monthController.text.trim();
                      final invoiceId = "INV_${_selectedStudentId}_$monthStr";
                      
                      await ref.read(adminToolsControllerProvider.notifier).recordCashPayment(
                            studentId: _selectedStudentId!,
                            invoiceId: invoiceId,
                            amount: amount,
                            collectorName: adminUser?.displayName ?? "Admin Official",
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(state.isSubmitting ? "Recording..." : "Verify & Save Cash Entry"),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 140,
        child: MiniStatCard(
          label: label,
          value: value,
          subtitle: subtitle,
          icon: icon,
          accent: accent,
        ),
      ),
    );
  }
}

class _StaffEntrySheet extends ConsumerStatefulWidget {
  const _StaffEntrySheet({required this.role});
  final UserRole role;

  @override
  ConsumerState<_StaffEntrySheet> createState() => _StaffEntrySheetState();
}

class _StaffEntrySheetState extends ConsumerState<_StaffEntrySheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedClassId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesValue = ref.watch(schoolClassesProvider);
    final classes = classesValue.valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                widget.role == UserRole.teacher ? Icons.school_outlined : Icons.admin_panel_settings_outlined,
                color: const Color(0xFF003D5B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Provision New ${widget.role.name.toUpperCase()}", 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Staff Full Name",
              prefixIcon: Icon(Icons.person_outline),
              hintText: "Enter official name",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: widget.role == UserRole.teacher ? TextInputType.phone : TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: widget.role == UserRole.teacher ? "Phone Number (Login ID)" : "Staff Handle / Email",
              prefixIcon: Icon(widget.role == UserRole.teacher ? Icons.phone_android : Icons.alternate_email),
              hintText: widget.role == UserRole.teacher ? "10-digit number" : "e.g. teacher_john or john@school.com",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: "Security Password",
              prefixIcon: Icon(Icons.lock_outline),
              hintText: "Default: password123",
            ),
          ),
          if (widget.role == UserRole.teacher) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Primary Subject",
                prefixIcon: Icon(Icons.book_outlined),
                hintText: "e.g. Mathematics, Science",
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedClassId,
              decoration: const InputDecoration(
                labelText: "Assigned Class Teacher To",
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("Not Assigned (Regular Staff)")),
                ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
              ],
              onChanged: (val) => setState(() => _selectedClassId = val),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
            label: Text(_isSubmitting ? "Generating Credentials..." : "Finalize & Provision Account"),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    // Auto-generate ID if handle is empty
    String handle = _emailController.text.trim();
    if (handle.isEmpty) {
      handle = name.toLowerCase().replaceAll(' ', '.');
    }
    
    final primarySubject = _subjectController.text.trim();
    if (widget.role == UserRole.teacher && primarySubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Primary subject is mandatory for teachers.")));
      return;
    }

    final password = _passwordController.text.trim().isEmpty ? "password123" : _passwordController.text.trim();
    final email = handle.contains("@") ? handle : "$handle@novarise.com";
    
    setState(() => _isSubmitting = true);
    try {
      final assignedClasses = _selectedClassId != null ? [_selectedClassId!] : <String>[];
      
      await ref.read(authServiceProvider).createUser(
        email: email,
        password: password,
        displayName: name,
        role: widget.role,
        assignedClassIds: assignedClasses,
        primarySubject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
      );

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

class _DeployFeesSheet extends ConsumerStatefulWidget {
  const _DeployFeesSheet();

  @override
  ConsumerState<_DeployFeesSheet> createState() => _DeployFeesSheetState();
}

class _DeployFeesSheetState extends ConsumerState<_DeployFeesSheet> {
  final _amountController = TextEditingController(text: "5000");
  final _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminToolsControllerProvider);

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
          Text("Deploy Monthly Fees", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Generate new invoices for all active students."),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Default Invoice Amount (INR)", prefixIcon: Icon(Icons.currency_rupee)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthController,
            decoration: const InputDecoration(labelText: "Billing Month (YYYY-MM)", prefixIcon: Icon(Icons.calendar_month)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text) ?? 5000.0;
                      await ref.read(adminToolsControllerProvider.notifier).generateMonthlyFees(
                            amount: amount,
                            monthYearValue: _monthController.text.trim(),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(state.isSubmitting ? "Deploying..." : "Generate Invoices"),
            ),
          ),
        ],
      ),
    );
  }
}
