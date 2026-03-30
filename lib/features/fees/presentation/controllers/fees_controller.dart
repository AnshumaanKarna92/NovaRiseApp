import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/fee_invoice.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";

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
