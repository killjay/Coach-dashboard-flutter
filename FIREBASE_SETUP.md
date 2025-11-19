# Firebase Setup Guide

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Firebase CLI (optional, for advanced setup)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `coach-client-app` (or your preferred name)
4. Enable/disable Google Analytics (optional, recommended: Enable)
5. Click **"Create project"**
6. Wait for project creation to complete
7. Click **"Continue"**

## Step 2: Add Firebase to Your Flutter App

### 2.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2.2 Configure Firebase for Your Platforms

Run the following command in your project root:

```bash
flutterfire configure
```

This will:

- Detect your Flutter project
- Let you select platforms (iOS, Android, Web)
- Automatically configure Firebase for each platform
- Generate `firebase_options.dart` file

**Note:** You'll need to select your Firebase project from the list.

### 2.3 Manual Configuration (Alternative)

If `flutterfire configure` doesn't work, follow platform-specific steps below.

## Step 3: Platform-Specific Setup

### iOS Setup

1. **Download GoogleService-Info.plist**

   - In Firebase Console, go to Project Settings
   - Select iOS app (or add iOS app if not added)
   - Download `GoogleService-Info.plist`

2. **Add to Xcode**

   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into `ios/Runner/` folder
   - Make sure "Copy items if needed" is checked
   - Select "Runner" target

3. **Update Podfile** (if needed)

   ```ruby
   # ios/Podfile
   platform :ios, '12.0'
   ```

4. **Install Pods**
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Android Setup

1. **Download google-services.json**

   - In Firebase Console, go to Project Settings
   - Select Android app (or add Android app if not added)
   - Download `google-services.json`

2. **Add to Android Project**

   - Place `google-services.json` in `android/app/` directory

3. **Update build.gradle files**

   **android/build.gradle:**

   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

   **android/app/build.gradle:**

   ```gradle
   apply plugin: 'com.google.gms.google-services'

   android {
       defaultConfig {
           minSdkVersion 21
       }
   }
   ```

### Web Setup

1. **Get Web Configuration**

   - In Firebase Console, go to Project Settings
   - Scroll to "Your apps" section
   - Click on Web app (or add Web app)
   - Copy the Firebase configuration object

2. **Update web/index.html**
   - Add Firebase SDK scripts (see example below)

## Step 4: Enable Firebase Services

### 4.1 Authentication

1. Go to Firebase Console → **Authentication**
2. Click **"Get started"**
3. Enable sign-in methods:
   - **Email/Password** (Enable)
   - **Google** (Enable - for Google Sign-In)
   - **Apple** (Enable - for Apple Sign-In, iOS/macOS only)

### 4.2 Firestore Database

1. Go to Firebase Console → **Firestore Database**
2. Click **"Create database"**
3. Choose mode:
   - **Production mode** (recommended for production)
   - **Test mode** (for development - allows all reads/writes)
4. Select location (choose closest to your users)
5. Click **"Enable"**

### 4.3 Cloud Storage

1. Go to Firebase Console → **Storage**
2. Click **"Get started"**
3. Start in **production mode** (or test mode for development)
4. Select location (same as Firestore recommended)
5. Click **"Done"**

### 4.4 Cloud Messaging (FCM)

1. Go to Firebase Console → **Cloud Messaging**
2. FCM is automatically enabled
3. For iOS, you'll need to:
   - Upload APNs certificate/key to Firebase
   - Configure in Firebase Console → Project Settings → Cloud Messaging

## Step 5: Firestore Security Rules

### Development Rules (Test Mode)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2024, 12, 31);
    }
  }
}
```

### Production Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user is coach
    function isCoach() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }

    // Helper function to check if user is client
    function isClient() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'client';
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAuthenticated() && request.auth.uid == userId;
    }

    // Workouts collection
    match /workouts/{workoutId} {
      allow read: if isAuthenticated();
      allow create: if isCoach();
      allow update: if isCoach() && resource.data.coachId == request.auth.uid;
      allow delete: if isCoach() && resource.data.coachId == request.auth.uid;
    }

    // Workout assignments
    match /workoutAssignments/{assignmentId} {
      allow read: if isAuthenticated() &&
                     (resource.data.clientId == request.auth.uid ||
                      resource.data.coachId == request.auth.uid);
      allow create: if isCoach();
      allow update: if isAuthenticated() &&
                       (resource.data.clientId == request.auth.uid ||
                        resource.data.coachId == request.auth.uid);
    }

    // Meal plans
    match /mealPlans/{mealPlanId} {
      allow read: if isAuthenticated();
      allow create: if isCoach();
      allow update: if isCoach() && resource.data.coachId == request.auth.uid;
      allow delete: if isCoach() && resource.data.coachId == request.auth.uid;
    }

    // Progress tracking (water, steps, weight, etc.)
    match /waterLogs/{logId} {
      allow read: if isAuthenticated() &&
                     (resource.data.clientId == request.auth.uid ||
                      get(/databases/$(database)/documents/users/$(resource.data.clientId)).data.coachId == request.auth.uid);
      allow create: if isClient() && request.resource.data.clientId == request.auth.uid;
      allow update, delete: if isClient() && resource.data.clientId == request.auth.uid;
    }

    match /stepLogs/{logId} {
      allow read: if isAuthenticated() &&
                     (resource.data.clientId == request.auth.uid ||
                      get(/databases/$(database)/documents/users/$(resource.data.clientId)).data.coachId == request.auth.uid);
      allow create: if isClient() && request.resource.data.clientId == request.auth.uid;
      allow update, delete: if isClient() && resource.data.clientId == request.auth.uid;
    }

    match /weightLogs/{logId} {
      allow read: if isAuthenticated() &&
                     (resource.data.clientId == request.auth.uid ||
                      get(/databases/$(database)/documents/users/$(resource.data.clientId)).data.coachId == request.auth.uid);
      allow create: if isClient() && request.resource.data.clientId == request.auth.uid;
      allow update, delete: if isClient() && resource.data.clientId == request.auth.uid;
    }

    // Progress photos
    match /progressPhotos/{photoId} {
      allow read: if isAuthenticated() &&
                     (resource.data.clientId == request.auth.uid ||
                      get(/databases/$(database)/documents/users/$(resource.data.clientId)).data.coachId == request.auth.uid);
      allow create: if isClient() && request.resource.data.clientId == request.auth.uid;
      allow delete: if isClient() && resource.data.clientId == request.auth.uid;
    }
  }
}
```

## Step 6: Cloud Storage Security Rules

### Development Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2024, 12, 31);
    }
  }
}
```

### Production Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User avatars
    match /avatars/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Progress photos
    match /progressPhotos/{userId}/{photoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Exercise media
    match /exercises/{exerciseId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    // Meal plan images
    match /meals/{mealId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 7: Initialize Firebase in Flutter

### Update main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated by flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: CoachClientApp(),
    ),
  );
}
```

## Step 8: Install Dependencies

Make sure these are in your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.9
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^5.0.0
```

Then run:

```bash
flutter pub get
```

## Step 9: Test Firebase Connection

Create a test file to verify Firebase is working:

```dart
// test/firebase_test.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirebase() async {
  await Firebase.initializeApp();

  // Test Firestore
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('test').add({'message': 'Hello Firebase!'});
  print('Firebase connected successfully!');
}
```

## Step 10: Firestore Data Structure

Here's the recommended Firestore structure:

```
firestore/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── name: string
│       ├── role: string (coach/client)
│       ├── avatarUrl: string?
│       ├── createdAt: timestamp
│       └── preferences: map
│
├── workouts/
│   └── {workoutId}/
│       ├── coachId: string
│       ├── name: string
│       ├── description: string?
│       ├── exercises: array
│       ├── duration: number
│       ├── difficulty: string
│       └── createdAt: timestamp
│
├── workoutAssignments/
│   └── {assignmentId}/
│       ├── workoutId: string
│       ├── clientId: string
│       ├── coachId: string
│       ├── assignedDate: timestamp
│       ├── dueDate: timestamp
│       ├── status: string
│       └── completedAt: timestamp?
│
├── mealPlans/
│   └── {mealPlanId}/
│       ├── coachId: string
│       ├── name: string
│       ├── description: string?
│       ├── meals: array
│       ├── duration: number
│       ├── totalCalories: number
│       └── macros: map
│
├── waterLogs/
│   └── {logId}/
│       ├── clientId: string
│       ├── amount: number
│       ├── loggedAt: timestamp
│       └── date: timestamp
│
├── stepLogs/
│   └── {logId}/
│       ├── clientId: string
│       ├── steps: number
│       ├── date: timestamp
│       └── source: string
│
└── weightLogs/
    └── {logId}/
        ├── clientId: string
        ├── weight: number
        └── loggedAt: timestamp
```

## Troubleshooting

### Issue: Firebase not initializing

- Check if `firebase_options.dart` exists
- Verify platform-specific configuration files are in place
- Check Firebase project settings

### Issue: Authentication not working

- Verify Authentication is enabled in Firebase Console
- Check sign-in methods are enabled
- Verify SHA-1 fingerprint for Android (if using Google Sign-In)

### Issue: Firestore permission denied

- Check Firestore security rules
- Verify user is authenticated
- Check user role/permissions

### Issue: Storage upload fails

- Check Storage security rules
- Verify file size limits
- Check network connectivity

## Next Steps

1. ✅ Complete Firebase setup
2. ✅ Implement Firebase repositories (see implementation files)
3. ✅ Test authentication flow
4. ✅ Test Firestore read/write operations
5. ✅ Test file uploads to Storage
6. ✅ Set up push notifications

## Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Firebase Storage](https://firebase.google.com/docs/storage)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

---

**Note:** Keep your Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`) secure and never commit them to public repositories if they contain sensitive data. They're already in `.gitignore`.

