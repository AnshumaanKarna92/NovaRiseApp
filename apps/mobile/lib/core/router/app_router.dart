import 'package:go_router/go_router.dart';

import '../../features/admin_tools/presentation/screens/admin_tools_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/auth/presentation/screens/auth_gate_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/fees/presentation/screens/fees_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/notices/presentation/screens/notices_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/students/presentation/screens/students_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGateScreen()),
    GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/fees', builder: (context, state) => const FeesScreen()),
    GoRoute(path: '/attendance', builder: (context, state) => const AttendanceScreen()),
    GoRoute(path: '/notices', builder: (context, state) => const NoticesScreen()),
    GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),
    GoRoute(path: '/students', builder: (context, state) => const StudentsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/admin-tools', builder: (context, state) => const AdminToolsScreen()),
  ],
);
