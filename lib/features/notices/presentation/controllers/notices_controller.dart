import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/notice_item.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../data/notice_submission_service.dart";

final noticesProvider = StreamProvider<List<NoticeItem>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  final classIds = ref.watch(currentClassIdsProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(schoolDataServiceProvider).watchNoticesForUser(user, classIds);
});

class NoticeSubmissionState {
  const NoticeSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

final noticeSubmissionServiceProvider = Provider<NoticeSubmissionService>((ref) {
  return NoticeSubmissionService(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final noticeSubmissionControllerProvider =
    StateNotifierProvider<NoticeSubmissionController, NoticeSubmissionState>((ref) {
  return NoticeSubmissionController(ref.watch(noticeSubmissionServiceProvider), ref);
});

class NoticeSubmissionController extends StateNotifier<NoticeSubmissionState> {
  NoticeSubmissionController(this._service, this._ref) : super(const NoticeSubmissionState());

  final NoticeSubmissionService _service;
  final Ref _ref;

  Future<void> submit({
    required String title,
    required String body,
    required String targetType,
    required List<String> targetClassIds,
    required String startAt,
    required String expiresAt,
  }) async {
    final user = _ref.read(userProfileProvider).valueOrNull;
    if (user == null) {
      state = const NoticeSubmissionState(error: "Sign in required.");
      return;
    }

    state = const NoticeSubmissionState(isSubmitting: true);
    try {
      await _service.publishNotice(
        schoolId: user.schoolId,
        title: title,
        body: body,
        targetType: targetType,
        targetClassIds: targetClassIds,
        startAt: startAt,
        expiresAt: expiresAt,
      );
      state = const NoticeSubmissionState(successMessage: "Notice published successfully.");
    } catch (error) {
      state = NoticeSubmissionState(error: error.toString());
    }
  }

  void clearMessage() {
    state = const NoticeSubmissionState();
  }
}
