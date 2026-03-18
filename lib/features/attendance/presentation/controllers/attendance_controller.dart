import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/app_user.dart";
import "../../../../core/models/attendance_document.dart";
import "../../../../core/models/attendance_summary.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../data/attendance_submission_service.dart";

final attendanceSummariesProvider = StreamProvider<List<AttendanceSummary>>((ref) {
  final classIds = ref.watch(currentClassIdsProvider);
  return ref.watch(schoolDataServiceProvider).watchAttendanceForClasses(classIds);
});

final selectedAttendanceClassProvider = StateProvider<String?>((ref) {
  final classes = ref.watch(currentClassIdsProvider);
  return classes.isEmpty ? null : classes.first;
});

final selectedAttendanceDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, "0");
  final day = now.day.toString().padLeft(2, "0");
  return "${now.year}-$month-$day";
});

final activeAttendanceDocumentProvider = StreamProvider<AttendanceDocument?>((ref) {
  final classId = ref.watch(selectedAttendanceClassProvider);
  final date = ref.watch(selectedAttendanceDateProvider);
  if (classId == null || classId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(schoolDataServiceProvider).watchAttendanceDocument(
        classId: classId,
        date: date,
      );
});

final attendanceSubmissionServiceProvider = Provider<AttendanceSubmissionService>((ref) {
  return AttendanceSubmissionService(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

class AttendanceSubmissionState {
  const AttendanceSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  AttendanceSubmissionState copyWith({
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    return AttendanceSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      successMessage: successMessage,
    );
  }
}

final attendanceSubmissionControllerProvider =
    StateNotifierProvider<AttendanceSubmissionController, AttendanceSubmissionState>((ref) {
  return AttendanceSubmissionController(ref.watch(attendanceSubmissionServiceProvider), ref);
});

class AttendanceSubmissionController extends StateNotifier<AttendanceSubmissionState> {
  AttendanceSubmissionController(this._service, this._ref)
      : super(const AttendanceSubmissionState());

  final AttendanceSubmissionService _service;
  final Ref _ref;

  Future<void> submit({
    required String classId,
    required String date,
    required List<Map<String, String>> records,
    AttendanceDocument? existing,
  }) async {
    state = const AttendanceSubmissionState(isSubmitting: true);
    try {
      if (existing == null) {
        final profile = _ref.read(userProfileProvider).valueOrNull;
        await _service.submitAttendance(
          classId: classId,
          date: date,
          records: records,
          schoolId: profile?.schoolId ?? "school_001",
        );
        state = const AttendanceSubmissionState(
          successMessage: "Attendance submitted successfully.",
        );
      } else {
        await _service.updateAttendance(
          attendanceId: existing.attendanceId,
          records: records,
          reason: "Updated from mobile app",
        );
        state = const AttendanceSubmissionState(
          successMessage: "Attendance updated successfully.",
        );
      }
    } catch (error) {
      state = AttendanceSubmissionState(error: error.toString());
    }
  }

  void clearMessage() {
    state = const AttendanceSubmissionState();
  }
}

final canEditAttendanceProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) {
    return false;
  }
  return user.role == UserRole.teacher || user.role == UserRole.admin;
});
