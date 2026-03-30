import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/app_surface.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "../controllers/profile_update_controller.dart";

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
    final classesMap = ref.watch(allClassesMapProvider);
    final isTab = !Navigator.of(context).canPop();

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Account")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileHeader(user: user, ref: ref),
          const SizedBox(height: 24),
          
          if (user?.role == UserRole.admin) ...[
            Text(
              "Administrative Identity",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _InfoRow(label: "Full Name", value: user?.displayName ?? "Administrator"),
                    const Divider(height: 24),
                    _InfoRow(label: "Official Role", value: "System Superintendent"),
                    const Divider(height: 24),
                    _InfoRow(label: "Institution", value: "Nova Rise Academy"),
                    const Divider(height: 24),
                    _InfoRow(label: "Access Level", value: "FULL_SYSTEM_CONTROL"),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              "Personal Information",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _InfoRow(
                      label: "Blood Group", 
                      value: user?.bloodGroup ?? "Not set",
                      onEdit: () => _showEditInfoSheet(context, ref, "Blood Group", user?.bloodGroup, (val) => ref.read(profileUpdateControllerProvider.notifier).updateProfile(bloodGroup: val)),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: "Contact", 
                      value: user?.phone ?? "Not set",
                      onEdit: () => _showEditInfoSheet(context, ref, "Phone Number", user?.phone, (val) => ref.read(profileUpdateControllerProvider.notifier).updateProfile(phone: val)),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: "Display Name", 
                      value: user?.displayName ?? "User",
                      onEdit: () => _showEditInfoSheet(context, ref, "Full Name", user?.displayName, (val) => ref.read(profileUpdateControllerProvider.notifier).updateProfile(displayName: val)),
                    ),
                  ],
                ),
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
                    _InfoRow(label: "Registration ID", value: user?.email.split('@').first.toUpperCase() ?? "N/A"),
                    const Divider(height: 24),
                    _InfoRow(label: "Institution", value: "Nova Rise Academy"),
                    const Divider(height: 24),
                    _InfoRow(label: "Registration Status", value: "VERIFIED"),
                  ],
                ),
              ),
            ),
            if (students.isNotEmpty) ...[
              const SizedBox(height: 24),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classesMap[student.classId] ?? "Grade ${student.classId}"),
                        Text("Reg ID: ${student.studentId}", style: const TextStyle(fontSize: 10, color: Colors.black45)),
                      ],
                    ),
                    trailing: const StatusChip(label: "ACTIVE", color: Color(0xFF00A86B)),
                  ),
                ),
            ],
          ],

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
          
          const SizedBox(height: 32),
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

  void _showEditInfoSheet(BuildContext context, WidgetRef ref, String label, String? currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Edit $label", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Update Information"),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E293B).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl.isNotEmpty
                      ? NetworkImage(user!.profileImageUrl)
                      : null,
                  child: (user?.profileImageUrl == null || user!.profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF1E293B))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => ref.read(profileUpdateControllerProvider.notifier).pickAndUploadPhoto(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E293B), width: 2),
                    ),
                    child: updateState.isUploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? "Academy User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (user?.role == UserRole.teacher ? "Academic Faculty" : user?.role == UserRole.parent ? "Registered Family" : "Institution Admin").toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
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
  const _InfoRow({required this.label, required this.value, this.onEdit});
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD4AF37)),
          ),
      ],
    );
  }
}
