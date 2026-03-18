import 'app_user.dart';

class SessionState {
  const SessionState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;
}
