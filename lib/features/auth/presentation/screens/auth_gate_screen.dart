import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/models/app_user.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../../shared/widgets/feature_card.dart";
import "../../../admin_tools/presentation/controllers/admin_tools_controller.dart";
import "../../../admin_tools/presentation/screens/admin_tools_screen.dart";
import "../../../attendance/presentation/controllers/attendance_controller.dart";
import "../../../attendance/presentation/screens/attendance_screen.dart";
import "../../../fees/presentation/controllers/fees_controller.dart";
import "../../../fees/presentation/screens/fees_screen.dart";
import "../../../messages/presentation/controllers/messages_controller.dart";
import "../../../messages/presentation/screens/messages_screen.dart";
import "../../../notices/presentation/controllers/notices_controller.dart";
import "../../../notices/presentation/screens/notices_screen.dart";
import "../../../profile/presentation/screens/profile_screen.dart";
import "../../../students/presentation/controllers/student_controller.dart";
import "../../../transport/presentation/controllers/transport_controller.dart";
import "../../../transport/presentation/screens/transport_screen.dart";
import "../controllers/session_controller.dart";
import "sign_in_screen.dart";

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  bool _bootstrapInProgress = false;
  String? _bootstrapError;
  String? _lastUidAttempted;

  Future<void> _bootstrapProfile() async {
    if (_bootstrapInProgress) {
      return;
    }

    setState(() {
      _bootstrapInProgress = true;
      _bootstrapError = null;
    });

    try {
      final fcmToken = await ref.read(notificationServiceProvider).getToken();
      await ref.read(authServiceProvider).ensureUserProfile(fcmToken: fcmToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrapInProgress = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrapInProgress = false;
        _bootstrapError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(userProfileProvider);

    if (authState.isLoading || profileState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firebaseUser = authState.valueOrNull;
    if (firebaseUser == null) {
      return const SignInScreen();
    }

    final profile = profileState.valueOrNull;
    if (profile == null) {
      final uid = firebaseUser.uid;
      
      if (_lastUidAttempted != uid) {
        _lastUidAttempted = uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _bootstrapProfile();
          }
        });
      }

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset("assets/images/logo.png", height: 100, width: 100),
                ),
                const SizedBox(height: 32),
                Text(
                  "Initializing Academy Workspace",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Preparing records, schedules, and secured data...",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_bootstrapInProgress)
                  const CircularProgressIndicator()
                else if (_bootstrapError != null) ...[
                  Text(
                    "Connection mismatch: $_bootstrapError",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _bootstrapProfile,
                    child: const Text("Reconnect"),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: const Text("Sign Out"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _AuthenticatedLayout(profile: profile);
  }
}

class _AuthenticatedLayout extends ConsumerStatefulWidget {
  const _AuthenticatedLayout({required this.profile});
  final AppUser profile;

  @override
  ConsumerState<_AuthenticatedLayout> createState() => _AuthenticatedLayoutState();
}

class _AuthenticatedLayoutState extends ConsumerState<_AuthenticatedLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final tabs = _getTabsForRole(profile.role);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => setState(() => _selectedIndex = 0),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/logo.png", height: 32, width: 32, fit: BoxFit.contain),
                const SizedBox(width: 10),
                const Text("Nova Rise"),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.black45,
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  List<_TabInfo> _getTabsForRole(UserRole role) {
    return switch (role) {
      UserRole.parent => [
          _TabInfo(
            label: "Home",
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            body: _DashboardView(profile: widget.profile),
          ),
          const _TabInfo(
            label: "Fees",
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            body: FeesScreen(),
          ),
          const _TabInfo(
            label: "Attendance",
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            body: AttendanceScreen(),
          ),
          const _TabInfo(
            label: "Notices",
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign,
            body: NoticesScreen(),
          ),
          const _TabInfo(
            label: "Transport",
            icon: Icons.directions_bus_outlined,
            activeIcon: Icons.directions_bus,
            body: TransportScreen(),
          ),
          const _TabInfo(
            label: "Profile",
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            body: ProfileScreen(),
          ),
        ],
      UserRole.teacher => [
          _TabInfo(
            label: "Home",
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            body: _DashboardView(profile: widget.profile),
          ),
          const _TabInfo(
            label: "Attendance",
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            body: AttendanceScreen(),
          ),
          const _TabInfo(
            label: "Messages",
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            body: MessagesScreen(),
          ),
          const _TabInfo(
            label: "Profile",
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            body: ProfileScreen(),
          ),
        ],
      UserRole.admin || UserRole.cashCollector => [
          _TabInfo(
            label: "Home",
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            body: _DashboardView(profile: widget.profile),
          ),
          const _TabInfo(
            label: "Operations",
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            body: AdminToolsScreen(),
          ),
          const _TabInfo(
            label: "Finances",
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments,
            body: FeesScreen(),
          ),
          const _TabInfo(
            label: "Transport",
            icon: Icons.directions_bus_outlined,
            activeIcon: Icons.directions_bus,
            body: TransportScreen(),
          ),
          const _TabInfo(
            label: "Profile",
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            body: ProfileScreen(),
          ),
        ],
      _ => [
          _TabInfo(
            label: "Home",
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            body: _DashboardView(profile: widget.profile),
          ),
          const _TabInfo(
            label: "Profile",
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            body: ProfileScreen(),
          ),
        ],
    };
  }

  // Removed _showDemoMenu for final version
}

class _TabInfo {
  const _TabInfo({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.body,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget body;
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.profile});
  final AppUser profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = _cardsForRole(profile.role);
    final students = ref.watch(currentStudentsProvider).valueOrNull ?? const [];
    final fees = ref.watch(feeInvoicesProvider).valueOrNull ?? const [];
    final notices = ref.watch(noticesProvider).valueOrNull ?? const [];
    final messages = ref.watch(messagesProvider).valueOrNull ?? const [];
    final attendance = ref.watch(attendanceSummariesProvider).valueOrNull ?? const [];
    final routes = ref.watch(routesProvider).valueOrNull ?? const [];
    final adminSummary = ref.watch(adminSummaryProvider).valueOrNull;

    final stats = _getStatsForRole(profile, students, fees, notices, messages, attendance, routes, adminSummary);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Namaste, ${profile.displayName.split(' ').first}",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _roleLabel(profile.role),
                    style: TextStyle(color: _accentForRole(profile.role), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: _accentForRole(profile.role).withValues(alpha: 0.1),
              child: Icon(_iconForRole(profile.role), color: _accentForRole(profile.role)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SmartBanner(
          profile: profile,
          stats: stats,
          notices: notices,
        ),
        const SizedBox(height: 32),
        Text(
          "Management Tools",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: cards.map((card) {
            return FeatureCard(
              title: card.$1,
              subtitle: card.$2,
              icon: card.$4,
              onTap: () => context.push(card.$3),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        const _HelpSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.parent => "PARENT PORTAL",
      UserRole.teacher => "ACADEMIC STAFF",
      UserRole.admin => "ADMINISTRATION",
      _ => "GUEST",
    };
  }

  List<(String, String, String, IconData, Color)> _getStatsForRole(
    AppUser profile,
    List students,
    List fees,
    List notices,
    List messages,
    List attendance,
    List routes,
    Map? adminSummary,
  ) {
    return switch (profile.role) {
      UserRole.parent => [
          ("Students", "${students.length}", "Linked children", Icons.family_restroom, const Color(0xFF003D5B)),
          ("Fees", "${fees.length}", "Pending items", Icons.receipt_long, const Color(0xFFD4AF37)),
          ("Transport", "${routes.length}", "Active routes", Icons.directions_bus, const Color(0xFF00A86B)),
        ],
      UserRole.teacher => [
          ("Classes", "${profile.assignedClassIds.length}", "Assigned focus", Icons.class_outlined, const Color(0xFF003D5B)),
          ("Students", "${students.length}", "Roster size", Icons.groups_2, const Color(0xFF00A86B)),
          ("Attendance", "${attendance.length}", "Daily records", Icons.fact_check, const Color(0xFFD4AF37)),
        ],
      UserRole.admin || UserRole.cashCollector => [
          ("Queue", "${adminSummary?["pendingFees"] ?? 0}", "Verification", Icons.payments, const Color(0xFFD4AF37)),
          ("Notices", "${adminSummary?["notices"] ?? notices.length}", "School feed", Icons.campaign, const Color(0xFF003D5B)),
          ("Comm Vol", "${adminSummary?["messages"] ?? messages.length}", "Entries", Icons.forum, const Color(0xFF00A86B)),
        ],
      _ => [("Active", "1", "Status OK", Icons.person, const Color(0xFF003D5B))],
    };
  }

  List<(String, String, String, IconData)> _cardsForRole(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return [
          ("Fees", "Pay invoices", "/fees", Icons.receipt_long_outlined),
          ("Notices", "School feed", "/notices", Icons.campaign_outlined),
          ("Transport", "Bus tracking", "/transport", Icons.directions_bus_outlined),
          ("Homework", "Class news", "/messages", Icons.forum_outlined),
        ];
      case UserRole.teacher:
        return [
          ("Attendance", "Mark daily", "/attendance", Icons.fact_check_outlined),
          ("Students", "Class roster", "/students", Icons.groups_2_outlined),
          ("Homework", "Post task", "/messages", Icons.edit_note_outlined),
          ("Notices", "Read alerts", "/notices", Icons.notifications_active_outlined),
        ];
      case UserRole.admin:
      case UserRole.cashCollector:
        return [
          ("Operations", "Verify queue", "/admin-tools", Icons.admin_panel_settings_outlined),
          ("Financials", "Fee records", "/fees", Icons.payments_outlined),
          ("Transport", "Bus routes", "/transport", Icons.directions_bus_outlined),
          ("Directory", "Search all", "/students", Icons.groups_outlined),
        ];
      case UserRole.unknown:
        return [("Profile", "My records", "/profile", Icons.person_outline)];
    }
  }

  IconData _iconForRole(UserRole role) {
    return switch (role) {
      UserRole.parent => Icons.family_restroom,
      UserRole.teacher => Icons.cast_for_education_outlined,
      UserRole.admin || UserRole.cashCollector => Icons.space_dashboard_outlined,
      UserRole.unknown => Icons.person_outline,
    };
  }

  Color _accentForRole(UserRole role) {
    return switch (role) {
      UserRole.parent => const Color(0xFF003D5B),
      UserRole.teacher => const Color(0xFF00A86B),
      UserRole.admin || UserRole.cashCollector => const Color(0xFFD4AF37),
      UserRole.unknown => const Color(0xFF003D5B),
    };
  }
}

class _SmartBanner extends StatelessWidget {
  const _SmartBanner({
    required this.profile,
    required this.stats,
    required this.notices,
  });

  final AppUser profile;
  final List<(String, String, String, IconData, Color)> stats;
  final List notices;

  @override
  Widget build(BuildContext context) {
    final accent = stats.first.$5;
    final latestNotice = notices.isEmpty ? null : notices.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYSTEM OVERVIEW",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.emergency_outlined, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.map((s) => _StatusItem(label: s.$1, value: s.$2)).toList(),
          ),
          const Divider(height: 48, color: Colors.white24),
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  latestNotice != null
                      ? "Latest: ${latestNotice.title}"
                      : "No unread school announcements today.",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white38, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.help_center_outlined, color: Colors.black45),
              SizedBox(width: 12),
              Text(
                "Academic Support",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "For technical issues or record corrections, please visit the school office.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connecting to school office: 011-23456789")),
                    );
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text("Call Office"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Opening school mail composer: help@novarise.com")),
                    );
                  },
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text("Email Us"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugTile extends StatelessWidget {
  const _DebugTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
