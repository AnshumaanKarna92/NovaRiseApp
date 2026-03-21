import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:file_picker/file_picker.dart";
import "package:firebase_storage/firebase_storage.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/fee_payment.dart";
import "package:nova_rise_app/core/models/import_job.dart";
import "package:nova_rise_app/core/models/lesson_record.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/features/admin_tools/data/import_submission_service.dart";
import "package:nova_rise_app/core/services/school_data_service.dart";

final adminSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return const {"pendingFees": 0, "notices": 0, "messages": 0, "students": 0, "classes": 0, "staff": 0};
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

  final students = await firestore.collection("students").where("schoolId", isEqualTo: user.schoolId).count().get();
  final classes = await firestore.collection("classes").where("schoolId", isEqualTo: user.schoolId).count().get();
  final staff = await firestore.collection("users").where("schoolId", isEqualTo: user.schoolId).where("role", whereIn: ["teacher", "cashCollector"]).count().get();

  return {
    "pendingFees": pendingFees.count ?? 0,
    "notices": notices.count ?? 0,
    "messages": messages.count ?? 0,
    "students": students.count ?? 0,
    "classes": classes.count ?? 0,
    "staff": staff.count ?? 0,
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

final schoolClassesProvider = StreamProvider<List<SchoolClass>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchClassesForSchool(user.schoolId);
});

final teacherClassesProvider = StreamProvider<List<SchoolClass>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(schoolDataServiceProvider).watchClassesForTeacher(user.uid, user.schoolId);
});

final importJobsProvider = StreamProvider<List<ImportJob>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  // Pure Firestore records
  return ref.watch(schoolDataServiceProvider).watchImportJobs(user.schoolId);
});

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

final adminToolsControllerProvider =
    StateNotifierProvider<AdminToolsController, AdminActionState>((ref) {
  return AdminToolsController(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
    ref,
  );
});

class AdminToolsController extends StateNotifier<AdminActionState> {
  AdminToolsController(this._functions, this._firestore, this._ref) : super(const AdminActionState());

  final dynamic _functions;
  final dynamic _firestore;
  final Ref _ref;

  Future<void> verify({
    required String paymentId,
    required String decision,
    required String notes,
  }) async {
    state = const AdminActionState(isSubmitting: true);
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
      state = AdminActionState(successMessage: "Payment $decision.");
    } catch (error) {
      state = AdminActionState(error: error.toString());
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

      state = const AdminActionState(successMessage: "Cash payment recorded successfully.");
    } catch (error) {
      state = AdminActionState(error: error.toString());
    }
  }

  void clear() {
    state = const AdminActionState();
  }

  Future<void> generateMonthlyFees({double amount = 5000.0, String? monthYearValue}) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final adminUser = _ref.read(userProfileProvider).value;
      final schoolId = adminUser?.schoolId ?? "school_001";
      final now = DateTime.now();
      
      String monthYear;
      String dueDate;
      if (monthYearValue != null && monthYearValue.isNotEmpty) {
        monthYear = monthYearValue;
        dueDate = "$monthYear-15";
      } else {
        final monthStr = now.month.toString().padLeft(2, "0");
        monthYear = "${now.year}-$monthStr";
        dueDate = "${now.year}-$monthStr-15";
      }
      
      final invoiceTitle = "Fee for $monthYear";
      
      final studentsQuery = await _firestore.collection("students")
        .where("schoolId", isEqualTo: schoolId)
        .where("status", isEqualTo: "active")
        .get();
        
      int generated = 0;
      final batch = _firestore.batch();
      
      for (final doc in studentsQuery.docs) {
        final studentId = doc.id;
        final invoiceId = "INV_${studentId}_$monthYear";
        
        final existing = await _firestore.collection("fee_invoices").doc(invoiceId).get();
        if (!existing.exists) {
          final invoiceRef = _firestore.collection("fee_invoices").doc(invoiceId);
          batch.set(invoiceRef, {
            "invoiceId": invoiceId,
            "schoolId": schoolId,
            "studentId": studentId,
            "title": invoiceTitle,
            "amount": amount,
            "dueDate": dueDate,
            "status": "unpaid",
            "paymentStatus": "unpaid",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
          });
          
          final notificationJobRef = _firestore.collection("notification_jobs").doc();
          batch.set(notificationJobRef, {
            "schoolId": schoolId,
            "type": "new_fee_invoice",
            "targetMode": "student",
            "targetIds": [studentId],
            "channel": "push",
            "payload": {
              "title": "New Fee Invoice Generated",
              "body": "Your invoice $invoiceTitle is due by $dueDate.",
              "invoiceId": invoiceId,
            },
            "status": "queued",
            "createdAt": FieldValue.serverTimestamp(),
          });
          generated++;
        }
      }
      
      if (generated > 0) {
        await batch.commit();
      }
      state = AdminActionState(successMessage: "Deployed $generated new fee invoices for $monthYear.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> sendFeeReminders() async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final adminUser = _ref.read(userProfileProvider).value;
      final schoolId = adminUser?.schoolId ?? "school_001";
      
      final unpaidInvoices = await _firestore.collection("fee_invoices")
        .where("schoolId", isEqualTo: schoolId)
        .where("paymentStatus", whereIn: ["unpaid", "rejected"])
        .get();
      
      int remindersSent = 0;
      final batch = _firestore.batch();
      
      for (final doc in unpaidInvoices.docs) {
        final data = doc.data();
        final studentId = data["studentId"];
        
        final notificationJobRef = _firestore.collection("notification_jobs").doc();
        batch.set(notificationJobRef, {
          "schoolId": schoolId,
          "type": "fee_reminder",
          "targetMode": "student",
          "targetIds": [studentId],
          "channel": "push",
          "payload": {
            "title": "Fee Payment Reminder",
            "body": "Reminder: Please pay pending fee invoice ${data["title"]} of INR ${data["amount"]}.",
            "invoiceId": data["invoiceId"],
          },
          "status": "queued",
          "createdAt": FieldValue.serverTimestamp(),
        });
        remindersSent++;
        if (remindersSent >= 250) break;
      }
      
      if (remindersSent > 0) {
        await batch.commit();
      }
      
      state = AdminActionState(successMessage: "Sent $remindersSent fee reminders to parents.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }
  Future<void> assignClassTeacher(String classId, String teacherUid) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      // 1. Remove this class from any users currently holding it
      final currentTeachers = await _firestore.collection("users")
          .where("assignedClassIds", arrayContains: classId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in currentTeachers.docs) {
        final data = doc.data();
        final List<String> classes = List<String>.from(data["assignedClassIds"] ?? []);
        classes.remove(classId);
        batch.update(doc.reference, {"assignedClassIds": classes});
      }
      
      // 2. Add to new teacher
      final newTeacherRef = _firestore.collection("users").doc(teacherUid);
      final newTeacherDoc = await newTeacherRef.get();
      if (newTeacherDoc.exists) {
        final data = newTeacherDoc.data()!;
        final List<String> classes = List<String>.from(data["assignedClassIds"] ?? []);
        if (!classes.contains(classId)) {
          classes.add(classId);
        }
        batch.update(newTeacherRef, {"assignedClassIds": classes});
    }
    
    // Also update the class document with the teacher name
    final classRef = _firestore.collection("classes").doc(classId);
    batch.set(classRef, {
      "classTeacherId": teacherUid,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
      state = AdminActionState(successMessage: "Teacher assigned to Class $classId.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> saveLessonRecord({
    required String classId,
    required String subject,
    required String topic,
    String topicBn = "",
    required String homework,
    String homeworkBn = "",
    required String date,
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      final user = _ref.read(userProfileProvider).value;
      if (user == null) throw Exception("User not logged in");

      final docRef = _firestore.collection("lesson_records").doc();
      final record = LessonRecord(
        recordId: docRef.id,
        schoolId: user.schoolId,
        classId: classId,
        subject: subject,
        teacherId: user.uid,
        teacherName: user.displayName,
        topic: topic,
        topicBn: topicBn,
        homework: homework,
        homeworkBn: homeworkBn,
        date: date,
        createdAt: DateTime.now(),
      );

      await docRef.set(record.toMap());
      state = const AdminActionState(successMessage: "Lesson record saved successfully.");
    } catch (error) {
      state = AdminActionState(error: error.toString());
    }
  }

  Future<void> deleteLessonRecord(String recordId) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await _firestore.collection("lesson_records").doc(recordId).delete();
      state = const AdminActionState(successMessage: "Record deleted successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> updateLessonRecord({
    required String recordId,
    required String topic,
    String topicBn = "",
    required String homework,
    String homeworkBn = "",
  }) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await _firestore.collection("lesson_records").doc(recordId).update({
        "topic": topic,
        "topicBn": topicBn,
        "homework": homework,
        "homeworkBn": homeworkBn,
        "updatedAt": FieldValue.serverTimestamp(),
      });
      state = const AdminActionState(successMessage: "Record updated successfully.");
    } catch (e) {
      state = AdminActionState(error: e.toString());
    }
  }

  Future<void> updateClassSubjects(String classId, Map<String, String> subjects) async {
    state = const AdminActionState(isSubmitting: true);
    try {
      await _firestore.collection("classes").doc(classId).set({
        "subjects": subjects,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = const AdminActionState(successMessage: "Class subjects updated.");
    } catch (error) {
      state = AdminActionState(error: error.toString());
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
      state = const ImportSubmissionState(successMessage: "CSV Sync Successful. Records are being processed in the background.");
    } catch (error) {
      String msg = error.toString();
      if (msg.contains("permission-denied")) {
        msg = "You don't have permission to perform this institutional sync. Please contact the administrator.";
      } else if (msg.contains("not-found")) {
        msg = "Institutional sync service is currently unavailable. Please try again later.";
      } else if (msg.contains("network-request-failed")) {
        msg = "Network error. Please check your internet connection and try again.";
      }
      state = ImportSubmissionState(error: msg);
    }
  }

  void clear() {
    state = const ImportSubmissionState();
  }
}
