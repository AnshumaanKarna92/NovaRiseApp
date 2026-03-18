class MessageItem {
  const MessageItem({
    required this.messageId,
    required this.classId,
    required this.type,
    required this.text,
    required this.createdAtLabel,
    this.dueDate,
  });

  factory MessageItem.fromMap(String id, Map<String, dynamic> data) {
    return MessageItem(
      messageId: id,
      classId: data["classId"] as String? ?? "",
      type: data["type"] as String? ?? "message",
      text: data["text"] as String? ?? "",
      dueDate: data["dueDate"] as String?,
      createdAtLabel: data["createdAt"]?.toString() ?? "",
    );
  }

  final String messageId;
  final String classId;
  final String type;
  final String text;
  final String createdAtLabel;
  final String? dueDate;
}
