import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

/// Firebase implementation of NotificationRepository
class FirebaseNotificationService implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<AppNotification> createNotification(AppNotification notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();

      final notificationData = notification.toJson();
      notificationData.remove('id');

      await docRef.set({
        ...notificationData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification
      await sendPushNotification(
        userId: notification.userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );

      return notification.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AppNotification.fromJson({
              'id': doc.id,
              ...data,
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'readAt': (data['readAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return AppNotification.fromJson({
                'id': doc.id,
                ...data,
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'readAt': (data['readAt'] as Timestamp?)?.toDate(),
              });
            })
            .toList());
  }

  @override
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null) {
        // User hasn't enabled push notifications
        return;
      }

      // In a real app, you'd send this via Firebase Cloud Messaging API
      // For now, we'll just log it
      // TODO: Implement actual FCM sending via backend or Cloud Functions
    } catch (e) {
      // Silently fail - push notifications are not critical
    }
  }
}

