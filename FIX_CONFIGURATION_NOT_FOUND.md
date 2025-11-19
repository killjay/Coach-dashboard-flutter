# Fix: CONFIGURATION_NOT_FOUND Error

## Problem

You're getting a `CONFIGURATION_NOT_FOUND` error when trying to register. This means Firebase Authentication is not properly configured for your web app.

## Solution Steps

### Step 1: Verify Web App is Registered in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **coach-dashboard-7b966**
3. Click the **⚙️ Settings** (gear icon) → **Project settings**
4. Scroll down to **"Your apps"** section
5. Look for a **Web app** with App ID: `1:894884637300:web:37bacab00963bb87dabf21`

**If the web app is NOT there:**

- Click **"Add app"** → Select **Web** (</> icon)
- Register the app with a nickname (e.g., "Coach Dashboard Web")
- Copy the configuration (you don't need to add it manually, FlutterFire handles it)
- Click **"Register app"**

### Step 2: Enable Authentication for Web

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"** (if you haven't already)
3. Go to **Sign-in method** tab
4. Find **Email/Password** in the list
5. Click on it
6. **Enable** it
7. Click **Save**

### Step 3: Check API Key Restrictions

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **coach-dashboard-7b966**
3. Go to **APIs & Services** → **Credentials**
4. Find the API key: `AIzaSyC7XKve0FGTcMNvHEywyXsNTrisTgQKsTM`
5. Click on it to edit
6. Under **"API restrictions"**, make sure:
   - Either **"Don't restrict key"** is selected, OR
   - **"Restrict key"** includes:
     - Identity Toolkit API
     - Firebase Authentication API
7. Under **"Application restrictions"**:
   - For development: Select **"None"** or add your domain
   - For production: Add your web domain
8. Click **Save**

### Step 4: Verify Firebase Services are Enabled

1. In Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for and ensure these APIs are **ENABLED**:
   - ✅ **Identity Toolkit API**
   - ✅ **Firebase Authentication API**
   - ✅ **Cloud Firestore API** (if using Firestore)
   - ✅ **Cloud Storage API** (if using Storage)

### Step 5: Regenerate Firebase Configuration (If Needed)

If the above doesn't work, regenerate your Firebase configuration:

```bash
# Reconfigure Firebase
flutterfire configure
```

When prompted:

- Select your project: **coach-dashboard-7b966**
- Select platforms: **Web** (and others you need)
- This will regenerate `firebase_options.dart`

### Step 6: Clear Browser Cache and Try Again

1. Clear your browser cache
2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Try registering again

## Quick Checklist

Before trying to register again, verify:

- [ ] Web app is registered in Firebase Console
- [ ] Email/Password authentication is enabled
- [ ] API key has no restrictions (or correct restrictions)
- [ ] Identity Toolkit API is enabled
- [ ] Firebase Authentication API is enabled
- [ ] Browser cache is cleared

## Still Not Working?

### Check Browser Console for More Details

1. Open Developer Tools (F12)
2. Go to **Console** tab
3. Look for more detailed error messages
4. Check **Network** tab for the failed request
5. Look at the response body for specific error details

### Verify Firebase Project

Make sure you're using the correct Firebase project:

- Project ID: `coach-dashboard-7b966`
- Check that this matches in Firebase Console

### Alternative: Re-register Web App

If nothing works, you can re-register the web app:

1. In Firebase Console → Project Settings
2. Scroll to "Your apps"
3. Delete the existing web app (if any)
4. Click "Add app" → Web
5. Register with a new name
6. Run `flutterfire configure` again
7. Select the new web app configuration

---

**Most Common Fix:** Enable Email/Password authentication in Firebase Console → Authentication → Sign-in method
