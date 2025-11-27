# Firebase Setup Guide for Local Development

## Issue: CORS Error on Web Uploads

You're encountering a CORS error because:
1. Firebase configuration is not complete (using placeholder values)
2. Firebase Storage CORS rules are not configured for web

## Quick Fix Steps

### Step 1: Configure Firebase Options

You have two options:

#### Option A: Use FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI if you haven't
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will:
- Connect to your Firebase project (`coach-dashboard-7b966`)
- Generate `lib/firebase_options.dart` with correct values
- Set up all platforms (Web, Android, iOS)

#### Option B: Manual Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/project/coach-dashboard-7b966/settings/general)
2. Click on your **Web app** (or create one if needed)
3. Copy the configuration values
4. Update `lib/firebase_options.dart` with your actual values

### Step 2: Configure CORS for Firebase Storage

Firebase Storage requires CORS configuration for web uploads. Create a file called `cors.json`:

```json
[
  {
    "origin": ["http://localhost:*", "http://127.0.0.1:*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization"]
  }
]
```

Then deploy it using `gsutil`:

```bash
# Install Google Cloud SDK if you haven't
# https://cloud.google.com/sdk/docs/install

# Set your project
gcloud config set project coach-dashboard-7b966

# Apply CORS configuration
gsutil cors set cors.json gs://coach-dashboard-7b966.firebasestorage.app
```

**Alternative: Use Firebase Console**
1. Go to [Firebase Console Storage](https://console.firebase.google.com/project/coach-dashboard-7b966/storage)
2. Click on the **Rules** tab
3. Add CORS configuration (if available in UI) or use gsutil method above

### Step 3: Verify Configuration

After completing the steps above:
1. Restart your Flutter app
2. Try uploading a progress photo again
3. Check browser console for any remaining errors

## Project Information

- **Project ID**: `coach-dashboard-7b966`
- **Storage Bucket**: `coach-dashboard-7b966.firebasestorage.app`
- **Auth Domain**: `coach-dashboard-7b966.firebaseapp.com`

## Troubleshooting

### Still getting CORS errors?
1. Make sure CORS rules are applied to the correct bucket
2. Clear browser cache and restart the app
3. Check that your `firebase_options.dart` has the correct `storageBucket` value

### Can't find API keys?
1. Go to Firebase Console → Project Settings
2. Scroll to "Your apps" section
3. Click on your Web app
4. Copy the `apiKey` value


