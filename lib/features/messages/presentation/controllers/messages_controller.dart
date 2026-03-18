import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/message_item.dart";
import "../../../students/presentation/controllers/student_controller.dart";

import "../../../auth/presentation/controllers/session_controller.dart";
import "../../data/message_submission_service.dart";

final messagesProvider = StreamProvider<List<MessageItem>>((ref) {
  final classIds = ref.watch(currentClassIdsProvider);
  return ref.watch(schoolDataServiceProvider).watchMessagesForClasses(classIds);
});

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
  return MessageSubmissionService(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final messageSubmissionControllerProvider =
    StateNotifierProvider<MessageSubmissionController, MessageSubmissionState>((ref) {
  return MessageSubmissionController(ref.watch(messageSubmissionServiceProvider), ref);
});

class MessageSubmissionController extends StateNotifier<MessageSubmissionState> {
  MessageSubmissionController(this._service, this._ref) : super(const MessageSubmissionState());

  final MessageSubmissionService _service;
  final Ref _ref;

  Future<void> submit({
    required String classId,
    required String type,
    required String text,
    String? dueDate,
  }) async {
    final user = _ref.read(userProfileProvider).valueOrNull;
    if (user == null) {
      state = const MessageSubmissionState(error: "Sign in required.");
      return;
    }

    state = const MessageSubmissionState(isSubmitting: true);
    try {
      await _service.createMessage(
        schoolId: user.schoolId,
        teacherId: user.uid,
        classId: classId,
        type: type,
        text: text,
        dueDate: dueDate,
      );
      state = const MessageSubmissionState(successMessage: "Message published successfully.");
    } catch (error) {
      state = MessageSubmissionState(error: error.toString());
    }
  }

  void clearMessage() {
    state = const MessageSubmissionState();
  }
}
