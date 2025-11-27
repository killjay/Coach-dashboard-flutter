import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/config/app_config.dart';

/// Authentication state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Current user provider
/// Returns the authenticated user, or a default user if skipAuthentication is enabled
final currentUserProvider = Provider<User?>((ref) {
  // If authentication is skipped, return a default user
  if (AppConfig.skipAuthentication) {
    return User(
      id: 'dev-${AppConfig.defaultRole}',
      email: '${AppConfig.defaultRole}@dev.local',
      name: 'Development ${AppConfig.defaultRole.capitalize()}',
      role: AppConfig.defaultRole,
      createdAt: DateTime.now(),
    );
  }

  // Normal flow: return authenticated user
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Authentication notifier
class AuthNotifier extends Notifier<AsyncValue<void>> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

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
  /// [role] is optional and only used for new users. Existing users keep their current role.
  Future<void> signInWithGoogle({String? role}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle(role: role);
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
    NotifierProvider<AuthNotifier, AsyncValue<void>>(() {
  return AuthNotifier();
});


