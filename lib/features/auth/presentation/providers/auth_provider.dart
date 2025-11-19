import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/auth_repository.dart';

/// Authentication state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Authentication notifier
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmail(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithApple();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});


