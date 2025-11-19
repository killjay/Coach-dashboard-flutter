# Firebase Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Configure Firebase

```bash
flutterfire configure
```

This command will:
- Detect your Flutter project
- Let you select your Firebase project (or create a new one)
- Configure Firebase for iOS, Android, and Web
- Generate `firebase_options.dart` automatically

### Step 3: Uncomment Firebase Initialization

Open `lib/main.dart` and uncomment the Firebase initialization:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uncomment these lines:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: CoachClientApp()));
}
```

### Step 4: Install Dependencies

```bash
flutter pub get
```

### Step 5: Enable Firebase Services

1. **Authentication**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to **Authentication** → **Get started**
   - Enable **Email/Password** sign-in method

2. **Firestore Database**
   - Go to **Firestore Database** → **Create database**
   - Start in **Test mode** (for development)
   - Select location closest to your users

3. **Storage** (Optional for now)
   - Go to **Storage** → **Get started**
   - Start in **Test mode**

### Step 6: Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 7: Test It!

Run your app:

```bash
flutter run
```

## ✅ What's Already Set Up

- ✅ Firebase packages in `pubspec.yaml`
- ✅ Firebase service implementations
- ✅ Repository abstraction layer
- ✅ Provider setup for dependency injection
- ✅ Main.dart ready for Firebase initialization

## 📝 Next Steps

1. **Set up Firestore Security Rules** (see `FIREBASE_SETUP.md`)
2. **Implement authentication screens** (login/register)
3. **Test Firebase connection** with a simple read/write
4. **Build your first feature** using the repository providers

## 🔧 Troubleshooting

### Issue: `flutterfire configure` not found
```bash
# Make sure FlutterFire CLI is installed
dart pub global activate flutterfire_cli

# Add to PATH if needed
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Issue: Firebase not initializing
- Check if `firebase_options.dart` exists
- Verify you uncommented the initialization code
- Check Firebase Console that project is created

### Issue: Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📚 Full Documentation

For detailed setup instructions, see:
- **FIREBASE_SETUP.md** - Complete Firebase setup guide
- **BACKEND_STRATEGY.md** - Backend architecture decisions

## 🎯 You're Ready!

Once Firebase is configured, you can start using:

```dart
// In your widgets
final authRepo = ref.read(authRepositoryProvider);
final workoutRepo = ref.read(workoutRepositoryProvider);
final progressRepo = ref.read(progressRepositoryProvider);
```

All repositories are already implemented and ready to use! 🚀


