import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/app_user.dart";
import "../../../../core/models/attendance_document.dart";
import "../../../../core/models/attendance_summary.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../../admin_tools/presentation/controllers/admin_tools_controller.dart";
import "../../data/attendance_submission_service.dart";

// ── Role helpers ────────────────────────────────────────────────────────────

/// Returns the today date string in YYYY-MM-DD format.
String get _todayDateString {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, "0");
  final day = now.day.toString().padLeft(2, "0");
  return "${now.year}-$month-$day";
}

/// Whether the current user can mark attendance (Teachers mark today only;
/// Admins can mark/edit any date via separate state).
final canMarkAttendanceProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return false;
  return user.role == UserRole.teacher || user.role == UserRole.admin;
});

/// Whether the current user is an admin (can change dates and edit records).
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  return user?.role == UserRole.admin;
});

// Keep backward compat for parts of the code that still check canEditAttendanceProvider
final canEditAttendanceProvider = canMarkAttendanceProvider;

// ── Class & date selectors ───────────────────────────────────────────────────

final selectedAttendanceClassProvider = StateProvider<String?>((ref) {
  final classes = ref.watch(currentClassIdsProvider);
  return classes.isEmpty ? null : classes.first;
});

/// For teachers this is always locked to today; admins can change it.
final selectedAttendanceDateProvider = StateProvider<String>((ref) {
  return _todayDateString;
});

// ── Data providers ───────────────────────────────────────────────────────────

final attendanceSummariesProvider = StreamProvider<List<AttendanceSummary>>((ref) {
  final classIds = ref.watch(currentClassIdsProvider);
  return ref.watch(schoolDataServiceProvider).watchAttendanceForClasses(classIds);
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

// ── Monthly attendance stats ─────────────────────────────────────────────────

/// Returns a map of month label -> {present, absent} for each month, derived
/// from the attendance summaries visible to the current user.
final monthlyAttendanceStatsProvider = Provider<Map<String, Map<String, int>>>((ref) {
  final summaries = ref.watch(attendanceSummariesProvider).valueOrNull ?? const [];

  final Map<String, Map<String, int>> result = {};
  for (final summary in summaries) {
    // date is "YYYY-MM-DD"
    if (summary.date.length < 7) continue;
    final monthKey = summary.date.substring(0, 7); // "YYYY-MM"
    result.putIfAbsent(monthKey, () => {"present": 0, "absent": 0});
    result[monthKey]!["present"] = (result[monthKey]!["present"] ?? 0) + summary.presentCount;
    result[monthKey]!["absent"] = (result[monthKey]!["absent"] ?? 0) + summary.absentCount;
  }
  return result;
});

// ── Submission ───────────────────────────────────────────────────────────────

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
      final profile = _ref.read(userProfileProvider).valueOrNull;
      final uid = profile?.uid ?? "unknown";
      final name = profile?.displayName ?? "Unknown User";

      if (existing == null) {
        await _service.submitAttendance(
          classId: classId,
          date: date,
          records: records,
          schoolId: profile?.schoolId ?? "school_001",
          markedByUid: uid,
          markedByName: name,
        );
        state = const AttendanceSubmissionState(
          successMessage: "Attendance submitted successfully.",
        );
      } else {
        await _service.updateAttendance(
          attendanceId: existing.attendanceId,
          records: records,
          reason: "Updated from mobile app",
          markedByUid: uid,
          markedByName: name,
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

final staffListProvider = StreamProvider.family<List<AppUser>, String>((ref, schoolId) {
  return ref.watch(schoolDataServiceProvider).watchStaff(schoolId);
});

final staffMapProvider = Provider<Map<String, String>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return {};
  
  final staffValue = ref.watch(staffListProvider(user.schoolId));
  return staffValue.maybeWhen(
    data: (list) => {for (final s in list) s.uid: s.displayName},
    orElse: () => {},
  );
});

final dailyAttendanceOverviewProvider = Provider<AsyncValue<List<({String classId, String className, bool isMarked})>>>((ref) {
  final classesValue = ref.watch(schoolClassesProvider);
  final summariesValue = ref.watch(attendanceSummariesProvider);
  final today = _todayDateString;

  return classesValue.when(
    data: (classes) => summariesValue.when(
      data: (summaries) {
        final markedIds = summaries
            .where((s) => s.date == today)
            .map((s) => s.classId)
            .toSet();
        
        final result = classes.map((c) => (
          classId: c.id,
          className: c.displayName,
          isMarked: markedIds.contains(c.id) || markedIds.contains(c.name),
        )).toList();
        return AsyncValue.data(result);
      },
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
