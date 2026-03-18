import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/attendance_document.dart";
import "../../../../core/models/student.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../controllers/attendance_controller.dart";

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Map<String, bool> _presentByStudentId = <String, bool>{};
  String? _lastRosterSignature;

  @override
  Widget build(BuildContext context) {
    ref.listen<AttendanceSubmissionState>(
      attendanceSubmissionControllerProvider,
      (previous, next) {
        if (next.successMessage != null && next.successMessage != previous?.successMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.successMessage!)),
          );
          ref.read(attendanceSubmissionControllerProvider.notifier).clearMessage();
        } else if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
      },
    );

    final canEdit = ref.watch(canEditAttendanceProvider);
    final classIds = ref.watch(currentClassIdsProvider);
    final selectedClass = ref.watch(selectedAttendanceClassProvider);
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final students = ref.watch(currentStudentsProvider);
    final activeAttendance = ref.watch(activeAttendanceDocumentProvider);
    final attendanceSummaries = ref.watch(attendanceSummariesProvider);
    final submission = ref.watch(attendanceSubmissionControllerProvider);

    final isTab = !Navigator.of(context).canPop();

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Attendance")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ScreenIntroCard(
            title: canEdit ? "Class Attendance" : "Attendance History",
            description: canEdit
                ? "Mark students present and track daily participation records for your assigned classes."
                : "Review daily attendance logs and summaries for your children's classes.",
            icon: Icons.fact_check_outlined,
            accent: const Color(0xFF003D5B),
          ),
          const SizedBox(height: 24),
          AsyncValueView(
            value: attendanceSummaries,
            data: (items) {
              final latest = items.isEmpty ? null : items.first;
              final visiblePresent = items.fold<int>(0, (sum, item) => sum + item.presentCount);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _StatBox(
                      label: "Classes",
                      value: "${classIds.length}",
                      subtitle: "Assigned",
                      icon: Icons.class_outlined,
                      accent: const Color(0xFF003D5B),
                    ),
                    _StatBox(
                      label: "Most Recent",
                      value: latest?.date ?? "-",
                      subtitle: "Latest mark",
                      icon: Icons.today_outlined,
                      accent: const Color(0xFFD4AF37),
                    ),
                    _StatBox(
                      label: "Attendance",
                      value: "$visiblePresent",
                      subtitle: "Total Marks",
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF00A86B),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (canEdit)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Roll Call",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (classIds.length > 1)
                      DropdownButtonFormField<String>(
                        initialValue: selectedClass,
                        decoration: const InputDecoration(labelText: "Target Class"),
                        items: classIds
                            .map(
                              (classId) => DropdownMenuItem<String>(
                                value: classId,
                                child: Text(classId),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          ref.read(selectedAttendanceClassProvider.notifier).state = value;
                        },
                      )
                    else if (classIds.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.class_outlined, color: Color(0xFF003D5B)),
                        title: Text("Class ${classIds.first}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Your primary assigned grade section"),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: selectedDate,
                      decoration: const InputDecoration(
                        labelText: "Selection Date",
                        hintText: "YYYY-MM-DD",
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      onChanged: (value) {
                        ref.read(selectedAttendanceDateProvider.notifier).state = value.trim();
                      },
                    ),
                    const SizedBox(height: 20),
                    AsyncValueView(
                      value: students,
                      data: (allStudents) {
                        final classStudents = _studentsForClass(allStudents, selectedClass);
                        return AsyncValueView(
                          value: activeAttendance,
                          data: (document) {
                            _syncRoster(classStudents, document);
                            if (classStudents.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: Text("No students in this class roster.")),
                              );
                            }
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${classStudents.length} Students Found"),
                                    TextButton.icon(
                                      onPressed: _markAllPresent,
                                      icon: const Icon(Icons.done_all),
                                      label: const Text("All Present"),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                for (final student in classStudents)
                                  _AttendanceTile(
                                    student: student,
                                    isPresent: _presentByStudentId[student.studentId] ?? true,
                                    onChanged: (val) => setState(() => _presentByStudentId[student.studentId] = val),
                                  ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: submission.isSubmitting
                                        ? null
                                        : () => _submitAttendance(
                                              classStudents: classStudents,
                                              existing: document,
                                            ),
                                    child: Text(
                                      submission.isSubmitting
                                          ? "Processing..."
                                          : document == null
                                              ? "Confirm Attendance"
                                              : "Update Records",
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            "Weekly Presence Record",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AsyncValueView(
            value: attendanceSummaries,
            data: (items) {
              final last7Days = List.generate(7, (i) {
                final date = DateTime.now().subtract(Duration(days: i));
                final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                final summary = items.where((item) => item.date == dateStr).firstOrNull;
                return MapEntry(date, summary);
              }).reversed.toList();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: last7Days.map((entry) {
                      final date = entry.key;
                      final summary = entry.value;
                      
                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              ["S", "M", "T", "W", "T", "F", "S"][date.weekday % 7],
                              style: const TextStyle(fontSize: 12, color: Colors.black38),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: summary == null 
                                  ? Colors.black12 
                                  : (summary.absentCount > 0 ? const Color(0xFFB34747) : const Color(0xFF00A86B)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${date.day}",
                                  style: TextStyle(
                                    color: summary == null ? Colors.black45 : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Student> _studentsForClass(List<Student> students, String? classId) {
    if (classId == null) {
      return const [];
    }
    final filtered = students.where((student) => student.classId == classId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  void _syncRoster(List<Student> classStudents, AttendanceDocument? document) {
    final rosterSignature = [
      document?.attendanceId ?? "new",
      ...classStudents.map((student) => student.studentId),
    ].join("|");

    if (_lastRosterSignature == rosterSignature) {
      return;
    }

    final next = <String, bool>{};
    for (final student in classStudents) {
      final existing = document?.records.where((record) => record.studentId == student.studentId);
      if (existing != null && existing.isNotEmpty) {
        next[student.studentId] = existing.first.status != "absent";
      } else {
        next[student.studentId] = true;
      }
    }
    _presentByStudentId
      ..clear()
      ..addAll(next);
    _lastRosterSignature = rosterSignature;
  }

  void _markAllPresent() {
    setState(() {
      for (final key in _presentByStudentId.keys) {
        _presentByStudentId[key] = true;
      }
    });
  }

  Future<void> _submitAttendance({
    required List<Student> classStudents,
    required AttendanceDocument? existing,
  }) async {
    final classId = ref.read(selectedAttendanceClassProvider);
    final date = ref.read(selectedAttendanceDateProvider);
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a target class.")),
      );
      return;
    }

    final records = classStudents
        .map(
          (student) => {
            "studentId": student.studentId,
            "status": (_presentByStudentId[student.studentId] ?? true) ? "present" : "absent",
            "remarks": "",
          },
        )
        .toList();

    await ref.read(attendanceSubmissionControllerProvider.notifier).submit(
          classId: classId,
          date: date,
          records: records,
          existing: existing,
        );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.student,
    required this.isPresent,
    required this.onChanged,
  });

  final Student student;
  final bool isPresent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(student.studentId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusToggle(
            label: "A",
            activeColor: const Color(0xFFB34747),
            isActive: !isPresent,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          _StatusToggle(
            label: "P",
            activeColor: const Color(0xFF00A86B),
            isActive: isPresent,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.label,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color activeColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? activeColor : Colors.black12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black45,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 140,
        child: MiniStatCard(
          label: label,
          value: value,
          subtitle: subtitle,
          icon: icon,
          accent: accent,
        ),
      ),
    );
  }
}
