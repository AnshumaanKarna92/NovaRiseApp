import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user.dart';
import '../controllers/session_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'This scaffold uses demo role sign-in. Replace it with Firebase phone authentication.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).signInAs(UserRole.parent);
              context.go('/');
            },
            child: const Text('Continue as Parent'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).signInAs(UserRole.teacher);
              context.go('/');
            },
            child: const Text('Continue as Teacher'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).signInAs(UserRole.admin);
              context.go('/');
            },
            child: const Text('Continue as Admin'),
          ),
        ],
      ),
    );
  }
}
