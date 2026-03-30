import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/school_class.dart";
import "package:nova_rise_app/shared/widgets/app_surface.dart";
import "package:nova_rise_app/shared/widgets/feature_card.dart";
import "package:nova_rise_app/features/admin_tools/presentation/controllers/admin_tools_controller.dart";
import "package:nova_rise_app/features/admin_tools/presentation/screens/admin_tools_screen.dart";
import "package:nova_rise_app/features/attendance/presentation/controllers/attendance_controller.dart";
import "package:nova_rise_app/features/attendance/presentation/screens/attendance_screen.dart";
import "package:nova_rise_app/features/diary/presentation/screens/diary_screen.dart";
import "package:nova_rise_app/features/fees/presentation/controllers/fees_controller.dart";
import "package:nova_rise_app/features/fees/presentation/screens/fees_screen.dart";
import "package:nova_rise_app/features/messages/presentation/controllers/messages_controller.dart";
import "package:nova_rise_app/features/messages/presentation/screens/messages_screen.dart";
import "package:nova_rise_app/features/notices/presentation/controllers/notices_controller.dart";
import "package:nova_rise_app/features/notices/presentation/screens/notices_screen.dart";
import "package:nova_rise_app/features/profile/presentation/screens/profile_screen.dart";
import "package:nova_rise_app/features/students/presentation/controllers/student_controller.dart";
import "package:nova_rise_app/features/students/presentation/screens/students_screen.dart";
import "package:nova_rise_app/features/auth/presentation/controllers/session_controller.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";
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

    debugPrint("AUTH_GATE: Starting bootstrap for UID: ${ref.read(authStateProvider).valueOrNull?.uid}");
    try {
      String? fcmToken;
      try {
        debugPrint("AUTH_GATE: Fetching FCM token...");
        fcmToken = await ref.read(notificationServiceProvider).getToken().timeout(const Duration(seconds: 10));
        debugPrint("AUTH_GATE: FCM token fetched: ${fcmToken?.substring(0, 10)}...");
      } catch (e) {
        debugPrint("AUTH_GATE: FCM Token fetch failed/timed out: $e. Proceeding.");
      }
      
      debugPrint("AUTH_GATE: Calling ensureUserProfile...");
      await ref.read(authServiceProvider).ensureUserProfile(fcmToken: fcmToken);
      debugPrint("AUTH_GATE: ensureUserProfile completed.");
      
      if (!mounted) return;
      setState(() {
        _bootstrapInProgress = false;
      });
    } catch (error) {
      debugPrint("AUTH_GATE: Bootstrap FATAL ERROR: $error");
      if (!mounted) return;
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
    
    debugPrint("AUTH_GATE: Build triggered. Auth: ${authState.isLoading ? 'Loading' : authState.valueOrNull?.uid}, Profile: ${profileState.isLoading ? 'Loading' : profileState.valueOrNull?.displayName}");

    if (authState.isLoading || profileState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileState.hasError) {
       debugPrint("AUTH_GATE: Profile Sync Error: ${profileState.error}");
       // Fall through to bootstrap or show error
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

    final isAdmin = profile.role == UserRole.admin || profile.role == UserRole.cashCollector;

    final showDrawer = isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: showDrawer
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: InkWell(
          onTap: () => setState(() => _selectedIndex = 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
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
      drawer: showDrawer
          ? Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/logo.png", height: 60),
                          const SizedBox(height: 12),
                          const Text(
                            "Nova Rise Admin",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tabs.length,
                      itemBuilder: (context, index) {
                        final t = tabs[index];
                        return ListTile(
                          leading: Icon(index == _selectedIndex ? t.activeIcon : t.icon),
                          title: Text(t.label),
                          selected: index == _selectedIndex,
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Sign Out"),
                    onTap: () => ref.read(authServiceProvider).signOut(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: isAdmin
          ? null
          : BottomNavigationBar(
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
            label: "Diary",
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories,
            body: DiaryScreen(),
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
            label: "Diary",
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories,
            body: DiaryScreen(),
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
            label: "Attendance",
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            body: AttendanceScreen(),
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
          _TabInfo(
            label: "Directory",
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            body: StudentsScreen(),
          ),
          const _TabInfo(
            label: "Notices",
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign,
            body: NoticesScreen(),
          ),
          const _TabInfo(
            label: "Diary",
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories,
            body: DiaryScreen(),
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
    final adminSummary = ref.watch(adminSummaryProvider);
    final stats = _getStatsForRole(profile, students, fees, notices, messages, attendance, adminSummary, ref);

    final teacherClasses = profile.role == UserRole.teacher 
        ? ref.watch(teacherClassesProvider).valueOrNull ?? []
        : <SchoolClass>[];

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
                    "Namaste, ${profile.displayName.isNotEmpty ? profile.displayName.split(' ').first : 'Admin'}",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentForRole(profile.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _roleLabel(profile.role).toUpperCase(),
                          style: TextStyle(
                            color: _accentForRole(profile.role),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _accentForRole(profile.role).withOpacity(0.08),
                child: Icon(_iconForRole(profile.role), color: _accentForRole(profile.role), size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SmartBanner(
          profile: profile,
          stats: stats,
          notices: notices,
        ),
        if (profile.role == UserRole.teacher) ...[
          const SizedBox(height: 32),
          Text(
            "Academic Responsibility",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (teacherClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.assignment_ind_outlined, size: 40, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    "No Class Assignments Yet",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  Text(
                    "Contact the administrator to assign you to a Grade or Subject.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            if (teacherClasses.any((c) => c.classTeacherId == profile.uid)) ...[
              const SizedBox(height: 16),
              const Text("Class Teacher", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 12),
              ...teacherClasses.where((c) => c.classTeacherId == profile.uid).map((cls) => _AssignmentCard(cls: cls, profile: profile)),
            ],
            if (teacherClasses.any((c) => c.classTeacherId != profile.uid)) ...[
              const SizedBox(height: 16),
              const Text("Subject Teacher", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 12),
              ...teacherClasses.where((c) => c.classTeacherId != profile.uid).map((cls) => _AssignmentCard(cls: cls, profile: profile)),
            ],
          ],
        ],
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
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: cards.map((card) {
            return FeatureCard(
              title: card.$1,
              subtitle: card.$2,
              icon: card.$4,
              onTap: () {
                if (card.$3 == "/students") {
                  ref.read(studentClassFilterProvider.notifier).state = null;
                }
                context.push(card.$3);
              },
            );
          }).toList(),
        ),
        if (profile.role == UserRole.admin || profile.role == UserRole.cashCollector) ...[
          const SizedBox(height: 32),
          Text(
            "Quick School Overview",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SchoolOverviewGrid(adminSummary: adminSummary),
        ],
        if (profile.role != UserRole.admin && profile.role != UserRole.cashCollector) ...[
          const SizedBox(height: 48),
          const _HelpSection(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SchoolOverviewGrid extends ConsumerWidget {
  const _SchoolOverviewGrid({this.adminSummary});
  final Map<String, int>? adminSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _OverviewItem(
          title: "Student Roster",
          value: "${adminSummary?["students"] ?? 0} total students",
          icon: Icons.groups_3_outlined,
          color: const Color(0xFF003D5B),
          onTap: () {
            ref.read(studentClassFilterProvider.notifier).state = null;
            context.push("/students");
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BreakdownCard(
                label: "BOYS",
                value: "${adminSummary?["boys"] ?? 0}",
                icon: Icons.male,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BreakdownCard(
                label: "GIRLS",
                value: "${adminSummary?["girls"] ?? 0}",
                icon: Icons.female,
                color: Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BreakdownCard(
                label: "JUNIOR",
                value: "${adminSummary?["juniors"] ?? 0}",
                icon: Icons.child_care,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BreakdownCard(
                label: "SENIOR",
                value: "${adminSummary?["seniors"] ?? 0}",
                icon: Icons.school,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _OverviewItem(
          title: "Class Sections",
          value: "${adminSummary?["classes"] ?? 0} active grades",
          icon: Icons.class_outlined,
          color: const Color(0xFFD4AF37),
          onTap: () {
            ref.read(studentClassFilterProvider.notifier).state = null;
            context.push("/students");
          },
        ),
        const SizedBox(height: 12),
        _OverviewItem(
          title: "Academic Staff",
          value: "${adminSummary?["staff"] ?? 0} members",
          icon: Icons.badge_outlined,
          color: const Color(0xFF00A86B),
          onTap: () {
            ref.read(studentClassFilterProvider.notifier).state = null;
            context.push("/students");
          },
        ),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value, 
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
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
  Map? adminSummary,
  WidgetRef ref,
) {
  return switch (profile.role) {
    UserRole.parent => [
        ("Students", "${students.length}", "Linked children", Icons.family_restroom, const Color(0xFF003D5B)),
        ("Fees", "${fees.length}", "Pending items", Icons.receipt_long, const Color(0xFFD4AF37)),
        ("Notices", "${notices.length}", "School alerts", Icons.campaign, const Color(0xFF00A86B)),
      ],
    UserRole.teacher => [
        ("Classes", "${ref.watch(teacherClassesProvider).valueOrNull?.length ?? 0}", "Assigned focus", Icons.class_outlined, const Color(0xFF003D5B)),
        ("Logs", "OPEN", "/diary", Icons.auto_stories_outlined, const Color(0xFF00A86B)),
        ("Attendance", "${attendance.length}", "Daily records", Icons.fact_check, const Color(0xFFD4AF37)),
      ],
    UserRole.admin || UserRole.cashCollector => [
        ("Students", "${adminSummary?["students"] ?? 0}", "Active records", Icons.groups, const Color(0xFF003D5B)),
        ("Classes", "${adminSummary?["classes"] ?? 0}", "Active sections", Icons.class_outlined, const Color(0xFF00A86B)),
        ("Staff", "${adminSummary?["staff"] ?? 0}", "Teaching team", Icons.badge_outlined, const Color(0xFFD4AF37)),
      ],
    _ => [
        ("Students", "${adminSummary?["students"] ?? 0}", "Active records", Icons.groups, const Color(0xFF003D5B)),
        ("Classes", "${adminSummary?["classes"] ?? 0}", "Active sections", Icons.class_outlined, const Color(0xFF00A86B)),
        ("Pending", "${adminSummary?["pendingFees"] ?? 0}", "Verification", Icons.hourglass_top, const Color(0xFFD4AF37)),
      ],
  };
}

List<(String, String, String, IconData)> _cardsForRole(UserRole role) {
  switch (role) {
    case UserRole.parent:
      return [
        ("Daily Diary", "Lesson logs", "/diary", Icons.auto_stories_outlined),
        ("Attendance", "View records", "/attendance", Icons.fact_check_outlined),
        ("Notices", "School feed", "/notices", Icons.campaign_outlined),
        ("Fees", "Pay invoices", "/fees", Icons.receipt_long_outlined),
      ];
    case UserRole.teacher:
      return [
        ("Attendance", "Mark daily", "/attendance", Icons.fact_check_outlined),
        ("Daily Diary", "Log lesson", "/diary", Icons.edit_note_outlined),
        ("Students", "Class roster", "/students", Icons.groups_2_outlined),
      ];
    case UserRole.admin:
    case UserRole.cashCollector:
      return [
        ("Operations", "Verify queue", "/admin-tools", Icons.admin_panel_settings_outlined),
        ("Daily Diary", "View reports", "/diary", Icons.auto_stories_outlined),
        ("Financials", "Fee records", "/fees", Icons.payments_outlined),
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
    UserRole.parent => const Color(0xFF1E293B),
    UserRole.teacher => const Color(0xFF10B981),
    UserRole.admin || UserRole.cashCollector => const Color(0xFF3B82F6),
    UserRole.unknown => const Color(0xFF1E293B),
  };
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.cls, required this.profile});
  final SchoolClass cls;
  final AppUser profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClassTeacher = cls.classTeacherId == profile.uid;
    final taughtSubjects = cls.subjects.entries
        .where((e) => e.value == profile.uid)
        .map((e) => e.key)
        .join(", ");

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isClassTeacher ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isClassTeacher ? Icons.workspace_premium_outlined : Icons.book_outlined,
            color: isClassTeacher ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        title: Text(
          cls.displayName, 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          isClassTeacher ? "Class Teacher" : "Subject Teacher: $taughtSubjects",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isClassTeacher ? const Color(0xFF10B981) : const Color(0xFF64748B),
                fontWeight: isClassTeacher ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
        onTap: () {
          ref.read(studentClassFilterProvider.notifier).state = cls.id;
          ref.read(diaryClassFilterProvider.notifier).state = cls.id;
          context.push("/students");
        },
      ),
    );
  }
}

class _SmartBanner extends ConsumerWidget {
  const _SmartBanner({
    required this.profile,
    required this.stats,
    required this.notices,
  });

  final AppUser profile;
  final List<(String, String, String, IconData, Color)> stats;
  final List notices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = stats.first.$5;
    final latestNotice = notices.isEmpty ? null : notices.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            accent.withOpacity(0.8),
          ],
        ),
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
                  color: Colors.white.withOpacity(0.7),
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
            children: stats.map((s) {
              final label = s.$1;
              return Expanded(
                child: _StatusItem(
                  label: label,
                  value: s.$2,
                  icon: s.$4,
                  onTap: () {
                    if (label == "Students" || label == "Classes" || label == "Staff") {
                      ref.read(studentClassFilterProvider.notifier).state = null;
                      context.push("/students");
                    } else if (s.$3.startsWith("/")) {
                      context.push(s.$3);
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const Divider(height: 48, color: Colors.white24),
          InkWell(
            onTap: () => context.push("/notices"),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value, required this.icon, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 14),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 16),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF1E293B).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_center_outlined, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Academic Support",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Facing issues with records or technical features? Our school office is here to help.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connecting to school office: 011-23456789")),
                    );
                  },
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text("Call Office"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Opening school mail: help@novarise.com")),
                    );
                  },
                  icon: const Icon(Icons.mail_outline, size: 16),
                  label: const Text("Email Us"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


