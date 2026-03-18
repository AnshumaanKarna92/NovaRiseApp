import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/app_user.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../controllers/notices_controller.dart";

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

    final canPost = user?.role == UserRole.admin;

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Notices")),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => _showNoticeDialog(context, ref),
              label: const Text("New Notice"),
              icon: const Icon(Icons.add),
            )
          : null,
      body: AsyncValueView(
        value: notices,
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ScreenIntroCard(
                title: "Academy Notice Board",
                description:
                    "Stay informed with official school announcements, holiday calendars, and academic circulars.",
                icon: Icons.campaign_outlined,
                accent: Color(0xFF003D5B),
              ),
              const SizedBox(height: 24),
              if (items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("No official notices published yet."),
                  ),
                )
              else
                for (final notice in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.new_releases_outlined,
                                  size: 20, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(
                                notice.startAt,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notice.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notice.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
    );
  }

  void _showNoticeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NoticeEntrySheet(),
    );
  }
}

class _NoticeEntrySheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NoticeEntrySheet> createState() => _NoticeEntrySheetState();
}

class _NoticeEntrySheetState extends ConsumerState<_NoticeEntrySheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noticeSubmissionControllerProvider);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Publish School Notice", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "Notice Title",
              hintText: "e.g. Summer Vacation Announcement",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Detailed Description",
              hintText: "Enter the complete notice text here...",
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
                        return;
                      }
                      await ref.read(noticeSubmissionControllerProvider.notifier).submit(
                            title: _titleController.text.trim(),
                            body: _bodyController.text.trim(),
                            targetType: "all",
                            targetClassIds: [],
                            startAt: dateStr,
                            expiresAt: "2026-12-31",
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: Text(state.isSubmitting ? "Publishing..." : "Publish to All"),
            ),
          ),
        ],
      ),
    );
  }
}
