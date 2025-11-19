# Troubleshooting Firebase Authentication Errors

## Common Error: 400 Bad Request

If you're seeing a `400 (Bad Request)` error when trying to sign up, here are the most common causes and solutions:

### 1. Email/Password Authentication Not Enabled

**Problem:** The most common cause of a 400 error is that Email/Password authentication is not enabled in Firebase Console.

**Solution:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Email/Password** in the list
5. Click on it and **Enable** it
6. Click **Save**

### 2. Weak Password

**Problem:** Firebase requires passwords to be at least 6 characters long.

**Solution:**
- Use a password with at least 6 characters
- Example: `Test123!` or `password123`

### 3. Invalid Email Format

**Problem:** The email address format is incorrect.

**Solution:**
- Ensure the email contains `@` and a valid domain
- Example: `user@example.com`
- Avoid spaces or special characters in the email

### 4. Email Already Exists

**Problem:** You're trying to register with an email that's already registered.

**Solution:**
- Use a different email address, or
- Sign in instead of registering

### 5. API Key Restrictions

**Problem:** Your Firebase API key might have restrictions that prevent authentication.

**Solution:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your Firebase API key
4. Check if there are any HTTP referrer restrictions
5. For web apps, make sure your domain is allowed

### 6. Firebase Project Configuration

**Problem:** The Firebase project might not be properly configured.

**Solution:**
1. Verify `firebase_options.dart` exists in your project
2. Check that the API key in the error matches your Firebase project
3. Ensure you're using the correct Firebase project

## How to Check the Actual Error

The app should show you a dialog with the specific error message. If you're not seeing it, check the browser console for more details.

### In Browser Console:
1. Open Developer Tools (F12)
2. Go to the **Console** tab
3. Look for error messages that start with `FirebaseError` or `Exception`
4. The error message will tell you the specific issue

## Quick Checklist

Before trying to register again, verify:

- [ ] Email/Password authentication is enabled in Firebase Console
- [ ] Password is at least 6 characters
- [ ] Email format is valid (contains @ and domain)
- [ ] Email is not already registered
- [ ] Firebase project is correctly configured
- [ ] `firebase_options.dart` file exists and is up to date

## Testing Steps

1. **Enable Email/Password in Firebase:**
   ```
   Firebase Console → Authentication → Sign-in method → Email/Password → Enable
   ```

2. **Try registering with:**
   - Email: `test@example.com`
   - Password: `test123` (at least 6 characters)
   - Name: `Test User`
   - Role: `Client` or `Coach`

3. **If it still fails:**
   - Check the browser console for the exact error
   - Verify Firebase project settings
   - Make sure you're using the correct Firebase project

## Common Error Messages

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `weak-password` | Password too short | Use at least 6 characters |
| `email-already-in-use` | Email exists | Sign in instead or use different email |
| `invalid-email` | Bad email format | Check email format |
| `operation-not-allowed` | Auth method disabled | Enable Email/Password in Firebase Console |
| `network-request-failed` | Network issue | Check internet connection |

## Still Having Issues?

1. **Check Firebase Console Logs:**
   - Go to Firebase Console → Authentication → Users
   - Check if any users were created despite the error

2. **Verify Firebase Configuration:**
   ```bash
   # Make sure firebase_options.dart exists
   ls lib/firebase_options.dart
   
   # Regenerate if needed
   flutterfire configure
   ```

3. **Clear Browser Cache:**
   - Sometimes cached Firebase config can cause issues
   - Clear browser cache and try again

4. **Check Network Tab:**
   - Open Developer Tools → Network tab
   - Try registering again
   - Look at the failed request
   - Check the response body for detailed error message

---

**Last Updated:** $(date)

