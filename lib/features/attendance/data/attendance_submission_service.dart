import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";

class AttendanceSubmissionService {
  AttendanceSubmissionService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> submitAttendance({
    required String classId,
    required String date,
    required List<Map<String, String>> records,
    required String schoolId,
  }) async {
    try {
      await _functions.httpsCallable("submitAttendance").call({
        "classId": classId,
        "date": date,
        "records": records,
        "submissionMode": "initial",
      });
    } catch (e) {
      // Direct Firestore Fallback
      final attendanceId = "ATT_${classId}_${date.replaceAll("-", "")}";
      final presentCount = records.where((r) => r["status"] == "present").length;
      final absentCount = records.length - presentCount;

      final batch = _firestore.batch();
      
      batch.set(_firestore.collection("attendance").doc(attendanceId), {
        "attendanceId": attendanceId,
        "classId": classId,
        "schoolId": schoolId,
        "date": date,
        "presentCount": presentCount,
        "absentCount": absentCount,
        "records": records,
        "isEdited": false,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  Future<void> updateAttendance({
    required String attendanceId,
    required List<Map<String, String>> records,
    required String reason,
  }) async {
    try {
      await _functions.httpsCallable("updateAttendance").call({
        "attendanceId": attendanceId,
        "records": records,
        "reason": reason,
      });
    } catch (e) {
      // Direct Firestore Fallback
      final presentCount = records.where((r) => r["status"] == "present").length;
      final absentCount = records.length - presentCount;

      await _firestore.collection("attendance").doc(attendanceId).update({
        "records": records,
        "presentCount": presentCount,
        "absentCount": absentCount,
        "isEdited": true,
        "lastEditReason": reason,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
