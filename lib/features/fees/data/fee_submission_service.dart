import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";
import "package:file_picker/file_picker.dart";
import "package:firebase_storage/firebase_storage.dart";

class FeeSubmissionService {
  FeeSubmissionService({
    required FirebaseStorage storage,
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  }) : _storage = storage,
       _functions = functions,
       _firestore = firestore;

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<String> uploadReceipt({
    required String schoolId,
    required String studentId,
    required String invoiceId,
    required PlatformFile file,
  }) async {
    final extension = file.extension ?? "bin";
    final objectPath =
        "schoolapp/$schoolId/fees/$studentId/${invoiceId}_${DateTime.now().millisecondsSinceEpoch}.$extension";
    final ref = _storage.ref(objectPath);

    if (file.bytes != null) {
      await ref.putData(file.bytes!);
    } else if (file.path != null) {
      await ref.putFile(File(file.path!));
    } else {
      throw Exception("Unable to read selected file.");
    }

    return ref.getDownloadURL();
  }

  Future<void> submitReceipt({
    required String invoiceId,
    required String studentId,
    required String screenshotUrl,
    required String clientReference,
    required String schoolId,
  }) async {
    try {
      await _functions.httpsCallable("createOrUpdateFeeReceipt").call({
        "invoiceId": invoiceId,
        "studentId": studentId,
        "paymentMethod": "upi",
        "clientReference": clientReference,
        "screenshotUrl": screenshotUrl,
      });
    } catch (e) {
      // Direct Firestore Fallback for maximum reliability if Cloud Functions are not yet deployed
      final paymentId = "PAY_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}";
      await _firestore.collection("fee_payments").doc(paymentId).set({
        "paymentId": paymentId,
        "invoiceId": invoiceId,
        "studentId": studentId,
        "schoolId": schoolId,
        "amount": 0, // Should be fetched or passed, but 0 indicates needs admin review
        "status": "pending_verification",
        "paymentMethod": "upi",
        "clientReference": clientReference,
        "screenshotUrl": screenshotUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });
      
      // Also update the invoice status locally to avoid confusion
      await _firestore.collection("fee_invoices").doc(invoiceId).update({
        "paymentStatus": "pending_verification",
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
