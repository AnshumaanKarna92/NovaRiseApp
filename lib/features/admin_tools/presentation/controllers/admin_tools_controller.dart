import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:file_picker/file_picker.dart";

import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/admin_tools/data/import_submission_service.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/core/models/lesson_record.dart";
import "package:nova_rise_app/core/models/fee_payment.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";

class AdminActionState {
  const AdminActionState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });
  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

final adminToolsControllerProvider = StateNotifierProvider<AdminToolsController, AdminActionState>((ref) {
  return AdminToolsController(ref);
});

class AdminToolsController extends StateNotifier<AdminActionState> {
  AdminToolsController(this.ref) : super(const AdminActionState());
  final Ref ref;

  void clear() {
    state = const AdminActionState();
  }

  Future<void> assignClassTeacher(String classId, String teacherUid) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await ref.read(schoolDataServiceProvider).updateClassTeacher(classId, teacherUid);
      state = const AdminActionState(successMessage: "Class teacher assigned successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> updateClassSubjects(String classId, Map<String, String> subjects) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await ref.read(schoolDataServiceProvider).updateClassSubjects(classId, subjects);
      state = const AdminActionState(successMessage: "Class subjects updated successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> verify({
    required String paymentId,
    required String decision,
    required String notes,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await ref.read(schoolDataServiceProvider).verifyFeePayment(paymentId, decision, notes);
      state = AdminActionState(successMessage: "Payment ${decision == 'verified' ? 'verified' : 'rejected'} successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> sendFeeReminders() async {
    state = const AdminActionState(isSubmitting: true);
    try {
      // Mocked for now, usually a cloud function
      await Future.delayed(const Duration(seconds: 1));
      state = const AdminActionState(successMessage: "Fee reminders sent to all pending guardians.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> recordCashPayment({
    required String studentId,
    required String invoiceId,
    required double amount,
    required String collectorName,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final schoolId = ref.read(userProfileProvider).value?.schoolId ?? "school_001";
      await ref.read(schoolDataServiceProvider).recordManualPayment(
        studentId: studentId,
        invoiceId: invoiceId,
        amount: amount,
        collectorName: collectorName,
        schoolId: schoolId,
      );
      state = const AdminActionState(successMessage: "Cash payment recorded successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> generateMonthlyFees({
    required double amount,
    required String monthYearValue,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final schoolId = ref.read(userProfileProvider).value?.schoolId ?? "school_001";
      await ref.read(schoolDataServiceProvider).generateMonthlyFees(
        schoolId: schoolId,
        defaultAmount: amount,
        monthYearValue: monthYearValue,
      );
      state = const AdminActionState(successMessage: "Monthly fees generated for all students.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> saveLessonRecord({
    required String classId,
    required String subject,
    required String period,
    required String chapter,
    required String topic,
    required String topicBn,
    required String homework,
    required String homeworkBn,
    required String date,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final user = ref.read(userProfileProvider).value!;
      final recordId = "LR_${DateTime.now().millisecondsSinceEpoch}";
      final record = LessonRecord(
        recordId: recordId,
        schoolId: user.schoolId,
        classId: classId,
        subject: subject,
        period: period,
        chapter: chapter,
        teacherId: user.uid,
        teacherName: user.displayName,
        topic: topic,
        topicBn: topicBn,
        homework: homework,
        homeworkBn: homeworkBn,
        date: date,
        createdAt: DateTime.now(),
      );
      await ref.read(schoolDataServiceProvider).saveLessonRecord(record);
      state = const AdminActionState(successMessage: "Lesson record saved successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> updateLessonRecord({
    required String recordId,
    required String period,
    required String chapter,
    required String topic,
    required String topicBn,
    required String homework,
    required String homeworkBn,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final user = ref.read(userProfileProvider).value!;
      await ref.read(schoolDataServiceProvider).updateLessonRecord(
            recordId: recordId,
            updates: {
              "period": period,
              "chapter": chapter,
              "topic": topic,
              "topicBn": topicBn,
              "homework": homework,
              "homeworkBn": homeworkBn,
              "updatedAt": DateTime.now().toIso8601String(),
              "lastEditedBy": user.uid,
            },
          );
      state = const AdminActionState(successMessage: "Lesson record updated successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> deleteLessonRecord(String recordId) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await ref.read(schoolDataServiceProvider).deleteLessonRecord(recordId);
      state = const AdminActionState(successMessage: "Lesson record deleted successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }
}

class ImportSubmissionState {
  const ImportSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });
  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

final importSubmissionControllerProvider = StateNotifierProvider<ImportSubmissionController, ImportSubmissionState>((ref) {
  return ImportSubmissionController(ref);
});

class ImportSubmissionController extends StateNotifier<ImportSubmissionState> {
  ImportSubmissionController(this.ref) : super(const ImportSubmissionState());
  final Ref ref;

  void clear() {
    state = const ImportSubmissionState();
  }

  Future<void> submitCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["csv"],
    );

    if (result == null || result.files.isEmpty) return;
    
    state = const ImportSubmissionState(isSubmitting: true);
    try {
      final schoolId = ref.read(userProfileProvider).value?.schoolId ?? "school_001";
      final service = ref.read(importSubmissionServiceProvider);
      
      final url = await service.uploadCsv(
        schoolId: schoolId,
        file: result.files.first,
      );
      
      await service.enqueueImport(fileUrl: url);
      
      state = const ImportSubmissionState(successMessage: "CSV uploaded and import enqueued successfully.");
    } catch (e) {
      state = ImportSubmissionState(error: e.toString());
    }
  }
}

final adminSummaryProvider = Provider<Map<String, int>>((ref) {
  final students = ref.watch(currentStudentsProvider).valueOrNull ?? [];
  final classes = ref.watch(schoolClassesProvider).valueOrNull ?? [];
  final staff = ref.watch(currentStaffProvider).valueOrNull ?? [];

  final boys = students.where((s) => s.branchId == "boys").length;
  final girls = students.where((s) => s.branchId == "girls").length;
  final juniors = students.where((s) => s.isJunior).length;
  final seniors = students.length - juniors;

  return {
    "students": students.length,
    "boys": boys,
    "girls": girls,
    "juniors": juniors,
    "seniors": seniors,
    "classes": classes.length,
    "staff": staff.length,
    "pendingFees": 0, // Placeholder for actual fee logic if needed
  };
});

final pendingFeePaymentsProvider = StreamProvider<List<FeePayment>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchPendingFeePayments(user.schoolId);
});

final importJobsProvider = StreamProvider((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchImportJobs(user.schoolId);
});
