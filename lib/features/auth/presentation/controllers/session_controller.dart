import "package:flutter/foundation.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "package:nova_rise_app/core/services/auth_service.dart";
import "package:nova_rise_app/core/services/notification_service.dart";

// Core Providers moved to lib/core/providers/school_providers.dart


class LoginState {
  const LoginState({
    this.isSubmitting = false,
    this.error,
  });

  final bool isSubmitting;
  final String? error;

  LoginState copyWith({
    bool? isSubmitting,
    String? error,
  }) {
    return LoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authServiceProvider), ref);
});

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authService, this.ref) : super(const LoginState());

  final AuthService _authService;
  final Ref ref;

  Future<void> signIn(String identifier, String password) async {
    if (identifier.isEmpty || password.isEmpty) {
      state = state.copyWith(error: "Please enter both ID and Password.");
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      String identifierClean = identifier.trim();
      List<String> attempts = [];
      
      // 1. If it's a 10-digit phone number, treat as Teacher ID
      final phoneRegex = RegExp(r"^[0-9]{10}$");
      if (phoneRegex.hasMatch(identifierClean)) {
        // Seeder created teachers with .boys, .girls, and .overall
        // Try overall first, then others
        attempts.add("${identifierClean}.overall@novarise.com");
        attempts.add("${identifierClean}.boys@novarise.com");
        attempts.add("${identifierClean}.girls@novarise.com");
      } 
      // 2. Registration ID Mapping (NRA or NRAJ)
      else if (!identifierClean.contains("@")) {
        // Try the actual identifier provided first
        final id = identifierClean.toLowerCase().replaceAll(' ', '');
        attempts.add("${id}.boys@novarise.com");
        attempts.add("${id}.girls@novarise.com");
        attempts.add("${id}@novarise.com");

        // Then try with dashes if missing
        if (id.startsWith("nra") && !id.contains("-") && id.length > 3) {
           final withDash = id.replaceFirst("nra", "nra-");
           attempts.add("${withDash}.boys@novarise.com");
           attempts.add("${withDash}.girls@novarise.com");
           attempts.add("${withDash}@novarise.com");
        }

        // Only as a fallback, try enforcing NRAJ if user just said NRA
        if (id.startsWith("nra") && !id.startsWith("nraj")) {
           final nraj = id.replaceFirst("nra", "nraj");
           attempts.add("${nraj}.boys@novarise.com");
           attempts.add("${nraj}.girls@novarise.com");
           attempts.add("${nraj}@novarise.com");
           
           // And with dash for nraj
           if (!nraj.contains("-") && nraj.length > 4) {
              final nrajDash = nraj.replaceFirst("nraj", "nraj-");
              attempts.add("${nrajDash}.boys@novarise.com");
              attempts.add("${nrajDash}.girls@novarise.com");
              attempts.add("${nrajDash}@novarise.com");
           }
        }
      } 
else {
        // 3. Regular email
        attempts.add(identifierClean.toLowerCase());
      }
      
      String? lastError;
      bool success = false;
      
      for (final email in attempts) {
        try {
          debugPrint("LOGIN_CONTROLLER: Attempting sign in with: $email");
          await _authService.signInWithEmail(email: email, password: password);
          success = true;
          break;
        } catch (e) {
          lastError = _formatError(e);
          // If the error is 'wrong password', we should probably stop (unless it was the wrong suffix)
          if (e is FirebaseAuthException && e.code == 'wrong-password') {
             break; 
          }
          continue;
        }
      }
      
      if (!success) {
        state = state.copyWith(isSubmitting: false, error: lastError ?? "Invalid credentials.");
        return;
      }
      
      final fcmToken = await ref.read(notificationServiceProvider).getToken();
      // We don't await this to avoid blocking login if the cloud function fails or times out
      _authService.ensureUserProfile(fcmToken: fcmToken);
      state = const LoginState();
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: _formatError(error));
    }
  }

  Future<void> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _authService.createUser(
        email: email,
        password: password,
        displayName: name,
        role: UserRole.admin,
        phone: phone,
      );
      state = const LoginState();
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: _formatError(error));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _authService.updatePassword(newPassword);
      state = const LoginState();
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: _formatError(error));
    }
  }

  String _formatError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case "user-not-found":
          return "No account found with this ID.";
        case "wrong-password":
          return "Invalid password. Please try again.";
        case "invalid-email":
          return "Invalid ID format.";
        default:
          return error.message ?? error.code;
      }
    }
    return error.toString();
  }
}

// Demo session logic removed
