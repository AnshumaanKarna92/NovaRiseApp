class AttendanceEntry {
  const AttendanceEntry({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  final String studentId;
  final String studentName;
  final bool status;
}
