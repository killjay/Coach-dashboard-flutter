/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Coach-Client App';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String themeKey = 'theme_mode';

  // User Roles
  static const String roleCoach = 'coach';
  static const String roleClient = 'client';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Water Tracking
  static const double defaultWaterGoal = 2000.0; // ml
  static const List<double> waterQuickAmounts = [250.0, 500.0, 750.0, 1000.0];

  // Step Tracking
  static const int defaultStepGoal = 10000;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
}


