class FeePayment {
  const FeePayment({
    required this.paymentId,
    required this.invoiceId,
    required this.studentId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.clientReference,
    required this.screenshotUrl,
    required this.uploadedByUid,
  });

  factory FeePayment.fromMap(String id, Map<String, dynamic> data) {
    return FeePayment(
      paymentId: id,
      invoiceId: data["invoiceId"] as String? ?? "",
      studentId: data["studentId"] as String? ?? "",
      amount: (data["amount"] as num?)?.toDouble() ?? 0,
      status: data["status"] as String? ?? "",
      paymentMethod: data["paymentMethod"] as String? ?? "",
      clientReference: data["clientReference"] as String? ?? "",
      screenshotUrl: data["screenshotUrl"] as String? ?? "",
      uploadedByUid: data["uploadedByUid"] as String? ?? "",
    );
  }

  final String paymentId;
  final String invoiceId;
  final String studentId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String clientReference;
  final String screenshotUrl;
  final String uploadedByUid;
}
