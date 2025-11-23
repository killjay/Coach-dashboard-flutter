import '../models/user.dart';

/// Abstract repository interface for authentication
/// This abstraction allows switching between Firebase and Node.js backends
abstract class AuthRepository {
  /// Sign in with email and password
  Future<User> signInWithEmail(String email, String password);

  /// Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  /// Sign in with Google
  /// [role] is optional and only used for new users. Existing users keep their current role.
  Future<User> signInWithGoogle({String? role});

  /// Sign in with Apple (iOS/macOS only)
  Future<User> signInWithApple();

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  User? get currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  });

  /// Delete user account
  Future<void> deleteAccount();
}


