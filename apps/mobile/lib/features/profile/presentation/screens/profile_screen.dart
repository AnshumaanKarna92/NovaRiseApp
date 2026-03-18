import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('Linked Student'),
              subtitle: Text('Priya Sharma | Class 5A'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Parent Contact'),
              subtitle: Text('+91xxxxxxxxxx'),
            ),
          ),
        ],
      ),
    );
  }
}
