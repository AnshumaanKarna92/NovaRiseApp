import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/attendance_controller.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(attendanceRosterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () {},
            child: const Text('Mark All Present'),
          ),
          const SizedBox(height: 12),
          for (final entry in roster)
            CheckboxListTile(
              value: entry.status,
              onChanged: (_) {},
              title: Text(entry.studentName),
              subtitle: Text(entry.studentId),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Submit Attendance'),
          ),
        ],
      ),
    );
  }
}
