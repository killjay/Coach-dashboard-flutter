import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Notification type enum
@JsonEnum()
enum NotificationType {
  @JsonValue('workout_assigned')
  workoutAssigned,
  @JsonValue('workout_reminder')
  workoutReminder,
  @JsonValue('meal_plan_assigned')
  mealPlanAssigned,
  @JsonValue('message')
  message,
  @JsonValue('water_reminder')
  waterReminder,
  @JsonValue('progress_update')
  progressUpdate,
  @JsonValue('invoice')
  invoice,
  @JsonValue('system')
  system,
}

/// Notification model
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime createdAt,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl, // Deep link or route
    Map<String, dynamic>? data, // Additional data
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

