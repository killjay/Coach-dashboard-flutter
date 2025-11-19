import '../models/workout.dart';

/// Abstract repository interface for workout management
/// This abstraction allows switching between Firebase and Node.js backends
abstract class WorkoutRepository {
  /// Get all workouts for a coach
  Future<List<Workout>> getWorkouts(String coachId);

  /// Get a single workout by ID
  Future<Workout> getWorkoutById(String workoutId);

  /// Create a new workout
  Future<Workout> createWorkout(Workout workout);

  /// Update an existing workout
  Future<Workout> updateWorkout(Workout workout);

  /// Delete a workout
  Future<void> deleteWorkout(String workoutId);

  /// Assign a workout to a client
  Future<void> assignWorkout({
    required String workoutId,
    required String clientId,
    required DateTime dueDate,
  });

  /// Get workouts assigned to a client
  Future<List<WorkoutAssignment>> getAssignedWorkouts(String clientId);

  /// Get workout assignments for a coach's clients
  Future<List<WorkoutAssignment>> getClientWorkoutAssignments(
    String coachId,
  );

  /// Update workout assignment status
  Future<void> updateWorkoutAssignmentStatus({
    required String assignmentId,
    required String status,
  });

  /// Watch workouts in real-time (for coach)
  Stream<List<Workout>> watchWorkouts(String coachId);

  /// Watch assigned workouts in real-time (for client)
  Stream<List<WorkoutAssignment>> watchAssignedWorkouts(String clientId);

  /// Get the count of clients assigned to a workout
  Future<int> getWorkoutAssignmentCount(String workoutId);
}


