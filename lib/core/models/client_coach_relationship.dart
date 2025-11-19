import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_coach_relationship.freezed.dart';
part 'client_coach_relationship.g.dart';

/// Client-Coach relationship model
@freezed
class ClientCoachRelationship with _$ClientCoachRelationship {
  const factory ClientCoachRelationship({
    required String id,
    required String coachId,
    required String clientId,
    required DateTime joinedAt,
    String? status, // 'active', 'inactive', 'pending'
    Map<String, dynamic>? notes,
  }) = _ClientCoachRelationship;

  factory ClientCoachRelationship.fromJson(Map<String, dynamic> json) =>
      _$ClientCoachRelationshipFromJson(json);
}

