import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';
part 'workout.g.dart';

/// Workout model
@freezed
class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String coachId,
    required String name,
    String? description,
    required List<Exercise> exercises,
    required int duration, // in minutes
    required String difficulty, // 'beginner', 'intermediate', 'advanced'
    required String category, // 'cardio', 'strength_training', 'flexibility', 'hiit', 'other'
    @Default([]) List<String> steps, // Instructions on how to perform the workout
    String? videoUrl, // YouTube link or uploaded video URL
    DateTime? createdAt,
  }) = _Workout;

  factory Workout.fromJson(Map<String, dynamic> json) =>
      _$WorkoutFromJson(json);
}

/// Exercise model
@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    String? description,
    required int sets,
    int? reps,
    int? duration, // in seconds
    required int restPeriod, // in seconds
    double? weight, // in kg
    String? mediaUrl, // video or image URL
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}

/// Workout assignment model
@freezed
class WorkoutAssignment with _$WorkoutAssignment {
  const factory WorkoutAssignment({
    required String id,
    required String workoutId,
    required String clientId,
    required DateTime assignedDate,
    required DateTime dueDate,
    required String status, // 'pending', 'in_progress', 'completed'
    DateTime? completedAt,
  }) = _WorkoutAssignment;

  factory WorkoutAssignment.fromJson(Map<String, dynamic> json) =>
      _$WorkoutAssignmentFromJson(json);
}


