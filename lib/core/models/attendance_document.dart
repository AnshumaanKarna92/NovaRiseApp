class AttendanceDocument {
  const AttendanceDocument({
    required this.attendanceId,
    required this.classId,
    required this.date,
    required this.records,
    required this.isEdited,
    this.markedByUid,
    this.markedByName,
    this.createdAt,
  });

  factory AttendanceDocument.fromMap(String id, Map<String, dynamic> data) {
    String? timeStr;
    if (data["createdAt"] != null) {
      if (data["createdAt"] is String) {
        timeStr = data["createdAt"];
      } else {
        // Handle Firestore Timestamp
        try {
          final dyn = data["createdAt"];
          if (dyn is DateTime) {
            timeStr = dyn.toLocal().toString().split(".")[0];
          } else {
            final ms = dyn.millisecondsSinceEpoch;
            timeStr = DateTime.fromMillisecondsSinceEpoch(ms).toLocal().toString().split(".")[0];
          }
        } catch (_) {}
      }
    }

    return AttendanceDocument(
      attendanceId: id,
      classId: data["classId"] as String? ?? "",
      date: data["date"] as String? ?? "",
      records: List<AttendanceRecord>.from(
        (data["records"] as List? ?? const []).map(
          (entry) => AttendanceRecord.fromMap(Map<String, dynamic>.from(entry as Map)),
        ),
      ),
      isEdited: data["isEdited"] as bool? ?? false,
      markedByUid: data["markedByUid"] as String?,
      markedByName: data["markedByName"] as String?,
      createdAt: timeStr,
    );
  }

  final String attendanceId;
  final String classId;
  final String date;
  final List<AttendanceRecord> records;
  final bool isEdited;
  final String? markedByUid;
  final String? markedByName;
  final String? createdAt;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.studentId,
    required this.status,
    this.remarks = "",
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data) {
    return AttendanceRecord(
      studentId: data["studentId"] as String? ?? "",
      status: data["status"] as String? ?? "present",
      remarks: data["remarks"] as String? ?? "",
    );
  }

  final String studentId;
  final String status;
  final String remarks;
}
