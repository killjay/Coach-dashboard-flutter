# Google Sign-In Setup for Web

## Problem
You're getting an error: `"ClientID not set. Either set it on a <meta name=\"google-signin-client_id\" content=\"CLIENT_ID\" /> tag, or pass clientId when initializing GoogleSignIn"`

This happens because Google Sign-In requires an OAuth 2.0 Client ID for web platforms.

## Solution: Get OAuth Client ID from Firebase

### Step 1: Get Your OAuth Client ID

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **coach-dashboard-7b966**
3. Click **⚙️ Settings** (gear icon) → **Project settings**
4. Scroll down to **"Your apps"** section
5. Click on your **Web app** (the one with App ID: `1:894884637300:web:37bacab00963bb87dabf21`)
6. Scroll down to find **"OAuth 2.0 Client IDs"** section
7. You'll see a Client ID that looks like: `894884637300-xxxxxxxxxxxxx.apps.googleusercontent.com`
8. **Copy this Client ID**

### Step 2: Add Client ID to web/index.html

1. Open `web/index.html`
2. Find the commented line:
   ```html
   <!-- <meta name="google-signin-client_id" content="YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com" /> -->
   ```
3. Uncomment it and replace `YOUR_OAUTH_CLIENT_ID` with your actual Client ID:
   ```html
   <meta name="google-signin-client_id" content="894884637300-xxxxxxxxxxxxx.apps.googleusercontent.com" />
   ```
4. Save the file

### Step 3: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Find **Google** in the list
4. Click on it
5. **Enable** it
6. Enter your **Support email** (your email address)
7. Click **Save**

### Step 4: Configure OAuth Consent Screen (If Needed)

If you haven't set up OAuth consent screen:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **coach-dashboard-7b966**
3. Go to **APIs & Services** → **OAuth consent screen**
4. Choose **External** (for testing) or **Internal** (for Google Workspace)
5. Fill in required fields:
   - App name: `Coach Dashboard`
   - User support email: Your email
   - Developer contact: Your email
6. Click **Save and Continue**
7. Add scopes (if needed):
   - `email`
   - `profile`
   - `openid`
8. Click **Save and Continue**
9. Add test users (if using External):
   - Add your email address
10. Click **Save and Continue**
11. Review and go back to Dashboard

### Step 5: Restart Your App

1. Stop your Flutter app
2. Clear browser cache
3. Run again:
   ```bash
   flutter run -d chrome
   ```

## Alternative: Disable Google Sign-In (If Not Needed)

If you don't want to use Google Sign-In right now, you can make it optional:

The code has been updated to handle missing Google Sign-In configuration gracefully. However, you'll still need to configure it if you want to use the "Sign in with Google" button.

## Verify It's Working

1. Run your app
2. Go to the Login screen
3. Click "Continue with Google"
4. You should see the Google sign-in popup
5. Select your Google account
6. You should be signed in successfully

## Troubleshooting

### Still Getting Client ID Error?

1. **Verify the meta tag is correct:**
   - Check `web/index.html` has the meta tag
   - Make sure it's not commented out
   - Verify the Client ID is correct

2. **Check OAuth Client ID exists:**
   - Go to Firebase Console → Project Settings → Your apps → Web app
   - Verify OAuth 2.0 Client IDs section shows your Client ID

3. **Clear browser cache:**
   - Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

4. **Check Google Sign-In is enabled:**
   - Firebase Console → Authentication → Sign-in method
   - Verify Google is enabled

### OAuth Consent Screen Issues

If you see "Error 403: access_denied":
- Make sure OAuth consent screen is configured
- Add your email as a test user (if using External)
- Wait a few minutes for changes to propagate

---

**Note:** The app will now work even if Google Sign-In is not configured. The Google Sign-In button will only work after you complete the setup above.

