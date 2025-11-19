import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/progress.dart';
import '../repositories/progress_repository.dart';

/// Service for automatic step tracking using HealthKit (iOS) and Google Fit (Android)
class StepTrackingService {
  final ProgressRepository progressRepository;
  Health? _health;
  bool _isInitialized = false;

  StepTrackingService(this.progressRepository);

  /// Initialize health service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _health = Health();

      // Request permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request health data permissions
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        // Request HealthKit permissions
        final types = [
          HealthDataType.STEPS,
        ];
        return await _health!.requestAuthorization(types);
      } else if (Platform.isAndroid) {
        // Request Google Fit permissions
        final types = [
          HealthDataType.STEPS,
        ];
        return await _health!.requestAuthorization(types);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if health data is available
  Future<bool> isAvailable() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _health!.hasPermissions([HealthDataType.STEPS]) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get steps for today
  Future<int> getTodaySteps() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return 0;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      int totalSteps = 0;
      for (final data in steps) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  /// Get steps for a specific date
  Future<int> getStepsForDate(DateTime date) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return 0;
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      int totalSteps = 0;
      for (final data in steps) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  /// Sync steps for today to Firebase
  Future<void> syncTodaySteps(String clientId) async {
    try {
      final steps = await getTodaySteps();
      if (steps > 0) {
        // Check if we already logged steps today
        final today = DateTime.now();
        final existingTotal = await progressRepository.getDailyStepTotal(
          clientId,
          today,
        );

        // Only log if the new value is different (to avoid duplicates)
        if (steps != existingTotal) {
          // Calculate the difference to log
          final difference = steps - existingTotal;
          if (difference > 0) {
            await progressRepository.logSteps(
              clientId: clientId,
              steps: difference,
              source: Platform.isIOS ? 'healthkit' : 'google_fit',
              date: today,
            );
          }
        }
      }
    } catch (e) {
      // Silently fail - manual entry is still available
    }
  }

  /// Sync steps for a date range
  Future<void> syncStepsForDateRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final steps = await getStepsForDate(currentDate);
        if (steps > 0) {
          final existingTotal = await progressRepository.getDailyStepTotal(
            clientId,
            currentDate,
          );

          if (steps != existingTotal) {
            final difference = steps - existingTotal;
            if (difference > 0) {
              await progressRepository.logSteps(
                clientId: clientId,
                steps: difference,
                source: Platform.isIOS ? 'healthkit' : 'google_fit',
                date: currentDate,
              );
            }
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Start background step tracking (for periodic sync)
  Future<void> startBackgroundTracking(String clientId) async {
    // This would typically use a background task service
    // For now, we'll sync when the app is opened
    await syncTodaySteps(clientId);
  }
}

