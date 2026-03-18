import 'package:flutter/material.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('Priya Sharma'),
              subtitle: Text('Class 5A | Parent: Suresh Sharma'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Aman Verma'),
              subtitle: Text('Class 5A | Parent: Reena Verma'),
            ),
          ),
        ],
      ),
    );
  }
}
