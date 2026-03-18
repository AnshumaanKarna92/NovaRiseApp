import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/attendance_repository.dart';
import '../../domain/models/attendance_entry.dart';

final attendanceRepositoryProvider = Provider((ref) => const AttendanceRepository());
final attendanceRosterProvider = Provider<List<AttendanceEntry>>((ref) {
  return ref.watch(attendanceRepositoryProvider).fetchRoster();
});
