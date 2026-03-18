import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../auth/presentation/controllers/session_controller.dart";
import "../../data/message_submission_service.dart";

class MessageSubmissionState {
  const MessageSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

final messageSubmissionServiceProvider = Provider<MessageSubmissionService>((ref) {
  return MessageSubmissionService(ref.watch(firebaseFunctionsProvider));
});

final messageSubmissionControllerProvider =
    StateNotifierProvider<MessageSubmissionController, MessageSubmissionState>((ref) {
  return MessageSubmissionController(ref.watch(messageSubmissionServiceProvider));
});

class MessageSubmissionController extends StateNotifier<MessageSubmissionState> {
  MessageSubmissionController(this._service) : super(const MessageSubmissionState());

  final MessageSubmissionService _service;

  Future<void> create({
    required String classId,
    required String type,
    required String text,
    String? dueDate,
  }) async {
    state = const MessageSubmissionState(isSubmitting: true);
    try {
      await _service.createMessage(
        classId: classId,
        type: type,
        text: text,
        dueDate: dueDate,
      );
      state = const MessageSubmissionState(successMessage: "Message published.");
    } catch (error) {
      state = MessageSubmissionState(error: error.toString());
    }
  }

  void clear() {
    state = const MessageSubmissionState();
  }
}
