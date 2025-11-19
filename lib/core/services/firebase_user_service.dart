import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Service for managing user data in Firestore
class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save user to Firestore
  Future<void> saveUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'avatarUrl': user.avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': user.preferences ?? {},
      });
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  /// Get user from Firestore
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return User.fromJson({
        'id': doc.id,
        ...data,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
      });
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get user by ID (alias for getUser)
  Future<User?> getUserById(String userId) async {
    return getUser(userId);
  }

  /// Update user in Firestore
  Future<void> updateUser(User user) async {
    try {
      final userData = user.toJson();
      userData.remove('id');
      userData.remove('createdAt');

      await _firestore.collection('users').doc(user.id).update(userData);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}


