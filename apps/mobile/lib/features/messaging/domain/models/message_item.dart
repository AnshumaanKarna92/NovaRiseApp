class MessageItem {
  const MessageItem({
    required this.type,
    required this.text,
    this.dueDate,
  });

  final String type;
  final String text;
  final String? dueDate;
}
