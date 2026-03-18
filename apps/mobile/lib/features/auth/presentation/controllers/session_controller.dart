import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/models/session_state.dart';
import '../../../../core/services/demo_session_service.dart';

final demoSessionServiceProvider = Provider((ref) => const DemoSessionService());

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref.read(demoSessionServiceProvider));
});

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._demoSessionService) : super(const SessionState());

  final DemoSessionService _demoSessionService;

  void signInAs(UserRole role) {
    final user = switch (role) {
      UserRole.parent => _demoSessionService.buildParent(),
      UserRole.teacher => _demoSessionService.buildTeacher(),
      UserRole.admin || UserRole.cashCollector => _demoSessionService.buildAdmin(),
    };

    state = SessionState(user: user);
  }

  void signOut() {
    state = const SessionState();
  }
}
