class FeeInvoice {
  const FeeInvoice({
    required this.invoiceId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.paymentStatus,
  });

  final String invoiceId;
  final String title;
  final double amount;
  final String dueDate;
  final String status;
  final String paymentStatus;
}
