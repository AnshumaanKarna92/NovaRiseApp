import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/attendance_document.dart";
import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/student.dart";
import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/admin_tools/presentation/controllers/admin_tools_controller.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/features/attendance/presentation/controllers/attendance_controller.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
import "package:nova_rise_app/shared/widgets/filter_bar.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

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
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: const Color(0xFF00A86B),
            ),
          );
          ref.read(attendanceSubmissionControllerProvider.notifier).clearMessage();
        } else if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: const Color(0xFFB34747),
            ),
          );
        }
      },
    );

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final role = userProfile?.role ?? UserRole.unknown;

    final canMark = ref.watch(canMarkAttendanceProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final isTab = !Navigator.of(context).canPop();

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Attendance")),
      body: switch (role) {
        UserRole.parent => _ParentAttendanceView(userProfile: userProfile),
        UserRole.teacher => _TeacherAttendanceView(),
        UserRole.admin || UserRole.cashCollector => _AdminAttendanceView(),
        _ => const Center(child: Text("Not authorized to view attendance.")),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PARENT VIEW — weekly calendar + monthly stats
// ─────────────────────────────────────────────────────────────────────────────

class _ParentAttendanceView extends ConsumerWidget {
  const _ParentAttendanceView({required this.userProfile});
  final AppUser? userProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceSummaries = ref.watch(attendanceSummariesProvider);
    final monthlyStats = ref.watch(monthlyAttendanceStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        ScreenIntroCard(
          title: "My Child's Attendance",
          description: "Track weekly presence and monthly attendance summary for your children.",
          icon: Icons.calendar_month_outlined,
          accent: const Color(0xFF003D5B),
        ),
        const SizedBox(height: 24),

        // ── Weekly Calendar ──────────────────────────────────────────────────
        Text(
          "This Week",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AsyncValueView(
          value: attendanceSummaries,
          data: (items) {
            final last7Days = List.generate(7, (i) {
              final date = DateTime.now().subtract(Duration(days: 6 - i));
              final dateStr =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              final summary = items.where((item) => item.date == dateStr).firstOrNull;
              return MapEntry(date, summary);
            });

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: last7Days.map((entry) {
                        final date = entry.key;
                        final summary = entry.value;
                        final isToday = date.day == DateTime.now().day &&
                            date.month == DateTime.now().month &&
                            date.year == DateTime.now().year;

                        Color dotColor;
                        if (summary == null) {
                          dotColor = Colors.black12;
                        } else if (summary.absentCount > 0) {
                          dotColor = const Color(0xFFB34747);
                        } else {
                          dotColor = const Color(0xFF00A86B);
                        }

                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                ["S", "M", "T", "W", "T", "F", "S"][date.weekday % 7],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isToday
                                      ? const Color(0xFF003D5B)
                                      : Colors.black38,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  border: isToday
                                      ? Border.all(color: const Color(0xFF003D5B), width: 2)
                                      : null,
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
                              const SizedBox(height: 4),
                              if (summary != null)
                                Text(
                                  summary.absentCount > 0 ? "A" : "P",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: summary.absentCount > 0
                                        ? const Color(0xFFB34747)
                                        : const Color(0xFF00A86B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Legend
                    Row(
                      children: [
                        _LegendDot(color: const Color(0xFF00A86B), label: "Present"),
                        const SizedBox(width: 16),
                        _LegendDot(color: const Color(0xFFB34747), label: "Absent"),
                        const SizedBox(width: 16),
                        _LegendDot(color: Colors.black12, label: "No record"),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        // ── Monthly Statistics ───────────────────────────────────────────────
        Text(
          "Monthly Summary",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ..._buildMonthlyCards(context, monthlyStats),

        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildMonthlyCards(BuildContext context, Map<String, Map<String, int>> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                "No attendance records found yet.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black45),
              ),
            ),
          ),
        ),
      ];
    }

    final sortedEntries = monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedEntries.map((entry) {
      final monthKey = entry.key; // "YYYY-MM"
      final present = entry.value["present"] ?? 0;
      final absent = entry.value["absent"] ?? 0;
      final total = present + absent;
      final attendancePercent = total == 0 ? 0.0 : present / total;

      final parts = monthKey.split("-");
      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0;
      final monthName = _monthName(month);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF003D5B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$monthName $year",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D5B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${(attendancePercent * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: attendancePercent >= 0.75
                          ? const Color(0xFF00A86B)
                          : const Color(0xFFB34747),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: attendancePercent,
                  minHeight: 10,
                  backgroundColor: Color(0xFFB34747).withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    attendancePercent >= 0.75
                        ? const Color(0xFF00A86B)
                        : const Color(0xFFD4AF37),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MonthStat(
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF00A86B),
                      label: "Present",
                      value: "$present days",
                    ),
                  ),
                  Expanded(
                    child: _MonthStat(
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFB34747),
                      label: "Absent",
                      value: "$absent days",
                    ),
                  ),
                  Expanded(
                    child: _MonthStat(
                      icon: Icons.calendar_today_outlined,
                      color: const Color(0xFF003D5B),
                      label: "Total",
                      value: "$total days",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _monthName(int month) {
    const names = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    return month >= 1 && month <= 12 ? names[month] : "Unknown";
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEACHER VIEW — Mark attendance for TODAY ONLY
// ─────────────────────────────────────────────────────────────────────────────

class _TeacherAttendanceView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TeacherAttendanceView> createState() => _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends ConsumerState<_TeacherAttendanceView> {
  final Map<String, bool> _presentByStudentId = <String, bool>{};
  String? _lastRosterSignature;

  @override
  Widget build(BuildContext context) {
    final classIds = ref.watch(currentClassIdsProvider);
    final classesValue = ref.watch(schoolClassesProvider);
    final selectedClass = ref.watch(selectedAttendanceClassProvider);
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final students = ref.watch(currentStudentsProvider);
    final activeAttendance = ref.watch(activeAttendanceDocumentProvider);
    final submission = ref.watch(attendanceSubmissionControllerProvider);

    // Today string
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayFormatted =
        "${now.day} ${_monthName(now.month)}, ${now.year}";

    final classesMap = ref.watch(allClassesMapProvider);


    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ScreenIntroCard(
          title: "Mark Attendance",
          description: "Record today's roll call for your class. Only today's attendance can be marked.",
          icon: Icons.fact_check_outlined,
          accent: const Color(0xFF00A86B),
        ),
        const SizedBox(height: 24),

        // Date display (read-only for teachers)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFF00A86B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(0xFF00A86B).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today_outlined, color: Color(0xFF00A86B)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Date",
                            style: TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                          Text(
                            todayFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF003D5B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "TODAY",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Class selector
                if (classIds.length > 1)
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(
                      labelText: "Select Class",
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    items: classIds
                        .map((classId) => DropdownMenuItem<String>(
                              value: classId,
                              child: Text(classesMap[classId] ?? "Grade $classId"),
                            ))
                        .toList(),
                    onChanged: (value) {
                      ref.read(selectedAttendanceClassProvider.notifier).state = value;
                    },
                  )
                else if (classIds.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.class_outlined, color: Color(0xFF003D5B)),
                    title: Text(
                      classesMap[classIds.first] ?? "Grade ${classIds.first}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text("Your assigned class"),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "No class assigned to your account. Please contact the school admin.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Roll call
        AsyncValueView(
          value: students,
          data: (allStudents) {
            final classStudents = _studentsForClass(allStudents, selectedClass);
            return AsyncValueView(
              value: activeAttendance,
              data: (document) {
                _syncRoster(classStudents, document);
                if (classStudents.isEmpty && classIds.isNotEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text("No students found in this class.")),
                    ),
                  );
                }
                if (classIds.isEmpty) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${classStudents.length} Students",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            TextButton.icon(
                              onPressed: _markAllPresent,
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text("All Present"),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A86B)),
                            ),
                          ],
                        ),
                        const Divider(),
                        for (final student in classStudents)
                          _AttendanceTile(
                            student: student,
                            isPresent: _presentByStudentId[student.studentId] ?? true,
                            onChanged: (val) =>
                                setState(() => _presentByStudentId[student.studentId] = val),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: submission.isSubmitting
                                ? null
                                : () => _submitAttendance(
                                      classStudents: classStudents,
                                      existing: document,
                                      date: todayStr,
                                    ),
                            icon: Icon(
                              document == null ? Icons.check_circle_outline : Icons.update,
                              size: 20,
                            ),
                            label: Text(
                              submission.isSubmitting
                                  ? "Saving..."
                                  : document == null
                                      ? "Submit Attendance"
                                      : "Update Attendance",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<Student> _studentsForClass(List<Student> students, String? classId) {
    if (classId == null) return const [];
    return students.where((s) => s.classId == classId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _syncRoster(List<Student> classStudents, AttendanceDocument? document) {
    final sig = [
      document?.attendanceId ?? "new",
      ...classStudents.map((s) => s.studentId),
    ].join("|");

    if (_lastRosterSignature == sig) return;

    final next = <String, bool>{};
    for (final student in classStudents) {
      final existing = document?.records.where((r) => r.studentId == student.studentId);
      if (existing != null && existing.isNotEmpty) {
        next[student.studentId] = existing.first.status != "absent";
      } else {
        next[student.studentId] = true;
      }
    }
    _presentByStudentId
      ..clear()
      ..addAll(next);
    _lastRosterSignature = sig;
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
    required String date,
  }) async {
    final classId = ref.read(selectedAttendanceClassProvider);
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a class first.")),
      );
      return;
    }

    final records = classStudents
        .map((student) => {
              "studentId": student.studentId,
              "status": (_presentByStudentId[student.studentId] ?? true) ? "present" : "absent",
              "remarks": "",
            })
        .toList();

    await ref.read(attendanceSubmissionControllerProvider.notifier).submit(
          classId: classId,
          date: date,
          records: records,
          existing: existing,
        );
  }

  String _monthName(int month) {
    const names = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return month >= 1 && month <= 12 ? names[month] : "";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN VIEW — View all classes, change date, edit records
// ─────────────────────────────────────────────────────────────────────────────

class _AdminAttendanceView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends ConsumerState<_AdminAttendanceView> {
  final Map<String, bool> _presentByStudentId = <String, bool>{};
  String? _lastRosterSignature;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classIds = ref.watch(currentClassIdsProvider);
    final classesValue = ref.watch(schoolClassesProvider);
    final selectedClass = ref.watch(selectedAttendanceClassProvider);
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final studentsValue = ref.watch(currentStudentsProvider);
    final filteredItems = ref.watch(filteredStudentsProvider);
    final filter = ref.watch(globalSchoolFilterProvider);
    final activeAttendance = ref.watch(activeAttendanceDocumentProvider);
    final attendanceSummaries = ref.watch(attendanceSummariesProvider);
    final submission = ref.watch(attendanceSubmissionControllerProvider);
    final classesMapValue = ref.watch(allClassesMapProvider);

    return AsyncValueView(
      value: classesValue,
      data: (allClassesRaw) {
        final classesMap = classesMapValue; // Use local final to ensure scope
        final allClasses = allClassesRaw.toList()
          ..sort((a, b) => a.classWeight.compareTo(b.classWeight));
        
        final filteredClasses = allClasses.where((c) {
          final genderMatch = filter.gender == GenderFilter.all || c.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
          final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? c.isJunior : !c.isJunior);
          return genderMatch && levelMatch;
        }).toList();

        final filteredClassIds = filteredClasses.map((c) => c.id).toList();

        return Column(
          children: [
            const GlobalFilterBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ScreenIntroCard(
                title: "Attendance Management",
                description: "View and edit attendance records for any class and date.",
                icon: Icons.admin_panel_settings_outlined,
                accent: const Color(0xFFD4AF37),
              ),
              const SizedBox(height: 24),

              // Summary stats
              AsyncValueView(
                value: attendanceSummaries,
                data: (items) {
                  final latest = items.isEmpty ? null : items.first;
                  final totalPresent = items.fold<int>(0, (sum, item) => sum + item.presentCount);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatBox(
                          label: "Classes",
                          value: "${classIds.length}",
                          subtitle: "Monitored",
                          icon: Icons.class_outlined,
                          accent: const Color(0xFF003D5B),
                        ),
                        _StatBox(
                          label: "Last Record",
                          value: latest?.date ?? "-",
                          subtitle: "Latest date",
                          icon: Icons.today_outlined,
                          accent: const Color(0xFFD4AF37),
                        ),
                        _StatBox(
                          label: "Present (all)",
                          value: "$totalPresent",
                          subtitle: "All records",
                          icon: Icons.check_circle_outline,
                          accent: const Color(0xFF00A86B),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Edit panel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit / View Attendance",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Class selector
                      if (filteredClassIds.length > 1)
                        DropdownButtonFormField<String>(
                          value: selectedClass,
                          decoration: const InputDecoration(
                            labelText: "Select Class",
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          items: filteredClassIds
                              .map((cId) => DropdownMenuItem<String>(
                                    value: cId,
                                    child: Text(classesMap[cId] ?? "Grade $cId"),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            ref.read(selectedAttendanceClassProvider.notifier).state = value;
                          },
                        )
                      else if (filteredClassIds.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.class_outlined, color: Color(0xFF003D5B)),
                          title: Text(classesMap[filteredClassIds.first] ?? "Grade ${filteredClassIds.first}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text("The selected class"),
                        ),
                      const SizedBox(height: 12),
                      // Date picker
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Select Date",
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          hintText: "Tap to pick a date",
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(selectedDate) ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final dateStr =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            _dateController.text = dateStr;
                            ref.read(selectedAttendanceDateProvider.notifier).state = dateStr;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Student list
                      AsyncValueView(
                        value: studentsValue,
                        data: (allStudents) {
                          final classStudents = _studentsForClass(filteredItems, selectedClass);
                          return AsyncValueView(
                            value: activeAttendance,
                            data: (document) {
                              _syncRoster(classStudents, document);
                              if (classStudents.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: Text("No students in this class.")),
                                );
                              }
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("${classStudents.length} Students"),
                                      TextButton.icon(
                                        onPressed: _markAllPresent,
                                        icon: const Icon(Icons.done_all, size: 18),
                                        label: const Text("All Present"),
                                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A86B)),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  for (final student in classStudents)
                                    _AttendanceTile(
                                      student: student,
                                      isPresent: _presentByStudentId[student.studentId] ?? true,
                                      onChanged: (val) => setState(
                                          () => _presentByStudentId[student.studentId] = val),
                                    ),
                                  const SizedBox(height: 16),
                                  if (document != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFD4AF37).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Color(0xFFD4AF37).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline,
                                              color: Color(0xFFD4AF37), size: 16),
                                          const SizedBox(width: 8),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final staffMap = ref.watch(staffMapProvider);
                                                  final name = document.markedByName ?? staffMap[document.markedByUid] ?? document.markedByUid?.substring(0, 5) ?? 'Staff';
                                                  return Text(
                                                    document.isEdited
                                                        ? "Edited by $name at ${document.createdAt}"
                                                        : "Marked by $name at ${document.createdAt}",
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37)),
                                                  );
                                                }
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: submission.isSubmitting
                                          ? null
                                          : () => _submitAttendance(
                                                classStudents: classStudents,
                                                existing: document,
                                              ),
                                      icon: Icon(
                                        document == null
                                            ? Icons.check_circle_outline
                                            : Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      label: Text(
                                        submission.isSubmitting
                                            ? "Saving..."
                                            : document == null
                                                ? "Submit Attendance"
                                                : "Save Changes",
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
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

              // Daily Status Board
              Text(
                "Today's Attendance Compliance",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AsyncValueView(
                value: ref.watch(dailyAttendanceOverviewProvider),
                data: (overview) {
                  if (overview.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("No academic classes registered.")),
                      ),
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final item in overview)
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (item.isMarked ? const Color(0xFF00A86B) : const Color(0xFFB34747)).withOpacity(0.1),
                              child: Icon(
                                item.isMarked ? Icons.check_circle_outline : Icons.error_outline,
                                color: item.isMarked ? const Color(0xFF00A86B) : const Color(0xFFB34747),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.className,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item.isMarked ? "Attendance Verified Today" : "Submission Missing",
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isMarked ? Colors.black54 : const Color(0xFFB34747),
                              ),
                            ),
                            trailing: !item.isMarked
                                ? TextButton(
                                    onPressed: () {
                                      final now = DateTime.now();
                                      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                                      ref.read(selectedAttendanceDateProvider.notifier).state = todayStr;
                                      ref.read(selectedAttendanceClassProvider.notifier).state = item.classId;
                                      _dateController.text = todayStr;
                                      // The UI will update the above Edit panel
                                    },
                                    child: const Text("Action Required"),
                                  )
                                : const Icon(Icons.verified, size: 16, color: Color(0xFF00A86B)),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  },
);
}

  List<Student> _studentsForClass(List<Student> students, String? classId) {
    if (classId == null) return const [];
    return students.where((s) => s.classId == classId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _syncRoster(List<Student> classStudents, AttendanceDocument? document) {
    final sig = [
      document?.attendanceId ?? "new",
      ...classStudents.map((s) => s.studentId),
    ].join("|");

    if (_lastRosterSignature == sig) return;

    final next = <String, bool>{};
    for (final student in classStudents) {
      final existing = document?.records.where((r) => r.studentId == student.studentId);
      if (existing != null && existing.isNotEmpty) {
        next[student.studentId] = existing.first.status != "absent";
      } else {
        next[student.studentId] = true;
      }
    }
    _presentByStudentId
      ..clear()
      ..addAll(next);
    _lastRosterSignature = sig;
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
        const SnackBar(content: Text("Please select a class.")),
      );
      return;
    }

    final records = classStudents
        .map((student) => {
              "studentId": student.studentId,
              "status":
                  (_presentByStudentId[student.studentId] ?? true) ? "present" : "absent",
              "remarks": "",
            })
        .toList();

    await ref.read(attendanceSubmissionControllerProvider.notifier).submit(
          classId: classId,
          date: date,
          records: records,
          existing: existing,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

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
      leading: Icon(
        student.branchId == "girls" ? Icons.female : Icons.male,
        size: 18,
        color: student.branchId == "girls" ? Colors.pink : const Color(0xFF003D5B),
      ),
      title: Row(
        children: [
          Expanded(child: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (student.isJunior ? Colors.orange : Colors.indigo).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              student.isJunior ? "JNR" : "SNR",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: student.isJunior ? Colors.orange : Colors.indigo,
              ),
            ),
          ),
        ],
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? activeColor : Colors.black12),
          boxShadow: isActive
              ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black45,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummaryTile extends StatelessWidget {
  const _AttendanceSummaryTile({required this.summary, required this.onTap});

  final dynamic summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = (summary.presentCount as int) + (summary.absentCount as int);
    final pct = total == 0 ? 0.0 : (summary.presentCount as int) / total;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: pct >= 0.75
            ? Color(0xFF00A86B).withOpacity(0.12)
            : Color(0xFFB34747).withOpacity(0.12),
        child: Text(
          "${(pct * 100).toStringAsFixed(0)}%",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: pct >= 0.75 ? const Color(0xFF00A86B) : const Color(0xFFB34747),
          ),
        ),
      ),
      title: Text(
        "Class ${summary.classId}  —  ${summary.date}",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        "${summary.presentCount}P  ${summary.absentCount}A${summary.isEdited ? '  · Edited' : ''}",
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
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
