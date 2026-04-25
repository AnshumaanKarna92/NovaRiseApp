import "package:cloud_firestore/cloud_firestore.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/attendance_document.dart";
import "package:nova_rise_app/core/models/attendance_summary.dart";
import "package:nova_rise_app/core/models/fee_invoice.dart";
import "package:nova_rise_app/core/models/fee_payment.dart";
import "package:nova_rise_app/core/models/import_job.dart";
import "package:nova_rise_app/core/models/lesson_record.dart";
import "package:nova_rise_app/core/models/message_item.dart";
import "package:nova_rise_app/core/models/notice_item.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/core/models/student.dart";

class SchoolDataService {
  SchoolDataService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Student>> watchStudentsForUser(AppUser user) {
    // Stream purely from Firestore

    if (user.role == UserRole.parent) {
      if (user.linkedStudentIds.isEmpty) {
        return Stream.value(const []);
      }
      return _firestore
          .collection("students")
          .where(FieldPath.documentId, whereIn: user.linkedStudentIds.take(10).toList())
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)));
    }

    if (user.role == UserRole.teacher && user.assignedClassIds.isNotEmpty) {
      return _firestore
          .collection("students")
          .where("classId", whereIn: user.assignedClassIds.take(10).toList())
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)));
    }

    return _firestore
        .collection("students")
        .where("schoolId", isEqualTo: user.schoolId)
        .limit(1000)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Stream<List<SchoolClass>> watchClassesForTeacher(String teacherUid, String schoolId, List<String> assignedClassIds) {
    return _firestore
        .collection("classes")
        .where("schoolId", isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolClass.fromMap(doc.id, doc.data()))
            .toList()
            ..sort((a, b) => a.id.compareTo(b.id)));
  }

  Stream<List<FeeInvoice>> watchFeeInvoices({List<String>? studentIds, String? schoolId}) {
    // Stream purely from Firestore
    Query query = _firestore.collection("fee_invoices");
    if (schoolId != null) {
      query = query.where("schoolId", isEqualTo: schoolId);
    } else if (studentIds != null && studentIds.isNotEmpty) {
      query = query.where("studentId", whereIn: studentIds.take(30).toList());
    } else {
      return Stream.value(const []);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FeeInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate))); // Show latest first
  }

  Stream<List<NoticeItem>> watchNoticesForUser(AppUser user, List<String> classIds) {
    return _firestore
        .collection("notices")
        .where("schoolId", isEqualTo: user.schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoticeItem.fromMap(doc.id, doc.data()))
            .where((notice) {
              if (user.role == UserRole.admin) return true;
              if (notice.targetType == "all") return true;
              if (notice.targetType == "teachers" && user.role == UserRole.teacher) return true;
              return classIds.any(notice.targetClassIds.contains);
            })
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt)));
  }

  Stream<List<MessageItem>> watchMessagesForClasses(List<String> classIds) {
    if (classIds.isEmpty) return Stream.value(const []);
    return _firestore
        .collection("messages")
        .where("classId", whereIn: classIds.take(10).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageItem.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.createdAtLabel.compareTo(a.createdAtLabel)));
  }

  Stream<List<AttendanceSummary>> watchAttendanceForClasses(List<String> classIds) {
    // Stream purely from Firestore
    if (classIds.isEmpty) {
      return Stream.value(const []);
    }
    return _firestore
        .collection("attendance")
        .where("classId", whereIn: classIds.take(30).toList())
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceSummary.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)));
  }

  Stream<AttendanceDocument?> watchAttendanceDocument({
    required String classId,
    required String date,
  }) {
    final attendanceId = "ATT_${classId}_${date.replaceAll("-", "")}";
    return _firestore.collection("attendance").doc(attendanceId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AttendanceDocument.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  Stream<List<FeePayment>> watchPendingFeePayments(String schoolId) {
    return _firestore
        .collection("fee_payments")
        .where("schoolId", isEqualTo: schoolId)
        .where("status", isEqualTo: "pending_verification")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeePayment.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.studentId.compareTo(b.studentId)));
  }

  Stream<List<ImportJob>> watchImportJobs(String schoolId) {
    return _firestore
        .collection("import_jobs")
        .where("schoolId", isEqualTo: schoolId)
        .orderBy("createdAt", descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ImportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<AppUser>> watchStaff(String schoolId) {
    return _firestore
        .collection("users")
        .where("schoolId", isEqualTo: schoolId)
        .where("role", whereIn: ["teacher", "cashCollector"])
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
          // De-duplicate by displayName to catch cross-branch duplicates
          final uniqueMap = {for (final u in users) u.displayName.trim().toLowerCase(): u};
          final uniqueList = uniqueMap.values.toList();
          return uniqueList..sort((a, b) => a.displayName.compareTo(b.displayName));
        });
  }

  Stream<List<SchoolClass>> watchClassesForSchool(String schoolId) {
    return _firestore
        .collection("classes")
        .where("schoolId", isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolClass.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id)));
  }

  Stream<List<LessonRecord>> watchLessonRecords({
    required String schoolId,
    List<String>? classIds,
    String? classId,
    String? date,
  }) {
    Query query = _firestore.collection("lesson_records").where("schoolId", isEqualTo: schoolId);

    if (classId != null) {
      query = query.where("classId", isEqualTo: classId);
    } else if (classIds != null && classIds.isNotEmpty) {
      query = query.where("classId", whereIn: classIds.take(10).toList());
    }
    if (date != null) {
      query = query.where("date", isEqualTo: date);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => LessonRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> updateClassTeacher(String classId, String teacherUid) async {
    await _firestore.collection("classes").doc(classId).update({
      "classTeacherId": teacherUid,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClassSubjects(String classId, Map<String, String> subjects) async {
    await _firestore.collection("classes").doc(classId).update({
      "subjects": subjects,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> verifyFeePayment(String paymentId, String decision, String notes) async {
    await _firestore.collection("fee_payments").doc(paymentId).update({
      "status": decision,
      "verificationNotes": notes,
      "verifiedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordManualPayment({
    required String studentId,
    required String invoiceId,
    required double amount,
    required String collectorName,
    required String schoolId,
  }) async {
    final paymentId = "PAY_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection("fee_payments").doc(paymentId).set({
      "paymentId": paymentId,
      "studentId": studentId,
      "invoiceId": invoiceId,
      "schoolId": schoolId,
      "amount": amount,
      "method": "cash",
      "status": "verified",
      "collectorName": collectorName,
      "paidAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> generateMonthlyFees({
    required String schoolId,
    required double defaultAmount,
    required String monthYearValue,
  }) async {
    // This probably should be a cloud function but we'll do simple bulk write
    final studentsSnapshot = await _firestore.collection("students").where("schoolId", isEqualTo: schoolId).get();
    final batch = _firestore.batch();
    for (var doc in studentsSnapshot.docs) {
      final studentId = doc.id;
      final data = doc.data();
      final studentFee = (data["monthlyFees"] as num?)?.toDouble() ?? defaultAmount;
      
      final invoiceId = "INV_${studentId}_${monthYearValue.replaceAll("-", "")}";
      batch.set(_firestore.collection("fee_invoices").doc(invoiceId), {
        "invoiceId": invoiceId,
        "studentId": studentId,
        "schoolId": schoolId,
        "amount": studentFee,
        "monthYearLabel": monthYearValue,
        "status": "pending",
        "dueDate": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> saveLessonRecord(LessonRecord record) async {
    await _firestore.collection("lesson_records").doc(record.recordId).set(record.toMap());
  }

  Future<void> updateLessonRecord({required String recordId, required Map<String, dynamic> updates}) async {
    await _firestore.collection("lesson_records").doc(recordId).update(updates);
  }

  Future<void> deleteLessonRecord(String recordId) async {
    await _firestore.collection("lesson_records").doc(recordId).delete();
  }
}
