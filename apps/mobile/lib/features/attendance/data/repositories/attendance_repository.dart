import '../../domain/models/attendance_entry.dart';

class AttendanceRepository {
  const AttendanceRepository();

  List<AttendanceEntry> fetchRoster() {
    return const [
      AttendanceEntry(studentId: 'S2026_001', studentName: 'Priya Sharma', status: true),
      AttendanceEntry(studentId: 'S2026_002', studentName: 'Aman Verma', status: false),
    ];
  }
}
