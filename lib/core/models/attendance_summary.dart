class AttendanceSummary {
  const AttendanceSummary({
    required this.attendanceId,
    required this.classId,
    required this.date,
    required this.presentCount,
    required this.absentCount,
    required this.isEdited,
  });

  factory AttendanceSummary.fromMap(String id, Map<String, dynamic> data) {
    final records = List<Map<String, dynamic>>.from(
      (data["records"] as List? ?? const []).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      ),
    );
    final absentCount = records.where((entry) => entry["status"] == "absent").length;
    final presentCount = records.length - absentCount;
    return AttendanceSummary(
      attendanceId: id,
      classId: data["classId"] as String? ?? "",
      date: data["date"] as String? ?? "",
      presentCount: presentCount,
      absentCount: absentCount,
      isEdited: data["isEdited"] as bool? ?? false,
    );
  }

  final String attendanceId;
  final String classId;
  final String date;
  final int presentCount;
  final int absentCount;
  final bool isEdited;
}
