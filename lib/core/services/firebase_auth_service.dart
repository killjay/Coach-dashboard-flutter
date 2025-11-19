import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'firebase_user_service.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthService implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  // Lazy initialization to avoid errors if Google Sign-In is not configured
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }
  final FirebaseUserService _userService = FirebaseUserService();

  @override
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed: User is null');
      }

      return await _getUserFromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Create user document in Firestore
      final user = User(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      // Save user to Firestore
      await _userService.saveUser(user);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google sign in failed: User is null');
      }

      final firebaseUser = userCredential.user!;
      
      // Check if user exists in Firestore, if not create it
      var user = await _userService.getUser(firebaseUser.uid);
      if (user == null) {
        // New user, create in Firestore
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? googleUser.displayName ?? '',
          role: 'client', // Default role for Google sign-in
          avatarUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          createdAt: DateTime.now(),
        );
        await _userService.saveUser(user);
      }

      return user;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  @override
  Future<User> signInWithApple() async {
    try {
      // Request credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential
      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw Exception('Apple sign in failed: User is null');
      }

      return await _getUserFromFirebaseUser(userCredential.user!);
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        if (_googleSignIn != null) googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  @override
  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Convert Firebase user to app User model
    // Note: This is a simplified version. In production, you'd fetch from Firestore
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      role: 'client', // Default, should be fetched from Firestore
      avatarUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  @override
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirebaseUser(firebaseUser);
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (name != null) {
        await user.updateDisplayName(name);
      }

      if (avatarUrl != null) {
        await user.updatePhotoURL(avatarUrl);
      }

      await user.reload();
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Helper methods

  Future<User> _getUserFromFirebaseUser(
    firebase_auth.User firebaseUser,
  ) async {
    // Try to fetch user from Firestore first
    final user = await _userService.getUser(firebaseUser.uid);
    if (user != null) {
      return user;
    }

    // If user doesn't exist in Firestore, create basic user
    // This can happen for existing Firebase Auth users
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      role: 'client', // Default role
      avatarUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak. Please use at least 6 characters.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email. Please sign in instead.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is invalid. Please check your email format.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return Exception('Email/Password authentication is not enabled. Please enable it in Firebase Console.');
      case 'invalid-credential':
        return Exception('Invalid credentials provided.');
      case 'network-request-failed':
        return Exception('Network error. Please check your internet connection.');
      default:
        return Exception('Authentication failed: ${e.message ?? e.code}');
    }
  }
}

