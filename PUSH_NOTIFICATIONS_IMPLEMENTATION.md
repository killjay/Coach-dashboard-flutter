# Push Notifications Implementation Guide

## Current Status

✅ **Completed:**
- FCM token retrieval from Firestore
- Notification model and repository structure
- Local notification display infrastructure
- Notification service interface

⚠️ **Pending:**
- Actual push notification sending via FCM backend
- Cloud Functions setup for notification triggers
- Notification payload handling and deep linking

## Implementation Requirements

### 1. Firebase Cloud Messaging (FCM) Setup

#### Backend Options:

**Option A: Firebase Cloud Functions (Recommended)**
- Set up Firebase Cloud Functions
- Create functions to send push notifications
- Trigger notifications based on events (new message, workout assigned, etc.)

**Option B: Custom Backend API**
- Create REST API endpoint for sending notifications
- Use Firebase Admin SDK on backend
- Handle notification triggers from your application

### 2. Cloud Functions Implementation

Create a Cloud Function to send push notifications:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { userId, title, body, data: notificationData } = data;
  
  // Get user's FCM token
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .get();
  
  const fcmToken = userDoc.data()?.fcmToken;
  
  if (!fcmToken) {
    throw new functions.https.HttpsError(
      'not-found',
      'FCM token not found for user'
    );
  }
  
  // Send notification
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: notificationData || {},
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
  
  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send notification'
    );
  }
});
```

### 3. Update Flutter Service

Update `lib/core/services/firebase_notification_service.dart`:

```dart
@override
Future<void> sendPushNotification({
  required String userId,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    // Option A: Call Cloud Function
    final callable = FirebaseFunctions.instance.httpsCallable('sendNotification');
    await callable.call({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
    });
    
    // Option B: Call your backend API
    // final response = await dio.post(
    //   'https://your-api.com/notifications/send',
    //   data: {
    //     'userId': userId,
    //     'title': title,
    //     'body': body,
    //     'data': data,
    //   },
    // );
    
  } catch (e) {
    throw Exception('Failed to send push notification: $e');
  }
}
```

### 4. FCM Token Management

Ensure FCM tokens are stored when users log in:

```dart
// In your auth service or app initialization
Future<void> _saveFCMToken(String userId) async {
  try {
    final messaging = FirebaseMessaging.instance;
    
    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token
      final token = await messaging.getToken();
      
      if (token != null) {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
      }
      
      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': newToken});
      });
    }
  } catch (e) {
    debugPrint('Error saving FCM token: $e');
  }
}
```

### 5. Notification Handlers

Set up notification handlers for foreground and background:

```dart
// In main.dart or app initialization
void _setupNotificationHandlers() {
  // Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Show local notification
    // Handle notification data
    // Navigate to relevant screen
  });
  
  // Background notifications (when app is terminated)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle notification tap
    // Navigate to relevant screen
  });
  
  // Check if app was opened from notification
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      // Handle notification tap
      // Navigate to relevant screen
    }
  });
}
```

### 6. Notification Triggers

Set up automatic notification triggers:

**For new messages:**
```dart
// In message service after sending message
await notificationService.createNotification(
  AppNotification(
    userId: recipientId,
    title: 'New Message',
    body: 'You have a new message from ${senderName}',
    type: 'message',
    data: {'messageId': messageId, 'senderId': senderId},
  ),
);
```

**For workout assignments:**
```dart
// In workout assignment service
await notificationService.createNotification(
  AppNotification(
    userId: clientId,
    title: 'New Workout Assigned',
    body: 'Your coach has assigned you a new workout',
    type: 'workout',
    data: {'workoutId': workoutId},
  ),
);
```

### 7. Deep Linking

Implement deep linking for notifications:

```dart
void _handleNotificationNavigation(Map<String, dynamic>? data) {
  if (data == null) return;
  
  final type = data['type'] as String?;
  final id = data['id'] as String?;
  
  switch (type) {
    case 'message':
      if (id != null) {
        context.push('${AppRoutes.chat}/$id');
      }
      break;
    case 'workout':
      if (id != null) {
        context.push('${AppRoutes.workoutDetail}/$id');
      }
      break;
    // Add more cases as needed
  }
}
```

## Testing

1. **Test FCM Token Storage:**
   - Verify token is saved to Firestore on login
   - Verify token is updated on refresh

2. **Test Notification Sending:**
   - Send test notification from Firebase Console
   - Verify notification is received on device

3. **Test Notification Handling:**
   - Test foreground notifications
   - Test background notifications
   - Test notification tap navigation

4. **Test Different Platforms:**
   - iOS: Requires APNs setup
   - Android: Should work out of the box
   - Web: Requires service worker setup

## Platform-Specific Setup

### iOS
1. Enable Push Notifications capability in Xcode
2. Configure APNs in Firebase Console
3. Upload APNs certificate or key to Firebase

### Android
1. Add FCM dependency (already in pubspec.yaml)
2. Configure `google-services.json` in `android/app/`
3. Set up notification channels for Android 8.0+

### Web
1. Enable Firebase Cloud Messaging for web
2. Set up service worker
3. Request notification permissions

## Security Considerations

1. **Validate notification requests:**
   - Only authenticated users can send notifications
   - Validate user permissions
   - Rate limit notification sending

2. **Protect FCM tokens:**
   - Store tokens securely
   - Implement token rotation
   - Handle token expiration

3. **Notification content:**
   - Sanitize user-generated content
   - Avoid sensitive information in notifications
   - Use data payloads for sensitive info

## Next Steps

1. ✅ Set up Firebase Cloud Functions (or backend API)
2. ✅ Implement notification sending function
3. ✅ Update Flutter service to call backend
4. ✅ Set up FCM token management
5. ✅ Implement notification handlers
6. ✅ Add deep linking support
7. ✅ Test on all platforms
8. ✅ Deploy to production

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Package](https://pub.dev/packages/firebase_messaging)
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Best Practices](https://firebase.google.com/docs/cloud-messaging/best-practices)

---

**Status**: ⚠️ Pending Implementation
**Priority**: High
**Estimated Time**: 4-8 hours


