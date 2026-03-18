import '../../domain/models/fee_invoice.dart';

class FeesRepository {
  const FeesRepository();

  List<FeeInvoice> fetchInvoices() {
    return const [
      FeeInvoice(
        invoiceId: 'INV_2026_001',
        title: 'March Tuition Fee',
        amount: 1500,
        dueDate: '2026-03-31',
        status: 'unpaid',
        paymentStatus: 'none',
      ),
      FeeInvoice(
        invoiceId: 'INV_2026_002',
        title: 'Transport Fee',
        amount: 600,
        dueDate: '2026-03-20',
        status: 'unpaid',
        paymentStatus: 'pending_verification',
      ),
    ];
  }
}
