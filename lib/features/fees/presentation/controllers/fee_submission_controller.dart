import "package:file_picker/file_picker.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/providers/school_providers.dart";
import "../../data/fee_submission_service.dart";

class FeeSubmissionState {
  const FeeSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.completedInvoiceId,
  });

  final bool isSubmitting;
  final String? error;
  final String? completedInvoiceId;

  FeeSubmissionState copyWith({
    bool? isSubmitting,
    String? error,
    String? completedInvoiceId,
  }) {
    return FeeSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      completedInvoiceId: completedInvoiceId,
    );
  }
}

// firebaseStorageProvider moved to lib/core/providers/school_providers.dart

final feeSubmissionServiceProvider = Provider<FeeSubmissionService>((ref) {
  return FeeSubmissionService(
    storage: ref.watch(firebaseStorageProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final feeSubmissionControllerProvider =
    StateNotifierProvider<FeeSubmissionController, FeeSubmissionState>((ref) {
  return FeeSubmissionController(ref.watch(feeSubmissionServiceProvider));
});

class FeeSubmissionController extends StateNotifier<FeeSubmissionState> {
  FeeSubmissionController(this._service) : super(const FeeSubmissionState());

  final FeeSubmissionService _service;

  Future<void> submit({
    required AppUser user,
    required String invoiceId,
    required String studentId,
    required PlatformFile file,
    required String clientReference,
  }) async {
    state = const FeeSubmissionState(isSubmitting: true);
    try {
      final screenshotUrl = await _service.uploadReceipt(
        schoolId: user.schoolId,
        studentId: studentId,
        invoiceId: invoiceId,
        file: file,
      );
      await _service.submitReceipt(
        invoiceId: invoiceId,
        studentId: studentId,
        screenshotUrl: screenshotUrl,
        clientReference: clientReference,
        schoolId: user.schoolId,
      );
      state = FeeSubmissionState(completedInvoiceId: invoiceId);
    } catch (error) {
      state = FeeSubmissionState(error: error.toString());
    }
  }

  void clearResult() {
    state = const FeeSubmissionState();
  }
}
