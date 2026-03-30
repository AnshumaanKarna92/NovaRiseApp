import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "../../../../shared/widgets/app_surface.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../controllers/messages_controller.dart";

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final classesMap = ref.watch(allClassesMapProvider);
    final isTab = !Navigator.of(context).canPop();

    ref.listen<MessageSubmissionState>(messageSubmissionControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        ref.read(messageSubmissionControllerProvider.notifier).clearMessage();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final canPost = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Updates")),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              heroTag: "messages_fab",
              onPressed: () => _showComposeDialog(context, ref, user!),
              label: const Text("Compose"),
              icon: const Icon(Icons.edit_note),
            )
          : null,
      body: AsyncValueView(
        value: messages,
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ScreenIntroCard(
                title: "Internal Updates",
                description:
                    "Review class-specific announcements, homework assignments, and teacher messages.",
                icon: Icons.forum_outlined,
                accent: Color(0xFF00A86B),
              ),
              const SizedBox(height: 24),
              if (items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("Your inbox is currently clear."),
                  ),
                )
              else
                for (final message in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StatusChip(
                                  label: message.type.toUpperCase(), color: const Color(0xFF003D5B)),
                              Text(
                                message.createdAtLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                          ),
                          if (message.classId.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.groups_outlined, size: 16, color: Colors.black45),
                                const SizedBox(width: 8),
                                Text(
                                  classesMap[message.classId] ?? "Grade ${message.classId}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
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

  void _showComposeDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MessageEntrySheet(user: user),
    );
  }
}

class _MessageEntrySheet extends ConsumerStatefulWidget {
  const _MessageEntrySheet({required this.user});
  final AppUser user;

  @override
  ConsumerState<_MessageEntrySheet> createState() => _MessageEntrySheetState();
}

class _MessageEntrySheetState extends ConsumerState<_MessageEntrySheet> {
  final _textController = TextEditingController();
  String _selectedType = "message";
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    if (widget.user.assignedClassIds.isNotEmpty) {
      _selectedClass = widget.user.assignedClassIds.first;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageSubmissionControllerProvider);
    final classesMap = ref.watch(allClassesMapProvider);

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
          Text("New Update", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: "Type"),
            items: const [
              DropdownMenuItem(value: "message", child: Text("General Message")),
              DropdownMenuItem(value: "homework", child: Text("Homework/Assignment")),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: const InputDecoration(labelText: "Target Class"),
            items: widget.user.assignedClassIds
                .map((id) => DropdownMenuItem(value: id, child: Text(classesMap[id] ?? "Grade $id")))
                .toList(),
            onChanged: (val) => setState(() => _selectedClass = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Message Content",
              hintText: "Enter your message or homework description here...",
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting || _selectedClass == null
                  ? null
                  : () async {
                      if (_textController.text.isEmpty) {
                        return;
                      }
                      await ref.read(messageSubmissionControllerProvider.notifier).submit(
                            classId: _selectedClass!,
                            type: _selectedType,
                            text: _textController.text.trim(),
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: Text(state.isSubmitting ? "Sending..." : "Send to Class"),
            ),
          ),
        ],
      ),
    );
  }
}
