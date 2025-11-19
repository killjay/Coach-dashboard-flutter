import '../models/notification.dart';

/// Abstract repository interface for notifications
abstract class NotificationRepository {
  /// Create a notification
  Future<AppNotification> createNotification(AppNotification notification);

  /// Get notifications for a user
  Future<List<AppNotification>> getNotifications(String userId);

  /// Get unread notification count
  Future<int> getUnreadCount(String userId);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Watch notifications in real-time
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Send push notification (platform-specific)
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
}

