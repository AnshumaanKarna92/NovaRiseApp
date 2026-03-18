import '../../domain/models/message_item.dart';

class MessagesRepository {
  const MessagesRepository();

  List<MessageItem> fetchMessages() {
    return const [
      MessageItem(
        type: 'homework',
        text: 'Bring your science notebook tomorrow.',
        dueDate: '2026-03-12',
      ),
      MessageItem(
        type: 'message',
        text: 'PTM will be held on Saturday at 11 AM.',
      ),
    ];
  }
}
