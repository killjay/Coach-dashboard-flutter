import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Service for managing user data in Firestore
class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save user to Firestore
  Future<void> saveUser(User user) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'avatarUrl': user.avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': user.preferences ?? {},
      };
      
      debugPrint('📝 Saving user to Firestore: ${user.id}');
      debugPrint('📝 User data: $userData');
      debugPrint('📝 Firestore instance: ${_firestore.app.name}');
      
      // Add timeout to prevent hanging
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(userData, SetOptions(merge: false))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore operation timed out after 10 seconds');
            },
          );
      
      debugPrint('✅ User saved successfully to Firestore');
      
      // Verify the document was created
      final doc = await _firestore.collection('users').doc(user.id).get();
      if (!doc.exists) {
        throw Exception('Document was not created in Firestore');
      }
      debugPrint('✅ Verified: Document exists in Firestore');
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException saving user: ${e.code} - ${e.message}');
      debugPrint('❌ Plugin: ${e.plugin}');
      throw Exception('Firestore error (${e.code}): ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving user to Firestore: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to save user: $e');
    }
  }

  /// Get user from Firestore
  Future<User?> getUser(String userId) async {
    try {
      debugPrint('📝 Fetching user from Firestore: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        debugPrint('⚠️ User document does not exist: $userId');
        return null;
      }

      final data = doc.data()!;
      debugPrint('📝 User data from Firestore: $data');
      
      // Convert Timestamp to ISO string for JSON parsing
      final createdAtTimestamp = data['createdAt'] as Timestamp?;
      final createdAtString = createdAtTimestamp?.toDate().toIso8601String();
      
      // Handle role being in preferences (legacy data)
      final userJson = <String, dynamic>{
        'id': doc.id,
        ...data,
        'createdAt': createdAtString, // Convert to ISO string for fromJson
      };
      
      // If role is in preferences, move it to top level
      if (userJson['role'] == null && data['preferences'] != null) {
        final preferences = data['preferences'] as Map<String, dynamic>?;
        if (preferences != null && preferences.containsKey('role')) {
          debugPrint('⚠️ Role found in preferences, moving to top level');
          userJson['role'] = preferences['role'];
          // Remove role from preferences
          final updatedPreferences = Map<String, dynamic>.from(preferences);
          updatedPreferences.remove('role');
          userJson['preferences'] = updatedPreferences;
        }
      }
      
      debugPrint('📝 Final user JSON: $userJson');
      final user = User.fromJson(userJson);
      debugPrint('✅ User parsed: ${user.name} (${user.email}), role: ${user.role}');
      return user;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting user: $e');
      debugPrint('❌ Stack trace: $stackTrace');
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

      // Ensure role is at top level, not in preferences
      if (userData.containsKey('preferences') && userData['preferences'] is Map) {
        final preferences = Map<String, dynamic>.from(userData['preferences'] as Map);
        // Remove role from preferences if it exists there
        preferences.remove('role');
        userData['preferences'] = preferences;
      }
      
      // Ensure role is at top level
      if (user.role.isNotEmpty) {
        userData['role'] = user.role;
      }

      debugPrint('📝 Updating user in Firestore: ${user.id}');
      debugPrint('📝 Update data: $userData');
      
      await _firestore.collection('users').doc(user.id).update(userData);
      
      debugPrint('✅ User updated successfully in Firestore');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating user in Firestore: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to update user: $e');
    }
  }
}


