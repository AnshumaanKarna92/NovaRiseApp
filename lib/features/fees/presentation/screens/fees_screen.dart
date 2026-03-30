import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/fee_invoice.dart";
import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
import "package:nova_rise_app/shared/widgets/filter_bar.dart";
import "package:nova_rise_app/features/fees/presentation/controllers/fee_submission_controller.dart";
import "package:nova_rise_app/features/fees/presentation/controllers/fees_controller.dart";

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fees = ref.watch(feeInvoicesProvider);
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
    final user = ref.watch(userProfileProvider).valueOrNull;
    final studentNames = {
      for (final student in students) student.studentId: student.name,
    };

    final isTab = !Navigator.of(context).canPop();

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Fees")),
      body: AsyncValueView(
        value: fees,
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("No fee invoices found."));
          }
          final isParent = user?.role == UserRole.parent;

          if (!isParent) {
            return _AdminFeesView(items: items, students: students, studentNames: studentNames);
          }

          final pending = items.where((item) => item.paymentStatus.contains("pending")).length;
          final totalAmount = items.fold<double>(0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ScreenIntroCard(
                title: "School Fee Center",
                description: "Review your child's outstanding invoices, upload proof of payment, and track verification status.",
                icon: Icons.receipt_long_outlined,
                accent: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _StatBox(
                      label: "Invoices",
                      value: "${items.length}",
                      subtitle: "Total records",
                      icon: Icons.list_alt_outlined,
                      accent: const Color(0xFF003D5B),
                    ),
                    _StatBox(
                      label: "Pending",
                      value: "$pending",
                      subtitle: "Awaiting",
                      icon: Icons.hourglass_top_outlined,
                      accent: const Color(0xFFD4AF37),
                    ),
                    _StatBox(
                      label: "Total due",
                      value: "₹${totalAmount.toStringAsFixed(0)}",
                      subtitle: "Current balance",
                      icon: Icons.payments_outlined,
                      accent: const Color(0xFF00A86B),
                      width: 180,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Recent Invoices",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final invoice in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    studentNames[invoice.studentId] ?? invoice.studentId,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: _statusLabel(invoice.paymentStatus),
                              color: _statusColor(invoice.paymentStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(label: "Due ${invoice.dueDate}", color: const Color(0xFF003D5B)),
                            StatusChip(
                              label: "INR ${invoice.amount.toStringAsFixed(0)}",
                              color: const Color(0xFF00A86B),
                            ),
                          ],
                        ),
                        if (!invoice.paymentStatus.contains("paid") && !invoice.paymentStatus.contains("verified") && !invoice.paymentStatus.contains("pending")) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _showUploadSheet(
                                context: context,
                                ref: ref,
                                invoice: invoice,
                                studentName:
                                    studentNames[invoice.studentId] ?? invoice.studentId,
                                user: user!,
                              ),
                              child: const Text("Upload receipt"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.contains("paid")) {
      return const Color(0xFF00A86B);
    }
    if (status.contains("pending")) {
      return const Color(0xFFD4AF37);
    }
    if (status.contains("rejected")) {
      return const Color(0xFFB34747);
    }
    return const Color(0xFF003D5B);
  }

  String _statusLabel(String status) {
    if (status.contains("paid")) return "PAYMENT SUCCESSFUL";
    if (status.contains("pending")) return "WAITING VERIFICATION";
    if (status.contains("rejected")) return "PAYMENT REJECTED";
    if (status.isEmpty || status.contains("unpaid")) return "UNPAID";
    return status.replaceAll("_", " ").toUpperCase();
  }

  Future<void> _showUploadSheet({
    required BuildContext context,
    required WidgetRef ref,
    required FeeInvoice invoice,
    required String studentName,
    required AppUser user,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _FeeUploadSheet(
          invoice: invoice,
          studentName: studentName,
          user: user,
        );
      },
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
    this.width = 150,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: width,
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

class _FeeUploadSheet extends ConsumerStatefulWidget {
  const _FeeUploadSheet({
    required this.invoice,
    required this.studentName,
    required this.user,
  });

  final FeeInvoice invoice;
  final String studentName;
  final AppUser user;

  @override
  ConsumerState<_FeeUploadSheet> createState() => _FeeUploadSheetState();
}

class _FeeUploadSheetState extends ConsumerState<_FeeUploadSheet> {
  final _referenceController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FeeSubmissionState>(feeSubmissionControllerProvider, (previous, next) {
      if (next.completedInvoiceId == widget.invoice.invoiceId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receipt submitted for verification.")),
        );
        ref.read(feeSubmissionControllerProvider.notifier).clearResult();
        Navigator.of(context).pop();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final submission = ref.watch(feeSubmissionControllerProvider);

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
          Text(
            "Upload Proof of Payment",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.studentName} • ${widget.invoice.title}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF003D5B).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF003D5B).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.qr_code_2, size: 60, color: Color(0xFF003D5B)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pay via UPI",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Scan this QR or use VPA:\nnovarise@upi",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: "UPI Reference / Transaction ID",
              hintText: "Enter the reference number from your app",
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _FileSelector(
            fileName: _selectedFile?.name,
            onTap: submission.isSubmitting ? null : _pickFile,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submission.isSubmitting ? null : _submit,
              child: Text(submission.isSubmitting ? "Uploading..." : "Submit Receipt"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ["jpg", "jpeg", "png", "pdf"],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  Future<void> _submit() async {
    final file = _selectedFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a receipt photo.")),
      );
      return;
    }

    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction reference is required.")),
      );
      return;
    }

    await ref.read(feeSubmissionControllerProvider.notifier).submit(
      user: widget.user,
      invoiceId: widget.invoice.invoiceId,
      studentId: widget.invoice.studentId,
      file: file,
      clientReference: reference,
    );
  }
}

class _FileSelector extends StatelessWidget {
  const _FileSelector({this.fileName, this.onTap});
  final String? fileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                fileName ?? "Select receipt image/PDF",
                style: TextStyle(
                  color: fileName == null ? Colors.black54 : Colors.black87,
                  fontWeight: fileName == null ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _AdminFeesView extends ConsumerStatefulWidget {
  const _AdminFeesView({required this.items, required this.students, required this.studentNames});
  final List<FeeInvoice> items;
  final List<dynamic> students;
  final Map<String, String> studentNames;

  @override
  ConsumerState<_AdminFeesView> createState() => _AdminFeesViewState();
}

class _AdminFeesViewState extends ConsumerState<_AdminFeesView> {
  String? _selectedClass;
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final classesMap = ref.watch(allClassesMapProvider);
    var mappedStudents = widget.students.cast<dynamic>();
    final classIds = mappedStudents.map((s) => s.classId as String).toSet().toList()..sort();
    
    final filtered = widget.items.where((inv) {
      final st = inv.paymentStatus.toLowerCase();
      
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Paid') {
          if (!st.contains('paid') && !st.contains('verified')) return false;
        } else if (_selectedStatus == 'Unpaid') {
          if (st.contains('paid') || st.contains('verified') || st.contains('pending')) return false;
        } else if (_selectedStatus == 'Pending') {
          if (!st.contains('pending')) return false;
        }
      }
      
      if (_selectedClass != null) {
        final student = mappedStudents.firstWhere((s) => s.studentId == inv.studentId, orElse: () => null);
        if (student?.classId != _selectedClass) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        const GlobalFilterBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const ScreenIntroCard(
                title: "Financial Overview",
                description: "View and filter student fee invoices. Use operations tab for bulk generation.",
                icon: Icons.analytics_outlined,
                accent: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 52) / 2,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedClass,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Class", 
                        prefixIcon: Icon(Icons.class_outlined, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Classes", style: TextStyle(fontSize: 13))),
                        ...classIds.map((c) => DropdownMenuItem(value: c, child: Text(classesMap[c] ?? "Grade $c", style: const TextStyle(fontSize: 13))))
                      ],
                      onChanged: (val) => setState(() => _selectedClass = val),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 52) / 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Status", 
                        prefixIcon: Icon(Icons.filter_list, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', 'Paid', 'Unpaid', 'Pending']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final studentList = widget.students.cast<Student>();
              final filter = ref.watch(globalSchoolFilterProvider);
              
              final finalFiltered = filtered.where((inv) {
                final student = studentList.firstWhere((s) => s.studentId == inv.studentId, orElse: () => Student.empty());
                if (student.studentId.isEmpty) return false;
                
                final genderMatch = filter.gender == GenderFilter.all || student.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
                final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? student.isJunior : !student.isJunior);
                
                return genderMatch && levelMatch;
              }).toList();

              if (finalFiltered.isEmpty) {
                return const Center(child: Text("No records match the selected filters."));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: finalFiltered.length,
                itemBuilder: (context, index) {
                  final invoice = finalFiltered[index];
                  final student = studentList.firstWhere((s) => s.studentId == invoice.studentId, orElse: () => Student.empty());
                  
                  bool isPaid = invoice.paymentStatus.contains('paid') || invoice.paymentStatus.contains('verified');
                  bool isPending = invoice.paymentStatus.contains('pending');
                  
                  Color statusColor = isPaid ? const Color(0xFF00A86B) : (isPending ? const Color(0xFFD4AF37) : const Color(0xFFB34747));
                  String statusText = isPaid ? "VERIFIED" : (isPending ? "PENDING REVIEW" : "UNPAID");
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(isPaid ? Icons.check : (isPending ? Icons.hourglass_top : Icons.warning_amber), color: statusColor, size: 20),
                      ),
                      title: Text(widget.studentNames[invoice.studentId] ?? invoice.studentId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${invoice.title} • ${classesMap[student.classId] ?? (student.classId.isEmpty ? '-' : student.classId)}\nDue: ${invoice.dueDate}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${invoice.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
