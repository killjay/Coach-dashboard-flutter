# How to Find Your OAuth Client ID

## What You Provided
You provided: `1:894884637300:web:37bacab00963bb87dabf21`

This is your **Firebase App ID**, not the OAuth Client ID. We need the **OAuth 2.0 Client ID** which looks different.

## Step-by-Step: Find OAuth Client ID

### Method 1: From Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **coach-dashboard-7b966**
3. Click **⚙️ Settings** (gear icon) → **Project settings**
4. Scroll down to **"Your apps"** section
5. Click on your **Web app** (the one with App ID: `1:894884637300:web:37bacab00963bb87dabf21`)
6. Scroll down in the app details
7. Look for **"OAuth 2.0 Client IDs"** section
8. You should see something like:
   ```
   OAuth 2.0 Client IDs
   894884637300-xxxxxxxxxxxxx.apps.googleusercontent.com
   ```
9. **Copy the entire Client ID** (it ends with `.apps.googleusercontent.com`)

### Method 2: From Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **coach-dashboard-7b966**
3. Go to **APIs & Services** → **Credentials**
4. Look for **"OAuth 2.0 Client IDs"** section
5. Find the one for **Web client** (it should show your Firebase project)
6. Click on it to see details
7. Copy the **Client ID** (it looks like: `894884637300-xxxxxxxxxxxxx.apps.googleusercontent.com`)

### Method 3: Create OAuth Client ID (If It Doesn't Exist)

If you don't see an OAuth Client ID:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **coach-dashboard-7b966**
3. Go to **APIs & Services** → **Credentials**
4. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
5. If prompted, configure OAuth consent screen first:
   - Choose **External** (for testing)
   - Fill in required fields
   - Save and continue
6. For Application type, select **Web application**
7. Name it: `Coach Dashboard Web`
8. Under **Authorized JavaScript origins**, add:
   - `http://localhost:3000`
   - `http://localhost:5000`
   - `http://localhost:8080`
   - Your production domain (if you have one)
9. Under **Authorized redirect URIs**, add:
   - `http://localhost:3000`
   - `http://localhost:5000`
   - `http://localhost:8080`
10. Click **Create**
11. Copy the **Client ID** that's generated

## What the OAuth Client ID Looks Like

✅ **Correct format:**
```
894884637300-abc123def456ghi789jkl.apps.googleusercontent.com
```

❌ **Not correct:**
```
1:894884637300:web:37bacab00963bb87dabf21  (This is App ID)
894884637300  (This is just the project number)
```

## Once You Have It

1. Open `web/index.html`
2. Find the commented line with `google-signin-client_id`
3. Uncomment it and replace `YOUR_OAUTH_CLIENT_ID` with your actual Client ID
4. Save the file
5. Restart your Flutter app

---

**Note:** The OAuth Client ID is usually automatically created when you register a web app in Firebase, but sometimes you need to create it manually in Google Cloud Console.

