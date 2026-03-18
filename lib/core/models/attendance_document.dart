class AttendanceDocument {
  const AttendanceDocument({
    required this.attendanceId,
    required this.classId,
    required this.date,
    required this.records,
    required this.isEdited,
  });

  factory AttendanceDocument.fromMap(String id, Map<String, dynamic> data) {
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
    );
  }

  final String attendanceId;
  final String classId;
  final String date;
  final List<AttendanceRecord> records;
  final bool isEdited;
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
