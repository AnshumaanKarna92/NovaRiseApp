import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/notices_controller.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return Card(
            child: ListTile(
              title: Text(notice.title),
              subtitle: Text('${notice.body}\nExpires: ${notice.expiresAt}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
