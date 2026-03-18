class ImportJob {
  const ImportJob({
    required this.jobId,
    required this.type,
    required this.status,
    required this.successCount,
    required this.failureCount,
  });

  factory ImportJob.fromMap(String id, Map<String, dynamic> data) {
    final summary = Map<String, dynamic>.from(data["summary"] as Map? ?? const {});
    return ImportJob(
      jobId: id,
      type: data["type"] as String? ?? "",
      status: data["status"] as String? ?? "",
      successCount: summary["successCount"] as int? ?? 0,
      failureCount: summary["failureCount"] as int? ?? 0,
    );
  }

  final String jobId;
  final String type;
  final String status;
  final int successCount;
  final int failureCount;
}
