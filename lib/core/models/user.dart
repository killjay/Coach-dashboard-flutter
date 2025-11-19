import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model representing both coaches and clients
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    required String role, // 'coach' or 'client'
    String? avatarUrl,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// User role enum
enum UserRole {
  coach,
  client,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.coach:
        return 'coach';
      case UserRole.client:
        return 'client';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'coach':
        return UserRole.coach;
      case 'client':
        return UserRole.client;
      default:
        return UserRole.client;
    }
  }
}


