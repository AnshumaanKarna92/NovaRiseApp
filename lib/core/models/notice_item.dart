class NoticeItem {
  const NoticeItem({
    required this.noticeId,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetClassIds,
    required this.startAt,
    required this.expiresAt,
  });

  factory NoticeItem.fromMap(String id, Map<String, dynamic> data) {
    return NoticeItem(
      noticeId: id,
      title: data["title"] as String? ?? "Notice",
      body: data["body"] as String? ?? "",
      targetType: data["targetType"] as String? ?? "all",
      targetClassIds: List<String>.from(data["targetClassIds"] as List? ?? const []),
      startAt: data["startAt"] as String? ?? "",
      expiresAt: data["expiresAt"] as String? ?? "",
    );
  }

  final String noticeId;
  final String title;
  final String body;
  final String targetType;
  final List<String> targetClassIds;
  final String startAt;
  final String expiresAt;
}
