import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user.dart';
import '../../../../shared/widgets/feature_card.dart';
import '../controllers/session_controller.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SchoolApp')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/sign-in'),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final cards = _cardsForRole(user.role);
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.displayName}'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).signOut();
              context.go('/sign-in');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Role: ${user.role.name} | School: ${user.schoolId}'),
            ),
          ),
          const SizedBox(height: 8),
          for (final card in cards)
            FeatureCard(
              title: card.$1,
              subtitle: card.$2,
              onTap: () => context.go(card.$3),
            ),
        ],
      ),
    );
  }

  List<(String, String, String)> _cardsForRole(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return [
          ('Fees', 'View invoices and upload receipts', '/fees'),
          ('Notices', 'Read school notices', '/notices'),
          ('Messages', 'Homework and class communication', '/messages'),
          ('Profile', 'Linked student details', '/profile'),
        ];
      case UserRole.teacher:
        return [
          ('Attendance', 'Mark and edit attendance', '/attendance'),
          ('Students', 'View class roster', '/students'),
          ('Messages', 'Post class messages and homework', '/messages'),
          ('Notices', 'Read school-wide notices', '/notices'),
        ];
      case UserRole.admin:
      case UserRole.cashCollector:
        return [
          ('Admin Tools', 'Imports, payments, and summaries', '/admin-tools'),
          ('Fees', 'Review fee states', '/fees'),
          ('Attendance', 'Review attendance', '/attendance'),
          ('Notices', 'Publish school notices', '/notices'),
        ];
    }
  }
}
