import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/lesson_record.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/shared/widgets/async_value_view.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/features/admin_tools/presentation/controllers/admin_tools_controller.dart";
import "package:nova_rise_app/core/services/school_data_service.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";

final diaryDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final diaryClassFilterProvider = StateProvider<String?>((ref) => null);

final lessonRecordsProvider = StreamProvider.family<List<LessonRecord>, ({String schoolId, String? classId, List<String>? classIds, String date})>((ref, arg) {
  return ref.watch(schoolDataServiceProvider).watchLessonRecords(
        schoolId: arg.schoolId,
        classId: arg.classId,
        classIds: arg.classIds,
        date: arg.date,
      );
});

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final selectedDate = ref.watch(diaryDateProvider);
    final dateStr = DateFormat("yyyy-MM-dd").format(selectedDate);
    final isTeacher = user.role == UserRole.teacher;
    final isAdmin = user.role == UserRole.admin || user.role == UserRole.cashCollector;
    final isParent = user.role == UserRole.parent;

    final teacherClasses = isTeacher ? ref.watch(teacherClassesProvider).valueOrNull ?? [] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Diary"),
        actions: [
          if (isTeacher && teacherClasses.isNotEmpty)
            IconButton(
              onPressed: () => _showAddDialog(context, ref, user),
              icon: const Icon(Icons.edit_note),
              tooltip: "Log Lesson",
            ),
        ],
      ),
      body: Column(
        children: [
          _DateHeader(selectedDate: selectedDate),
          if (isAdmin) _AdminClassSelector(schoolId: user.schoolId),
          Expanded(
            child: AsyncValueView(
              value: ref.watch(lessonRecordsProvider((
                schoolId: user.schoolId,
                classId: isAdmin ? ref.watch(diaryClassFilterProvider) : null,
                classIds: !isAdmin ? ref.watch(currentClassIdsProvider) : null,
                date: dateStr,
              ))),
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_stories_outlined, size: 64, color: Colors.black26),
                        const SizedBox(height: 16),
                        Text("No entries for this day", style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _LessonTile(record: record);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLessonRecordBottomSheet(user: user),
    );
  }
}

class _DateHeader extends ConsumerWidget {
  const _DateHeader({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = _isSameDay(selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => ref.read(diaryDateProvider.notifier).state = selectedDate.subtract(const Duration(days: 1)),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat("EEEE").format(selectedDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  DateFormat("d MMMM yyyy").format(selectedDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () => ref.read(diaryDateProvider.notifier).state = selectedDate.add(const Duration(days: 1)),
            icon: Icon(Icons.chevron_right, color: isToday ? Colors.black12 : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({required this.record});
  final LessonRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesMap = ref.watch(allClassesMapProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.subject.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      classesMap[record.classId] ?? "Grade ${record.classId}",
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (record.teacherId == ref.watch(userProfileProvider).valueOrNull?.uid) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _handleEdit(context, ref, record),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _handleDelete(context, ref, record),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  record.topic,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (record.topicBn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.topicBn,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                if (record.homework.isNotEmpty || record.homeworkBn.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text(
                              "HOMEWORK",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.0,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (record.homework.isNotEmpty)
                          Text(
                            record.homework,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (record.homeworkBn.isNotEmpty) ...[
                          if (record.homework.isNotEmpty) const SizedBox(height: 4),
                          Text(
                            record.homeworkBn,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.1),
                  child: Text(
                    record.teacherName[0],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  record.teacherName,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref, LessonRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to remove this diary entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(adminToolsControllerProvider.notifier).deleteLessonRecord(record.recordId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref, LessonRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLessonRecordBottomSheet(user: ref.read(userProfileProvider).value!, editRecord: record),
    );
  }
}

class _AddLessonRecordBottomSheet extends ConsumerStatefulWidget {
  const _AddLessonRecordBottomSheet({required this.user, this.editRecord});
  final AppUser user;
  final LessonRecord? editRecord;

  @override
  ConsumerState<_AddLessonRecordBottomSheet> createState() => _AddLessonRecordBottomSheetState();
}

class _AddLessonRecordBottomSheetState extends ConsumerState<_AddLessonRecordBottomSheet> {
  final _topicController = TextEditingController();
  final _topicBnController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _homeworkBnController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSubject;
  bool _showBengali = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      _topicController.text = widget.editRecord!.topic;
      _topicBnController.text = widget.editRecord!.topicBn;
      _homeworkController.text = widget.editRecord!.homework;
      _homeworkBnController.text = widget.editRecord!.homeworkBn;
      _selectedClassId = widget.editRecord!.classId;
      _selectedSubject = widget.editRecord!.subject;
      if (_topicBnController.text.isNotEmpty || _homeworkBnController.text.isNotEmpty) {
        _showBengali = true;
      }
    } else {
      _selectedSubject = widget.user.primarySubject;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(teacherClassesProvider).value ?? const [];
    final state = ref.watch(adminToolsControllerProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 32, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 16),
              Text(
                widget.editRecord != null ? "Edit Lesson Record" : "Log Daily Lesson", 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Section"),
            value: _selectedClassId,
            items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
            onChanged: widget.editRecord != null ? null : (val) {
              final cls = classes.firstWhere((c) => c.id == val);
              final isClassTeacher = cls.classTeacherId == widget.user.uid;
              
              final mySubjectsInClass = isClassTeacher
                  ? cls.subjects.keys.toList()
                  : cls.subjects.entries
                      .where((e) => e.value == widget.user.uid)
                      .map((e) => e.key)
                      .toList();
              
              setState(() {
                _selectedClassId = val;
                if (mySubjectsInClass.length == 1) {
                  _selectedSubject = mySubjectsInClass.first;
                } else if (mySubjectsInClass.contains(widget.user.primarySubject)) {
                  _selectedSubject = widget.user.primarySubject;
                } else {
                  _selectedSubject = null;
                }
              });
            },
          ),
          if (_selectedClassId != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final cls = classes.firstWhere((c) => c.id == _selectedClassId);
                final isClassTeacher = cls.classTeacherId == widget.user.uid;
                
                final subjects = isClassTeacher
                  ? cls.subjects.keys.toList()
                  : cls.subjects.entries
                      .where((e) => e.value == widget.user.uid)
                      .map((e) => e.key)
                      .toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Subject",
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  value: subjects.contains(_selectedSubject) ? _selectedSubject : null,
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val),
                );
              }
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: "Topic Covered (English)", hintText: "What was taught?"),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _homeworkController,
            decoration: const InputDecoration(labelText: "Homework Tasks (English)", hintText: "Optional assignments..."),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _showBengali,
              onExpansionChanged: (val) => setState(() => _showBengali = val),
              tilePadding: EdgeInsets.zero,
              title: Text(
                "Bengali Translation (অপশনাল)", 
                style: TextStyle(
                  color: _showBengali ? const Color(0xFF3B82F6) : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: Icon(
                Icons.translate, 
                size: 20, 
                color: _showBengali ? const Color(0xFF3B82F6) : Colors.black54,
              ),
              children: [
                TextField(
                  controller: _topicBnController,
                  decoration: const InputDecoration(
                    labelText: "বিষয় (Bengali Topic)",
                    hintText: "আজ কি পড়ানো হলো?",
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _homeworkBnController,
                  decoration: const InputDecoration(
                    labelText: "বাড়ির কাজ (Bengali Homework)",
                    hintText: "শিক্ষার্থীদের জন্য কাজ...",
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: state.isSubmitting || _selectedSubject == null || _topicController.text.isEmpty
                ? null
                : () async {
                    if (widget.editRecord != null) {
                      await ref.read(adminToolsControllerProvider.notifier).updateLessonRecord(
                            recordId: widget.editRecord!.recordId,
                            topic: _topicController.text.trim(),
                            topicBn: _topicBnController.text.trim(),
                            homework: _homeworkController.text.trim(),
                            homeworkBn: _homeworkBnController.text.trim(),
                          );
                    } else {
                      final dateStr = DateFormat("yyyy-MM-dd").format(ref.read(diaryDateProvider));
                      await ref.read(adminToolsControllerProvider.notifier).saveLessonRecord(
                            classId: _selectedClassId!,
                            subject: _selectedSubject!,
                            topic: _topicController.text.trim(),
                            topicBn: _topicBnController.text.trim(),
                            homework: _homeworkController.text.trim(),
                            homeworkBn: _homeworkBnController.text.trim(),
                            date: dateStr,
                          );
                    }
                    if (mounted) Navigator.pop(context);
                  },
            child: state.isSubmitting ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text("Save Lesson Log"),
          ),
        ],
      ),
    );
  }
}

class _AdminClassSelector extends ConsumerWidget {
  const _AdminClassSelector({required this.schoolId});
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesValue = ref.watch(schoolClassesProvider);
    final selectedClass = ref.watch(diaryClassFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AsyncValueView(
        value: classesValue,
        data: (classes) {
          if (classes.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButton<String?>(
              value: selectedClass,
              hint: const Text("All Grades"),
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text("All Grades")),
                ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
              ],
              onChanged: (val) => ref.read(diaryClassFilterProvider.notifier).state = val,
            ),
          );
        },
      ),
    );
  }
}
