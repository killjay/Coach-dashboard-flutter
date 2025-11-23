/// Application configuration
/// Controls which backend implementation to use
class AppConfig {
  AppConfig._();

  /// Whether to use Firebase backend
  /// Set to false to use Node.js/API backend
  /// Currently set to true as Firebase is the chosen backend
  static const bool useFirebase = true;

  /// API base URL (used when useFirebase is false)
  static const String apiBaseUrl = 'https://api.example.com';

  /// Firebase project configuration
  static const String firebaseProjectId = 'your-project-id';

  /// Environment (development, staging, production)
  static const String environment = 'development';

  /// Enable debug logging
  static const bool enableDebugLogging = true;

  /// Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  /// Development mode: Skip authentication
  /// Set to true to bypass login and go directly to dashboards
  /// Set to false to enable authentication (for production)
  static const bool skipAuthentication = false;

  /// Default role when skipping authentication
  /// Options: 'coach' or 'client'
  static const String defaultRole = 'client';
}

