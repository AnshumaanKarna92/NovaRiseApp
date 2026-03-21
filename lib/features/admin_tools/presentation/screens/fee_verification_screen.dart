import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../../shared/widgets/receipt_view.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../controllers/admin_tools_controller.dart";

class FeeVerificationScreen extends ConsumerWidget {
  const FeeVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPayments = ref.watch(pendingFeePaymentsProvider);
    final students = ref.watch(currentStudentsProvider).value ?? const [];
    final studentNames = {for (final student in students) student.studentId: student.name};
    final verificationState = ref.watch(adminToolsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Fee Receipts")),
      body: AsyncValueView(
        value: pendingPayments,
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("Verification queue is currently empty."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final payment = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 24),
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            child: OutlinedButton(
                              onPressed: verificationState.isSubmitting
                                  ? null
                                  : () => _showRejectionDialog(context, ref, payment.paymentId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                              child: const Text("Reject"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: verificationState.isSubmitting
                                  ? null
                                  : () => ref.read(adminToolsControllerProvider.notifier).verify(
                                      paymentId: payment.paymentId,
                                      decision: "verified",
                                      notes: "Approved by admin",
                                    ),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                              child: const Text("Verify"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, WidgetRef ref, String paymentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Proof"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Reason for rejection required:"),
            const SizedBox(height: 8),
            TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              ref.read(adminToolsControllerProvider.notifier).verify(
                paymentId: paymentId,
                decision: "rejected",
                notes: controller.text,
              );
            },
            child: const Text("Confirm Rejection"),
          ),
        ],
      ),
    );
  }
}
