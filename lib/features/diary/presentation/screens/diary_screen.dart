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
import "package:nova_rise_app/shared/widgets/filter_bar.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
import "package:nova_rise_app/features/diary/presentation/utils/diary_pdf_generator.dart";

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
      ),
      floatingActionButton: (isTeacher && teacherClasses.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, ref, user),
              icon: const Icon(Icons.add),
              label: const Text("Log Lesson"),
              backgroundColor: const Color(0xFF003D5B),
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          if (isAdmin || isTeacher) const GlobalFilterBar(),
          _DateHeader(selectedDate: selectedDate),
          if (isAdmin || isTeacher) _AdminClassSelector(schoolId: user.schoolId),
          Expanded(
            child: Builder(
              builder: (context) {
                final filter = ref.watch(globalSchoolFilterProvider);
                final allClasses = ref.watch(schoolClassesProvider).valueOrNull ?? [];
                
                // Filter classes based on gender and level
                final filteredClassIds = allClasses.where((c) {
                  final genderMatch = filter.gender == GenderFilter.all || c.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
                  final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? c.isJunior : !c.isJunior);
                  return genderMatch && levelMatch;
                }).map((c) => c.id).toList();

                final userClassIds = ref.watch(currentClassIdsProvider);
                final selectedClassIdFromFilter = (isAdmin || isTeacher) ? ref.watch(diaryClassFilterProvider) : null;
                
                // For students/parents, it's their first assigned class.
                // For admins/teachers, it's their filter selection, or first assigned if filter is empty and there's only one.
                final selectedClassId = (selectedClassIdFromFilter != null) 
                    ? selectedClassIdFromFilter 
                    : (userClassIds.isNotEmpty ? userClassIds.first : null);
                
                // For students/parents, we don't apply the global dashboard filter to their own diary
                final isManagedUser = isAdmin || isTeacher;
                final effectiveClassId = isManagedUser 
                    ? (selectedClassId != null && filteredClassIds.contains(selectedClassId) ? selectedClassId : null)
                    : selectedClassId;
                
                return AsyncValueView(
                  value: ref.watch(lessonRecordsProvider((
                    schoolId: user.schoolId,
                    classId: effectiveClassId,
                    classIds: (!isAdmin) ? ref.watch(currentClassIdsProvider) : (selectedClassId == null ? filteredClassIds : null),
                    date: dateStr,
                  ))),
                  data: (records) {
                    if (records.isEmpty) {
                      return Column(
                        children: [
                          if (effectiveClassId != null)
                             _PdfDownloadRow(allClasses: allClasses, effectiveClassId: effectiveClassId, records: records, selectedDate: selectedDate),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_stories_outlined, size: 64, color: Colors.black26),
                                  const SizedBox(height: 16),
                                  const Text("No entries for this day", style: TextStyle(color: Colors.black45)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        if (effectiveClassId != null)
                           _PdfDownloadRow(allClasses: allClasses, effectiveClassId: effectiveClassId, records: records, selectedDate: selectedDate),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (effectiveClassId != null || (isTeacher && !isAdmin))
                                _DiaryTableView(
                                  records: records,
                                  isAdmin: isAdmin,
                                  currentUserId: user.uid,
                                  onEdit: (r) => _handleEdit(context, ref, r),
                                  onDelete: (r) => _handleDelete(context, ref, r),
                                )
                              else
                                ...records.map((record) => _LessonRecordCard(
                                      record: record,
                                      isAdmin: isAdmin,
                                      currentUserId: user.uid,
                                      onEdit: () => _handleEdit(context, ref, record),
                                      onDelete: () => _handleDelete(context, ref, record),
                                    )),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
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

class _LessonRecordCard extends ConsumerWidget {
  const _LessonRecordCard({
    required this.record,
    required this.isAdmin,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });
  final LessonRecord record;
  final bool isAdmin;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                        color: Color(0xFF3B82F6).withOpacity(0.08),
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
                    if (isAdmin || record.teacherId == currentUserId) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
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
                          fontFamily: 'NotoSansBengali',
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
                                  fontFamily: 'NotoSansBengali',
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
                  backgroundColor: Color(0xFF1E293B).withOpacity(0.1),
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
  final _chapterController = TextEditingController();
  String _selectedPeriod = "1st";
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
      _chapterController.text = widget.editRecord!.chapter;
      _selectedPeriod = widget.editRecord!.period;
      _selectedClassId = widget.editRecord!.classId;
      _selectedSubject = widget.editRecord!.subject;
      if (_topicBnController.text.isNotEmpty || _homeworkBnController.text.isNotEmpty) {
        _showBengali = true;
      }
    } else {
      _selectedSubject = widget.user.subjects.isNotEmpty ? widget.user.subjects.first : widget.user.primarySubject;
    }
  }

  bool _initialized = false;
  void _initDefaults(List<SchoolClass> classes) {
    if (_initialized || classes.isEmpty || widget.editRecord != null) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final firstClass = classes.first;
      final allClassSubjects = firstClass.subjects.keys.toList();
      
      setState(() {
        _selectedClassId = firstClass.id;
        
        final List<String> allClassCombined = {
          ...firstClass.subjects.keys,
          ...widget.user.subjects,
          if (widget.user.primarySubject != null && widget.user.primarySubject!.isNotEmpty) widget.user.primarySubject!,
          "General Lesson",
        }.toList()..sort();

        if (allClassCombined.isNotEmpty) {
           _selectedSubject = allClassCombined.contains(widget.user.primarySubject) 
               ? widget.user.primarySubject 
               : allClassCombined.first;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role == UserRole.admin || widget.user.role == UserRole.cashCollector;
    final classes = ref.watch(isAdmin ? schoolClassesProvider : teacherClassesProvider).value ?? const [];
    final state = ref.watch(adminToolsControllerProvider);

    _initDefaults(classes);

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
                  color: Color(0xFF3B82F6).withOpacity(0.1),
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
              
              final allClassSubjects = cls.subjects.keys.toList();
              
              setState(() {
                _selectedClassId = val;
                
                // If teacher has profile subjects that match class, pick first one
                final profileMatches = widget.user.subjects.where((s) => allClassSubjects.contains(s)).toList();
                
                if (allClassSubjects.isNotEmpty) {
                  if (profileMatches.isNotEmpty) {
                    _selectedSubject = profileMatches.first;
                  } else if (allClassSubjects.contains(widget.user.primarySubject)) {
                    _selectedSubject = widget.user.primarySubject;
                  } else {
                    _selectedSubject = allClassSubjects.first;
                  }
                } else {
                  _selectedSubject = "General Lesson";
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
                
                // Effective subjects for this teacher in this class
                final classMappedSubjects = cls.subjects.entries
                        .where((e) => e.value == widget.user.uid)
                        .map((e) => e.key)
                        .toList();
                
                final List<String> combinedSubjects = {
                  ...cls.subjects.keys,
                  ...widget.user.subjects,
                  if (widget.user.primarySubject != null && widget.user.primarySubject!.isNotEmpty) widget.user.primarySubject!,
                  "Bengali", "English", "Math", "Physics", "Arabic", "GK", "Drawing", "Game", 
                  "Environment Science", "History", "Geography", "Hindi", "Computer", 
                  "Work Education", "Physical Education", "Life Science", "Physical Science", 
                  "Chemistry", "Biology", "Social Science", "Physiology", 
                  "English Rhymes", "Bengali Rhymes",
                  "General Lesson", "Lesson Review",
                }.toList()..sort();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Subject",
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  value: combinedSubjects.contains(_selectedSubject) ? _selectedSubject : null,
                  items: combinedSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val),
                );
              }
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Period"),
                  value: _selectedPeriod,
                  items: ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPeriod = val ?? "1st"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _chapterController,
                  decoration: const InputDecoration(labelText: "Chapter No/Name", hintText: "e.g. 5 or Geometry"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: "Topic Covered (English)", hintText: "What was taught?"),
            maxLines: 2,
            textInputAction: TextInputAction.next,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _homeworkController,
            decoration: const InputDecoration(labelText: "Homework Tasks (English)", hintText: "Optional assignments..."),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onChanged: (val) => setState(() {}),
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
                  style: const TextStyle(fontFamily: 'NotoSansBengali'),
                  decoration: const InputDecoration(
                    labelText: "বিষয় (Bengali Topic)",
                    hintText: "আজ কি পড়ানো হলো?",
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _homeworkBnController,
                  style: const TextStyle(fontFamily: 'NotoSansBengali'),
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
                            period: _selectedPeriod,
                            chapter: _chapterController.text.trim(),
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
                            period: _selectedPeriod,
                            chapter: _chapterController.text.trim(),
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

    final user = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.cashCollector;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AsyncValueView<List<SchoolClass>>(
        value: classesValue,
        data: (allClasses) {
          final filter = ref.watch(globalSchoolFilterProvider);
          final currentTeacherClasses = isAdmin ? <String>[] : (ref.watch(teacherClassesProvider).valueOrNull ?? []).map((c) => c.id).toList();

          final filteredClasses = allClasses.where((c) {
            if (!isAdmin && !currentTeacherClasses.contains(c.id)) return false;
            final genderMatch = filter.gender == GenderFilter.all || c.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
            final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? c.isJunior : !c.isJunior);
            return genderMatch && levelMatch;
          }).toList();

          if (filteredClasses.isEmpty) return const SizedBox.shrink();
          
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
                ...filteredClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
              ],
              onChanged: (val) => ref.read(diaryClassFilterProvider.notifier).state = val,
            ),
          );
        },
      ),
    );
  }
}
class _DiaryTableView extends StatelessWidget {
  const _DiaryTableView({
    required this.records, 
    required this.isAdmin,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });
  final List<LessonRecord> records;
  final bool isAdmin;
  final String currentUserId;
  final Function(LessonRecord) onEdit;
  final Function(LessonRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    // Sort records by period (standardized format like 1st, 2nd...)
    final sorted = List<LessonRecord>.from(records)
      ..sort((a, b) => a.period.compareTo(b.period));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        columnSpacing: 16,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        columns: const [
          DataColumn(label: Text("")), 
          DataColumn(label: Text("Period")),
          DataColumn(label: Text("Subject")),
          DataColumn(label: Text("Chapter")),
          DataColumn(label: Text("Activity")),
          DataColumn(label: Text("Homework")),
          DataColumn(label: Text("Sign")),
        ],
        rows: sorted.map((r) => DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin || r.teacherId == currentUserId) ...[
                    IconButton(onPressed: () => onEdit(r), icon: const Icon(Icons.edit, size: 18, color: Color(0xFF64748B))),
                    IconButton(onPressed: () => onDelete(r), icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                  ],
                ],
              ),
            ),
            DataCell(Text(r.period, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(r.subject)),
            DataCell(Text(r.chapter)),
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  r.topicBn.isNotEmpty ? "${r.topic}\n${r.topicBn}" : r.topic,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  r.homeworkBn.isNotEmpty ? "${r.homework}\n${r.homeworkBn}" : r.homework,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.teacherName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(DateFormat("HH:mm").format(r.createdAt), style: const TextStyle(fontSize: 9, color: Colors.black45)),
                ],
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }
}
class _PdfDownloadRow extends StatelessWidget {
  const _PdfDownloadRow({
    required this.allClasses,
    required this.effectiveClassId,
    required this.records,
    required this.selectedDate,
  });

  final List<SchoolClass> allClasses;
  final String effectiveClassId;
  final List<LessonRecord> records;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                final cls = allClasses.firstWhere((c) => c.id == effectiveClassId);
                DiaryPdfGenerator.generateAndShare(
                  records: records,
                  schoolClass: cls,
                  date: selectedDate,
                );
              },
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text("Share PDF"),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE50914), // PDF Red
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                final cls = allClasses.firstWhere((c) => c.id == effectiveClassId);
                DiaryPdfGenerator.generateAndShareImage(
                  records: records,
                  schoolClass: cls,
                  date: selectedDate,
                );
              },
              icon: const Icon(Icons.image, size: 18),
              label: const Text("Share Image"),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
