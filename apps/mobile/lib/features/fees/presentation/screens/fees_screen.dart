import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/fees_controller.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(feesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return Card(
            child: ListTile(
              title: Text(invoice.title),
              subtitle: Text(
                'Amount: INR ${invoice.amount.toStringAsFixed(0)}\n'
                'Due: ${invoice.dueDate}\n'
                'Status: ${invoice.paymentStatus}',
              ),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('Pay'),
              ),
            ),
          );
        },
      ),
    );
  }
}
