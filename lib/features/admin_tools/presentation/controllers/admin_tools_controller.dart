import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:file_picker/file_picker.dart";
import "package:firebase_storage/firebase_storage.dart";

import "../../../../core/models/fee_payment.dart";
import "../../../../core/models/import_job.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../data/import_submission_service.dart";

final adminSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return const {"pendingFees": 0, "notices": 0, "messages": 0};
  }
  // Pure Firestore records

  final firestore = ref.watch(firebaseFirestoreProvider);
  final pendingFees = await firestore
      .collection("fee_payments")
      .where("schoolId", isEqualTo: user.schoolId)
      .where("status", isEqualTo: "pending_verification")
      .count()
      .get();
  final notices = await firestore
      .collection("notices")
      .where("schoolId", isEqualTo: user.schoolId)
      .count()
      .get();
  final messages = await firestore
      .collection("messages")
      .where("schoolId", isEqualTo: user.schoolId)
      .count()
      .get();

  return {
    "pendingFees": pendingFees.count ?? 0,
    "notices": notices.count ?? 0,
    "messages": messages.count ?? 0,
  };
});

final pendingFeePaymentsProvider = StreamProvider<List<FeePayment>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  // Pure Firestore records
  return ref.watch(schoolDataServiceProvider).watchPendingFeePayments(user.schoolId);
});

final importJobsProvider = StreamProvider<List<ImportJob>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  // Pure Firestore records
  return ref.watch(schoolDataServiceProvider).watchImportJobs(user.schoolId);
});

class FeeVerificationState {
  const FeeVerificationState({
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

final feeVerificationControllerProvider =
    StateNotifierProvider<FeeVerificationController, FeeVerificationState>((ref) {
  return FeeVerificationController(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
    ref,
  );
});

class FeeVerificationController extends StateNotifier<FeeVerificationState> {
  FeeVerificationController(this._functions, this._firestore, this._ref) : super(const FeeVerificationState());

  final dynamic _functions;
  final dynamic _firestore;
  final Ref _ref;

  Future<void> verify({
    required String paymentId,
    required String decision,
    required String notes,
  }) async {
    state = const FeeVerificationState(isSubmitting: true);
    try {
      try {
        await _functions.httpsCallable("verifyFeePayment").call({
          "paymentId": paymentId,
          "decision": decision,
          "notes": notes,
        });
      } catch (e) {
        // Direct Firestore Fallback
        final paymentDoc = await _firestore.collection("fee_payments").doc(paymentId).get();
        if (paymentDoc.exists) {
          final data = paymentDoc.data()!;
          final invoiceId = data["invoiceId"];
          
          await _firestore.runTransaction((transaction) async {
            transaction.update(_firestore.collection("fee_payments").doc(paymentId), {
              "status": decision,
              "adminNotes": notes,
              "updatedAt": FieldValue.serverTimestamp(),
            });
            
            transaction.update(_firestore.collection("fee_invoices").doc(invoiceId), {
              "paymentStatus": decision == "verified" ? "paid" : "rejected",
              "updatedAt": FieldValue.serverTimestamp(),
            });
          });
        }
      }
      state = FeeVerificationState(successMessage: "Payment $decision.");
    } catch (error) {
      state = FeeVerificationState(error: error.toString());
    }
  }

  Future<void> recordCashPayment({
    required String studentId,
    required String invoiceId,
    required double amount,
    required String collectorName,
  }) async {
    state = const FeeVerificationState(isSubmitting: true);
    try {
      final paymentId = "cash_${DateTime.now().millisecondsSinceEpoch}";
      final adminUser = _ref.read(userProfileProvider).value;
      await _firestore.collection("fee_payments").doc(paymentId).set({
        "paymentId": paymentId,
        "schoolId": adminUser?.schoolId ?? "school_001",
        "studentId": studentId,
        "invoiceId": invoiceId,
        "amount": amount,
        "status": "verified",
        "paymentMethod": "cash",
        "clientReference": collectorName,
        "adminNotes": "Cash payment recorded by $collectorName",
        "screenshotUrl": "",
        "uploadedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await _firestore.collection("fee_invoices").doc(invoiceId).update({
        "paymentStatus": "paid",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      state = const FeeVerificationState(successMessage: "Cash payment recorded successfully.");
    } catch (error) {
      state = FeeVerificationState(error: error.toString());
    }
  }

  void clear() {
    state = const FeeVerificationState();
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

final adminFirebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final importSubmissionServiceProvider = Provider<ImportSubmissionService>((ref) {
  return ImportSubmissionService(
    storage: ref.watch(adminFirebaseStorageProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
});

final importSubmissionControllerProvider =
    StateNotifierProvider<ImportSubmissionController, ImportSubmissionState>((ref) {
  return ImportSubmissionController(
    ref.watch(importSubmissionServiceProvider),
    ref,
  );
});

class ImportSubmissionController extends StateNotifier<ImportSubmissionState> {
  ImportSubmissionController(this._service, this._ref) : super(const ImportSubmissionState());

  final ImportSubmissionService _service;
  final Ref _ref;

  Future<void> submitCsv() async {
    final user = _ref.read(userProfileProvider).asData?.value;
    if (user == null) {
      state = const ImportSubmissionState(error: "Sign in required.");
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["csv"],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    state = const ImportSubmissionState(isSubmitting: true);
    try {
      final fileUrl = await _service.uploadCsv(
        schoolId: user.schoolId,
        file: result.files.single,
      );
      await _service.enqueueImport(fileUrl: fileUrl);
      state = const ImportSubmissionState(successMessage: "CSV import job queued.");
    } catch (error) {
      state = ImportSubmissionState(error: error.toString());
    }
  }

  void clear() {
    state = const ImportSubmissionState();
  }
}
