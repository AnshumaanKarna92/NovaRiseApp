import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/models/app_user.dart";
import "../../../../core/services/auth_service.dart";
import "../../../../core/services/notification_service.dart";

// Demo logic removed for final version

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firebaseMessagingProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  // Side effect: initialize notifications when auth state changes (or on app start)
  ref.read(notificationServiceProvider).initialize();
  
  return authService.authStateChanges();
});

final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<AppUser?>.value(null);
  }

  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore.collection("users").doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null; // Force bootstrap flow if profile missing
    }
    return AppUser.fromMap(snapshot.id, snapshot.data()!);
  });
});


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
      final email = identifier.contains("@") ? identifier : "$identifier@novarise.com";
      await _authService.signInWithEmail(email: email, password: password);
      
      final fcmToken = await ref.read(notificationServiceProvider).getToken();
      await _authService.ensureUserProfile(fcmToken: fcmToken);
      state = const LoginState();
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: _formatError(error));
    }
  }

  Future<void> registerAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _authService.createUser(
        email: email,
        password: password,
        displayName: name,
        role: UserRole.admin,
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
