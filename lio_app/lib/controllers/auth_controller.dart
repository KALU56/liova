import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authService) : super(const AsyncData(null));

  final AuthService _authService;

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _authService.signUpWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _authService.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    try {
      await _authService.updateDisplayName(displayName);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isSignedIn => _authService.currentUser != null;
  String? get userId => _authService.userId;
  String? getUserEmail() => _authService.userEmail;
  String? getUserDisplayName() => _authService.userDisplayName;
}
