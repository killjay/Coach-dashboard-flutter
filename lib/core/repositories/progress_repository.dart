import 'dart:typed_data';
import '../models/progress.dart';

/// Abstract repository interface for progress tracking
/// This abstraction allows switching between Firebase and Node.js backends
abstract class ProgressRepository {
  // Water tracking
  /// Log water intake
  Future<WaterLog> logWater({
    required String clientId,
    required double amount,
    DateTime? loggedAt,
  });

  /// Get water logs for a date range
  Future<List<WaterLog>> getWaterLogs({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get daily water total
  Future<double> getDailyWaterTotal(String clientId, DateTime date);

  // Step tracking
  /// Log steps
  Future<StepLog> logSteps({
    required String clientId,
    required int steps,
    required String source,
    DateTime? date,
  });

  /// Get step logs for a date range
  Future<List<StepLog>> getStepLogs({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get daily step total
  Future<int> getDailyStepTotal(String clientId, DateTime date);

  // Weight tracking
  /// Log weight
  Future<WeightLog> logWeight({
    required String clientId,
    required double weight,
    DateTime? loggedAt,
  });

  /// Get weight logs
  Future<List<WeightLog>> getWeightLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // Body measurements
  /// Log body measurements
  Future<BodyMeasurement> logBodyMeasurement({
    required String clientId,
    double? chest,
    double? waist,
    double? hips,
    double? arms,
    double? thighs,
    double? bodyFat,
    double? muscleMass,
    DateTime? measuredAt,
  });

  /// Get body measurement history
  Future<List<BodyMeasurement>> getBodyMeasurements({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // Progress photos
  /// Upload progress photo
  /// On web, pass bytes. On mobile, pass imagePath.
  Future<ProgressPhoto> uploadProgressPhoto({
    required String clientId,
    String? imagePath,
    Uint8List? imageBytes,
    String? notes,
  });

  /// Get progress photos
  Future<List<ProgressPhoto>> getProgressPhotos({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Delete progress photo
  Future<void> deleteProgressPhoto(String photoId);

  // Real-time streams
  /// Watch water logs in real-time
  Stream<List<WaterLog>> watchWaterLogs(String clientId, DateTime date);

  /// Watch step logs in real-time
  Stream<List<StepLog>> watchStepLogs(String clientId, DateTime date);
}


