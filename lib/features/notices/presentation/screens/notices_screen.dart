import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/notice_item.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "../../../admin_tools/presentation/controllers/admin_tools_controller.dart";
import "../controllers/notices_controller.dart";
import "package:nova_rise_app/shared/widgets/filter_bar.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isTab = !Navigator.of(context).canPop();

    ref.listen<NoticeSubmissionState>(noticeSubmissionControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        ref.read(noticeSubmissionControllerProvider.notifier).clearMessage();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.cashCollector;

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Notices")),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => NoticesScreen.showNoticeDialog(context, ref),
              label: const Text("Create Notice"),
              icon: const Icon(Icons.campaign),
            )
          : null,
      body: Column(
        children: [
          if (isAdmin) const GlobalFilterBar(),
          Expanded(
            child: AsyncValueView(
              value: notices,
              data: (itemsRaw) {
                final filter = ref.watch(globalSchoolFilterProvider);
                final allClasses = ref.watch(schoolClassesProvider).valueOrNull ?? [];
                
                final items = itemsRaw.where((notice) {
                  if (notice.targetType == "all" || notice.targetType == "teachers") return true;
                  return notice.targetClassIds.any((id) {
                    final cls = allClasses.firstWhere((c) => c.id == id, orElse: () => SchoolClass(id: id, schoolId: "unknown", name: id, branchIdFromData: "unknown", subjects: {}));
                    final genderMatch = filter.gender == GenderFilter.all || cls.branchId == (filter.gender == GenderFilter.boys ? "boys" : "girls");
                    final levelMatch = filter.level == LevelFilter.all || (filter.level == LevelFilter.junior ? cls.isJunior : !cls.isJunior);
                    return genderMatch && levelMatch;
                  });
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const ScreenIntroCard(
                      title: "Academy Notice Board",
                      description: "Stay informed with official announcements and academic circulars.",
                      icon: Icons.campaign_outlined,
                      accent: Color(0xFF003D5B),
                    ),
                    const SizedBox(height: 24),
                    if (items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text("No official notices found matching your filters."),
                        ),
                      )
                    else
                      for (final notice in items)
                        _NoticeCard(notice: notice, isAdmin: isAdmin),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static void showNoticeDialog(BuildContext context, WidgetRef ref, {NoticeItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _NoticeEntrySheet(existing: existing),
    );
  }
}

class _NoticeCard extends ConsumerWidget {
  const _NoticeCard({required this.notice, required this.isAdmin});
  final NoticeItem notice;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesMap = ref.watch(allClassesMapProvider);
    final String targetLabel = notice.targetType == "all" 
        ? "Everyone" 
        : notice.targetType == "teachers" 
            ? "Teachers Group" 
            : notice.targetClassIds.map((id) => classesMap[id] ?? id).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        notice.startAt,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                            onPressed: () => NoticesScreen.showNoticeDialog(context, ref, existing: notice),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, ref),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notice.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notice.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "TARGET: $targetLabel".toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notice?"),
        content: const Text("Are you sure you want to remove this announcement permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(noticeSubmissionControllerProvider.notifier).delete(notice.noticeId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _NoticeEntrySheet extends ConsumerStatefulWidget {
  const _NoticeEntrySheet({this.existing});
  final NoticeItem? existing;

  @override
  ConsumerState<_NoticeEntrySheet> createState() => _NoticeEntrySheetState();
}

class _NoticeEntrySheetState extends ConsumerState<_NoticeEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String _targetType = "all";
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title);
    _bodyController = TextEditingController(text: widget.existing?.body);
    _targetType = widget.existing?.targetType ?? "all";
    if (widget.existing?.targetClassIds.isNotEmpty ?? false) {
      _selectedClassId = widget.existing!.targetClassIds.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noticeSubmissionControllerProvider);
    final classesValue = ref.watch(schoolClassesProvider);
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? "Publish Academy Notice" : "Edit Notice",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Notice Title", hintText: "Formal title of the announcement"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: "Notice Content", hintText: "Enter complete announcement data..."),
          ),
          const SizedBox(height: 24),
          const Text("Select Audience Target", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text("All"),
                selected: _targetType == "all",
                onSelected: (val) => setState(() => _targetType = "all"),
              ),
              ChoiceChip(
                label: const Text("Teachers Only"),
                selected: _targetType == "teachers",
                onSelected: (val) => setState(() => _targetType = "teachers"),
              ),
              ChoiceChip(
                label: const Text("Specific Class"),
                selected: _targetType == "classes",
                onSelected: (val) => setState(() => _targetType = "classes"),
              ),
            ],
          ),
          if (_targetType == "classes") ...[
            const SizedBox(height: 16),
            classesValue.when(
              data: (list) => DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(labelText: "Target Class"),
                items: list.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
                onChanged: (val) => setState(() => _selectedClassId = val),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Failed to load classes"),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () async {
                    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;
                    if (_targetType == "classes" && _selectedClassId == null) return;

                    if (widget.existing == null) {
                      await ref.read(noticeSubmissionControllerProvider.notifier).submit(
                            title: _titleController.text.trim(),
                            body: _bodyController.text.trim(),
                            targetType: _targetType,
                            targetClassIds: _targetType == "classes" ? [_selectedClassId!] : [],
                            startAt: dateStr,
                            expiresAt: "2026-12-31",
                          );
                    } else {
                      await ref.read(noticeSubmissionControllerProvider.notifier).update(
                            noticeId: widget.existing!.noticeId,
                            title: _titleController.text.trim(),
                            body: _bodyController.text.trim(),
                            targetType: _targetType,
                            targetClassIds: _targetType == "classes" ? [_selectedClassId!] : [],
                          );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(state.isSubmitting ? "Processing..." : (widget.existing == null ? "Publish Announcement" : "Update Notice")),
          ),
        ],
      ),
    );
  }
}
