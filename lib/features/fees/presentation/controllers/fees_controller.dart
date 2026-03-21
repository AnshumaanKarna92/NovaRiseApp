import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/app_user.dart";
import "../../../../core/models/fee_invoice.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";

final feeInvoicesProvider = StreamProvider<List<FeeInvoice>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  
  if (user.role == UserRole.admin || user.role == UserRole.cashCollector) {
    return ref.watch(schoolDataServiceProvider).watchFeeInvoices(schoolId: user.schoolId);
  }

  final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
  return ref.watch(schoolDataServiceProvider).watchFeeInvoices(
        studentIds: students.map((s) => s.studentId).toList(),
      );
});
