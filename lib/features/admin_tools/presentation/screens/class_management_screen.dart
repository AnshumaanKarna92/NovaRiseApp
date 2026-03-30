import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Assignments (v1.2.2)")),
      body: const Center(child: Text("Build Debug Mode")),
    );
  }
}
