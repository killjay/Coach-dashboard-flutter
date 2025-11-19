# Development Mode - Authentication Disabled

## Current Status

✅ **Authentication is currently DISABLED** for faster development.

The app will skip login and go directly to the dashboard.

## Configuration

In `lib/core/config/app_config.dart`:

```dart
/// Development mode: Skip authentication
static const bool skipAuthentication = true;

/// Default role when skipping authentication
static const String defaultRole = 'coach'; // or 'client'
```

## Switching Between Coach and Client Views

### Option 1: Change Default Role

Edit `lib/core/config/app_config.dart`:
- Set `defaultRole = 'coach'` for Coach Dashboard
- Set `defaultRole = 'client'` for Client Dashboard
- Restart the app

### Option 2: Direct URL Navigation

When running the app, you can navigate directly:
- Coach Dashboard: `http://localhost:8080/#/coach`
- Client Dashboard: `http://localhost:8080/#/client`

### Option 3: Add Role Switcher (Future)

We can add a simple role switcher button in the dashboard for easy testing.

## Re-enabling Authentication

When you're ready to test authentication:

1. Open `lib/core/config/app_config.dart`
2. Change:
   ```dart
   static const bool skipAuthentication = false;
   ```
3. Restart the app
4. The app will now require login

## Benefits of This Approach

- ✅ Faster development - no need to login every time
- ✅ Easy to switch between coach/client views
- ✅ All authentication code is preserved
- ✅ Can re-enable with one config change
- ✅ No need to set up Firebase auth for now

## What's Still Available

Even with auth disabled, you can still:
- Access all routes directly
- Test all features
- Build UI components
- Test Firebase services (if configured)
- Switch between dashboards

---

**Note:** Remember to re-enable authentication before deploying to production!

