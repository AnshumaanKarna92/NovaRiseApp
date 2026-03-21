import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../auth/presentation/controllers/session_controller.dart";
import "../../data/notice_submission_service.dart";

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

  Future<void> publish({
    required String title,
    required String body,
    required String targetType,
    required List<String> targetClassIds,
    required String startAt,
    required String expiresAt,
  }) async {
    state = const NoticeSubmissionState(isSubmitting: true);
    try {
      final user = _ref.read(userProfileProvider).value;
      await _service.publishNotice(
        schoolId: user?.schoolId ?? "school_001",
        title: title,
        body: body,
        targetType: targetType,
        targetClassIds: targetClassIds,
        startAt: startAt,
        expiresAt: expiresAt,
      );
      state = const NoticeSubmissionState(successMessage: "Notice published.");
    } catch (error) {
      state = NoticeSubmissionState(error: error.toString());
    }
  }

  void clear() {
    state = const NoticeSubmissionState();
  }
}
