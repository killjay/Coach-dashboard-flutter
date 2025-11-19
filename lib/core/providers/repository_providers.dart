import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../repositories/auth_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/meal_plan_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/message_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/workout_log_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_workout_service.dart';
import '../services/firebase_progress_service.dart';
import '../services/firebase_meal_plan_service.dart';
import '../services/firebase_client_service.dart';
import '../services/firebase_invoice_service.dart';
import '../services/firebase_message_service.dart';
import '../services/firebase_notification_service.dart';
import '../services/firebase_goal_service.dart';
import '../services/firebase_workout_log_service.dart';

/// Provider for AuthRepository
/// Switches between Firebase and API implementations based on config
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseAuthService();
  } else {
    // TODO: Return API implementation when created
    // return ApiAuthService(ref.read(apiServiceProvider));
    throw UnimplementedError('API auth service not yet implemented');
  }
});

/// Provider for WorkoutRepository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseWorkoutService();
  } else {
    // TODO: Return API implementation when created
    // return ApiWorkoutService(ref.read(apiServiceProvider));
    throw UnimplementedError('API workout service not yet implemented');
  }
});

/// Provider for ProgressRepository
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseProgressService();
  } else {
    // TODO: Return API implementation when created
    // return ApiProgressService(ref.read(apiServiceProvider));
    throw UnimplementedError('API progress service not yet implemented');
  }
});

/// Provider for MealPlanRepository
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseMealPlanService();
  } else {
    // TODO: Return API implementation when created
    // return ApiMealPlanService(ref.read(apiServiceProvider));
    throw UnimplementedError('API meal plan service not yet implemented');
  }
});

/// Provider for ClientRepository
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseClientService();
  } else {
    // TODO: Return API implementation when created
    // return ApiClientService(ref.read(apiServiceProvider));
    throw UnimplementedError('API client service not yet implemented');
  }
});

/// Provider for InvoiceRepository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseInvoiceService();
  } else {
    // TODO: Return API implementation when created
    // return ApiInvoiceService(ref.read(apiServiceProvider));
    throw UnimplementedError('API invoice service not yet implemented');
  }
});

/// Provider for MessageRepository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseMessageService();
  } else {
    // TODO: Return API implementation when created
    // return ApiMessageService(ref.read(apiServiceProvider));
    throw UnimplementedError('API message service not yet implemented');
  }
});

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseNotificationService();
  } else {
    // TODO: Return API implementation when created
    // return ApiNotificationService(ref.read(apiServiceProvider));
    throw UnimplementedError('API notification service not yet implemented');
  }
});

/// Provider for GoalRepository
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseGoalService();
  } else {
    // TODO: Return API implementation when created
    // return ApiGoalService(ref.read(apiServiceProvider));
    throw UnimplementedError('API goal service not yet implemented');
  }
});

/// Provider for WorkoutLogRepository
final workoutLogRepositoryProvider = Provider<WorkoutLogRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseWorkoutLogService();
  } else {
    // TODO: Return API implementation when created
    // return ApiWorkoutLogService(ref.read(apiServiceProvider));
    throw UnimplementedError('API workout log service not yet implemented');
  }
});

