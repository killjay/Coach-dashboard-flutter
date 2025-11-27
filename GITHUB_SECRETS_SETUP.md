# GitHub Secrets Setup Guide

This guide explains how to set up GitHub Secrets for Firebase configuration to enable automated deployments.

## Required Secrets

You need to add the following secrets to your GitHub repository:

### How to Add Secrets

1. Go to your GitHub repository: `https://github.com/killjay/Coach-dashboard-flutter`
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below:

### Firebase Configuration Secrets

#### Project-wide Secrets (same for all platforms)
- **`FIREBASE_PROJECT_ID`**: `coach-dashboard-7b966`
- **`FIREBASE_MESSAGING_SENDER_ID`**: `894884637300`
- **`FIREBASE_AUTH_DOMAIN`**: `coach-dashboard-7b966.firebaseapp.com`
- **`FIREBASE_STORAGE_BUCKET`**: `coach-dashboard-7b966.firebasestorage.app`

#### Web Platform Secrets
- **`FIREBASE_WEB_API_KEY`**: Your web API key (from Firebase Console)
- **`FIREBASE_WEB_APP_ID`**: `1:894884637300:web:37bacab00963bb87dabf21`
- **`FIREBASE_MEASUREMENT_ID`**: `G-5STFCC02HN` (optional, for Analytics)

#### Android Platform Secrets
- **`FIREBASE_ANDROID_API_KEY`**: Your Android API key (from Firebase Console)
- **`FIREBASE_ANDROID_APP_ID`**: `1:894884637300:android:3a885c38a8f6049adabf21`

#### iOS Platform Secrets
- **`FIREBASE_IOS_API_KEY`**: Your iOS API key (from Firebase Console)
- **`FIREBASE_IOS_APP_ID`**: `1:894884637300:ios:185cccf4ce6f4b1cdabf21`

## How to Find Your API Keys

1. Go to [Firebase Console](https://console.firebase.google.com/project/coach-dashboard-7b966/settings/general)
2. Scroll down to **Your apps** section
3. Click on the gear icon next to your app (Web/Android/iOS)
4. Click **Project settings**
5. Find the **apiKey** field in the configuration

## Quick Setup Script

You can also find all these values in your local `lib/firebase_options.dart` file (if you have it configured locally).

## After Adding Secrets

Once you've added all the secrets:
1. The GitHub Actions workflow will automatically use them
2. The `firebase_options.dart` file will be generated during the build process
3. Your deployments will work without exposing API keys in the repository

## Security Notes

- ✅ Secrets are encrypted and only accessible during workflow runs
- ✅ Secrets are never exposed in logs or build outputs
- ✅ Only repository collaborators with admin access can view/manage secrets
- ✅ The generated `firebase_options.dart` is not committed to the repository (it's in `.gitignore`)






