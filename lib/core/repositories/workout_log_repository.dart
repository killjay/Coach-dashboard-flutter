import '../models/workout_log.dart';

/// Abstract repository interface for workout log management
abstract class WorkoutLogRepository {
  /// Start a workout session
  Future<WorkoutLog> startWorkout({
    required String workoutId,
    required String assignmentId,
    required String clientId,
  });

  /// Save exercise log during workout
  Future<void> saveExerciseLog({
    required String workoutLogId,
    required ExerciseLog exerciseLog,
  });

  /// Complete a workout session
  Future<WorkoutLog> completeWorkout({
    required String workoutLogId,
    String? notes,
  });

  /// Get workout logs for a client
  Future<List<WorkoutLog>> getWorkoutLogs(String clientId);

  /// Get a specific workout log
  Future<WorkoutLog> getWorkoutLog(String workoutLogId);

  /// Get workout logs for a specific workout
  Future<List<WorkoutLog>> getWorkoutLogsByWorkout({
    required String workoutId,
    required String clientId,
  });

  /// Get personal records for a client
  Future<List<PersonalRecord>> getPersonalRecords(String clientId);

  /// Get personal record for a specific exercise
  Future<PersonalRecord?> getPersonalRecord({
    required String clientId,
    required String exerciseId,
    required String recordType,
  });

  /// Watch workout logs in real-time
  Stream<List<WorkoutLog>> watchWorkoutLogs(String clientId);
}

