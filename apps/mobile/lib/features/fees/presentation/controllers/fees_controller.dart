import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fees_repository.dart';
import '../../domain/models/fee_invoice.dart';

final feesRepositoryProvider = Provider((ref) => const FeesRepository());
final feesProvider = Provider<List<FeeInvoice>>((ref) {
  return ref.watch(feesRepositoryProvider).fetchInvoices();
});
