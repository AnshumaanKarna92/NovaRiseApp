import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/messages_controller.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages & Homework')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Card(
            child: ListTile(
              title: Text(message.type.toUpperCase()),
              subtitle: Text(
                message.dueDate == null
                    ? message.text
                    : '${message.text}\nDue: ${message.dueDate}',
              ),
              isThreeLine: message.dueDate != null,
            ),
          );
        },
      ),
    );
  }
}
