import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/fee_invoice.dart";
import "../../../students/presentation/controllers/student_controller.dart";

final feeInvoicesProvider = StreamProvider<List<FeeInvoice>>((ref) {
  final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
  return ref
      .watch(schoolDataServiceProvider)
      .watchFeeInvoicesForStudents(students.map((student) => student.studentId).toList());
});
