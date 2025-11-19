# Test Credentials Guide

## Creating Test Users

Since this app uses Firebase Authentication, you need to create test users. You have two options:

### Option 1: Create Users Through the App (Recommended)

1. **Run the app:**
   ```bash
   flutter run -d chrome  # For web
   # or
   flutter run  # For mobile/desktop
   ```

2. **Register test accounts:**
   - Navigate to the Register screen
   - Create accounts with the following credentials:

#### Test Coach Account
- **Email:** `coach@test.com`
- **Password:** `TestCoach123!`
- **Name:** `Test Coach`
- **Role:** `Coach`

#### Test Client Account
- **Email:** `client@test.com`
- **Password:** `TestClient123!`
- **Name:** `Test Client`
- **Role:** `Client`

### Option 2: Create Users in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Users**
4. Click **"Add user"**
5. Enter email and password
6. Click **"Add user"**

**Note:** If you create users this way, you'll also need to create their user documents in Firestore manually with the correct role.

## Suggested Test Credentials

Here are some test credentials you can use:

### Coach Account
```
Email: coach@test.com
Password: TestCoach123!
Role: coach
```

### Client Account
```
Email: client@test.com
Password: TestClient123!
Role: client
```

### Additional Test Accounts (Optional)

#### Coach 2
```
Email: coach2@test.com
Password: TestCoach123!
Role: coach
```

#### Client 2
```
Email: client2@test.com
Password: TestClient123!
Role: client
```

## Quick Test Script

You can also create test users programmatically. Add this to a test file or run it once:

```dart
// test/create_test_users.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> createTestUsers() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Create Coach
  try {
    final coachCredential = await auth.createUserWithEmailAndPassword(
      email: 'coach@test.com',
      password: 'TestCoach123!',
    );
    await coachCredential.user?.updateDisplayName('Test Coach');
    await firestore.collection('users').doc(coachCredential.user!.uid).set({
      'email': 'coach@test.com',
      'name': 'Test Coach',
      'role': 'coach',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Coach user created');
  } catch (e) {
    print('Coach user may already exist: $e');
  }

  // Create Client
  try {
    final clientCredential = await auth.createUserWithEmailAndPassword(
      email: 'client@test.com',
      password: 'TestClient123!',
    );
    await clientCredential.user?.updateDisplayName('Test Client');
    await firestore.collection('users').doc(clientCredential.user!.uid).set({
      'email': 'client@test.com',
      'name': 'Test Client',
      'role': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Client user created');
  } catch (e) {
    print('Client user may already exist: $e');
  }
}
```

## Testing Authentication Flow

1. **Register a new user:**
   - Open the app
   - Click "Register"
   - Fill in the form
   - Select role (Coach or Client)
   - Submit

2. **Login:**
   - Use the credentials you created
   - Should redirect to appropriate dashboard based on role

3. **Test Google Sign-In:**
   - Click "Sign in with Google"
   - Select Google account
   - First time will prompt for role selection

## Security Notes

⚠️ **Important:**
- These are test credentials only
- Never use these in production
- Change passwords if deploying to production
- Consider using Firebase Authentication's test users feature for automated testing

## Troubleshooting

### User exists but can't login
- Check if email is verified (if email verification is enabled)
- Verify password is correct
- Check Firebase Console → Authentication → Users

### User created but wrong role
- Check Firestore → users collection
- Verify the `role` field is set correctly
- Update manually if needed

### Can't create user
- Check Firebase Authentication is enabled
- Verify Email/Password sign-in method is enabled
- Check Firebase Console for error messages

---

**Last Updated:** $(date)

