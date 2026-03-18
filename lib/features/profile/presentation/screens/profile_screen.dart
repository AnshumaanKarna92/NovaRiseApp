import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/app_surface.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";

import "../../../../core/models/app_user.dart";
import "../controllers/profile_update_controller.dart";

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
    final isTab = !Navigator.of(context).canPop();

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Account")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileHeader(user: user, ref: ref),
          const SizedBox(height: 24),
          Text(
            "Account Security",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Color(0xFF003D5B)),
                  title: const Text("Access Password"),
                  subtitle: const Text("Update your portal security key"),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showChangePasswordSheet(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Academic Portfolio",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(label: "Academic Role", value: user?.role.name.toUpperCase() ?? "Unknown"),
                  const Divider(height: 24),
                  _InfoRow(label: "School ID", value: user?.schoolId ?? "Not assigned"),
                  const Divider(height: 24),
                  _InfoRow(label: "Registration Status", value: "VERIFIED"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (students.isNotEmpty) ...[
            Text(
              "Connected Students",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final student in students)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF003D5B),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${student.studentId} • Class ${student.classId}"),
                  trailing: const StatusChip(label: "ACTIVE", color: Color(0xFF00A86B)),
                ),
              ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text("Secure Sign Out"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "Nova Rise Academy App v1.1.0 (Live)",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ChangePasswordSheet(),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Update Password", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Enter a new complex password to secure your academy account."),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "New Password", prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Confirm New Password", prefixIcon: Icon(Icons.lock_reset_outlined)),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      if (_passwordController.text != _confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
                        return;
                      }
                      await ref.read(loginControllerProvider.notifier).updatePassword(_passwordController.text);
                      if (context.mounted && ref.read(loginControllerProvider).error == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully.")));
                      }
                    },
              child: Text(state.isSubmitting ? "Updating..." : "Update Password"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user, required this.ref});
  final AppUser? user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(profileUpdateControllerProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF003D5B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl.isNotEmpty
                      ? NetworkImage(user!.profileImageUrl)
                      : null,
                  child: (user?.profileImageUrl == null || user!.profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF003D5B))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => ref.read(profileUpdateControllerProvider.notifier).pickAndUploadPhoto(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                    child: updateState.isUploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? "Academy User",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role == UserRole.teacher ? "Senior Faculty" : user?.role == UserRole.parent ? "Family Contact" : "Administrator",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
