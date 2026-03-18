import 'package:flutter/material.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('Pending Fee Verifications'),
              subtitle: Text('Backed by `getDashboardSummaries` and fee payment records.'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('CSV Imports'),
              subtitle: Text('Track import jobs and validation reports.'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Attendance Review'),
              subtitle: Text('Review daily attendance and override with audit logging.'),
            ),
          ),
        ],
      ),
    );
  }
}
