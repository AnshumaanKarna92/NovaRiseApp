import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../../shared/widgets/receipt_view.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/models/app_user.dart";
import "../controllers/admin_tools_controller.dart";

class AdminToolsScreen extends ConsumerWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final pendingPayments = ref.watch(pendingFeePaymentsProvider);
    final students = ref.watch(currentStudentsProvider).value ?? const [];
    final studentNames = {for (final student in students) student.studentId: student.name};
    final importJobs = ref.watch(importJobsProvider);
    final importSubmission = ref.watch(importSubmissionControllerProvider);

    final isTab = !Navigator.of(context).canPop();

    ref.listen<FeeVerificationState>(feeVerificationControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(feeVerificationControllerProvider.notifier).clear();
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ScreenIntroCard(
            title: "School Operations",
            description: "Manage fee verifications, student record imports, and monitor communication activity across the school.",
            icon: Icons.admin_panel_settings_outlined,
            accent: Color(0xFFD4AF37),
          ),
          const SizedBox(height: 24),
          summary.when(
            data: (data) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _StatBox(
                    label: "Queue",
                    value: "${data["pendingFees"]}",
                    subtitle: "Unverified",
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFFD4AF37),
                  ),
                  _StatBox(
                    label: "Notices",
                    value: "${data["notices"]}",
                    subtitle: "Published",
                    icon: Icons.campaign_outlined,
                    accent: const Color(0xFF003D5B),
                  ),
                  _StatBox(
                    label: "Comm Vol",
                    value: "${data["messages"]}",
                    subtitle: "Total Entries",
                    icon: Icons.forum_outlined,
                    accent: const Color(0xFF00A86B),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
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
                    title: Text("All payments verified."),
                    subtitle: Text("Verification queue is currently empty."),
                  ),
                );
              }
              return Column(
                children: items.map((payment) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  studentNames[payment.studentId] ?? payment.studentId,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const StatusChip(label: "REVIEW", color: Color(0xFFD4AF37)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusChip(label: "INR ${payment.amount.toStringAsFixed(0)}", color: const Color(0xFF00A86B)),
                              StatusChip(label: payment.paymentMethod.toUpperCase(), color: const Color(0xFF003D5B)),
                              if (payment.clientReference.isNotEmpty)
                                StatusChip(label: payment.clientReference, color: Colors.grey),
                            ],
                          ),
                          if (payment.screenshotUrl.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ReceiptView(url: payment.screenshotUrl),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _verifyPayment(ref, payment.paymentId, "verified"),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text("Verify"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _verifyPayment(ref, payment.paymentId, "rejected"),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text("Reject"),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "User & Staff Management",
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
                      onPressed: () => _showAddStaffDialog(context, ref, UserRole.teacher),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text("New Teacher"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddStaffDialog(context, ref, UserRole.admin),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text("New Admin"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Data & Import Maintenance",
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
                        child: FilledButton.icon(
                          onPressed: importSubmission.isSubmitting
                              ? null
                              : () => ref.read(importSubmissionControllerProvider.notifier).submitCsv(),
                          icon: const Icon(Icons.upload_file),
                          label: Text(importSubmission.isSubmitting ? "Import Students CSV" : "Import CSV"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRecordCashDialog(context, ref),
                          icon: const Icon(Icons.currency_rupee),
                          label: const Text("Record Cash"),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  AsyncValueView(
                    value: importJobs,
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text("No recent import activity.");
                      }
                      return Column(
                        children: items.take(3).map((job) {
                          return ListTile(
                            leading: Icon(
                              job.status == "completed" ? Icons.check_circle : Icons.sync,
                              color: job.status == "completed" ? const Color(0xFF00A86B) : const Color(0xFFD4AF37),
                            ),
                            title: Text(job.type),
                            subtitle: Text("Success: ${job.successCount} | Failed: ${job.failureCount}"),
                            trailing: Text(job.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
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
    await ref.read(feeVerificationControllerProvider.notifier).verify(
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
}

class _CashEntrySheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CashEntrySheet> createState() => _CashEntrySheetState();
}

class _CashEntrySheetState extends ConsumerState<_CashEntrySheet> {
  final _studentIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _invoiceIdController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _amountController.dispose();
    _invoiceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feeVerificationControllerProvider);

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
          Text("Record Manual Cash Payment", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(
              labelText: "Student ID",
              hintText: "e.g. STU_1001",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _invoiceIdController,
            decoration: const InputDecoration(
              labelText: "Invoice ID (Optional)",
              hintText: "e.g. INV_APR24_STU1001",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Amount Collected (INR)",
              prefixText: "₹ ",
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      if (_studentIdController.text.isEmpty || _amountController.text.isEmpty) {
                        return;
                      }
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      final adminUser = ref.read(userProfileProvider).value;
                      await ref.read(feeVerificationControllerProvider.notifier).recordCashPayment(
                            studentId: _studentIdController.text.trim(),
                            invoiceId: _invoiceIdController.text.trim().isEmpty
                                ? "INV_MISC_${DateTime.now().millisecondsSinceEpoch}"
                                : _invoiceIdController.text.trim(),
                            amount: amount,
                            collectorName: adminUser?.displayName ?? "Admin Official",
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
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
  final _passwordController = TextEditingController();
  final _classIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _classIdController.dispose();
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
          Text("Provision New ${widget.role.name.toUpperCase()}", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Full Name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email or Staff ID",
              hintText: "e.g. teacher_abc or test@school.com",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Initial Secret / Password"),
            obscureText: true,
          ),
          if (widget.role == UserRole.teacher) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _classIdController,
              decoration: const InputDecoration(
                labelText: "Assigned Class ID (Optional)",
                hintText: "e.g. CLASS_10A",
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? "Provisioning..." : "Provision Account"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.contains("@") ? _emailController.text : "${_emailController.text}@novarise.com";
      
      final classes = _classIdController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      // Directly using AuthService to create user
      await ref.read(authServiceProvider).createUser(
        email: email,
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: widget.role,
        assignedClassIds: widget.role == UserRole.teacher ? classes : [],
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
