class FeeInvoice {
  const FeeInvoice({
    required this.invoiceId,
    required this.studentId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.paymentStatus,
  });

  factory FeeInvoice.fromMap(String id, Map<String, dynamic> data) {
    return FeeInvoice(
      invoiceId: id,
      studentId: data["studentId"] as String? ?? "",
      title: data["title"] as String? ?? "Fee Invoice",
      amount: (data["amount"] as num?)?.toDouble() ?? 0,
      dueDate: data["dueDate"] as String? ?? "",
      status: data["status"] as String? ?? "",
      paymentStatus: data["paymentStatus"] as String? ?? "",
    );
  }

  final String invoiceId;
  final String studentId;
  final String title;
  final double amount;
  final String dueDate;
  final String status;
  final String paymentStatus;
}
