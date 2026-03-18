import "package:cloud_firestore/cloud_firestore.dart";

import "../models/app_user.dart";
import "../models/attendance_document.dart";
import "../models/attendance_summary.dart";
import "../models/fee_invoice.dart";
import "../models/fee_payment.dart";
import "../models/import_job.dart";
import "../models/message_item.dart";
import "../models/notice_item.dart";
import "../models/student.dart";

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
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Stream<List<FeeInvoice>> watchFeeInvoicesForStudents(List<String> studentIds) {
    // Stream purely from Firestore
    if (studentIds.isEmpty) {
      return Stream.value(const []);
    }
    return _firestore
        .collection("fee_invoices")
        .where("studentId", whereIn: studentIds.take(10).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeeInvoice.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate)));
  }

  Stream<List<NoticeItem>> watchNoticesForUser(AppUser user, List<String> classIds) {
    // Stream purely from Firestore

    return _firestore
        .collection("notices")
        .where("schoolId", isEqualTo: user.schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoticeItem.fromMap(doc.id, doc.data()))
            .where((notice) {
              if (notice.targetType == "all") {
                return true;
              }
              return classIds.any(notice.targetClassIds.contains);
            })
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt)));
  }

  Stream<List<MessageItem>> watchMessagesForClasses(List<String> classIds) {
    // Stream purely from Firestore
    if (classIds.isEmpty) {
      return Stream.value(const []);
    }
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
        .where("classId", whereIn: classIds.take(10).toList())
        .limit(50)
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

}
