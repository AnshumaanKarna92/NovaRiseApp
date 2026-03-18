import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/messages_repository.dart';
import '../../domain/models/message_item.dart';

final messagesRepositoryProvider = Provider((ref) => const MessagesRepository());
final messagesProvider = Provider<List<MessageItem>>((ref) {
  return ref.watch(messagesRepositoryProvider).fetchMessages();
});
