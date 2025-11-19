import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_log.freezed.dart';
part 'workout_log.g.dart';

/// Workout log model - tracks a completed workout session
@freezed
class WorkoutLog with _$WorkoutLog {
  const factory WorkoutLog({
    required String id,
    required String workoutId,
    required String assignmentId,
    required String clientId,
    required DateTime startedAt,
    DateTime? completedAt,
    int? totalDuration, // in seconds
    String? notes,
    required List<ExerciseLog> exerciseLogs,
    DateTime? createdAt,
  }) = _WorkoutLog;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogFromJson(json);
}

/// Exercise log model - tracks individual exercise completion
@freezed
class ExerciseLog with _$ExerciseLog {
  const factory ExerciseLog({
    required String id,
    required String exerciseId,
    required String exerciseName,
    required List<SetLog> sets,
    String? notes,
    bool? isPersonalRecord, // True if this was a PR
  }) = _ExerciseLog;

  factory ExerciseLog.fromJson(Map<String, dynamic> json) =>
      _$ExerciseLogFromJson(json);
}

/// Set log model - tracks individual set completion
@freezed
class SetLog with _$SetLog {
  const factory SetLog({
    required int setNumber,
    int? reps,
    double? weight, // in kg
    int? duration, // in seconds (for time-based exercises)
    @Default(false) bool isCompleted,
    String? notes,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) =>
      _$SetLogFromJson(json);
}

/// Personal record model - tracks PRs for exercises
@freezed
class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required String id,
    required String clientId,
    required String exerciseId,
    required String exerciseName,
    required String recordType, // 'max_weight', 'max_reps', 'max_duration'
    required double value,
    required DateTime achievedAt,
    String? workoutLogId, // Reference to the workout log where PR was achieved
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
}

