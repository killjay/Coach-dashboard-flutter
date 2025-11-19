import '../models/goal.dart';

/// Abstract repository interface for goal management
abstract class GoalRepository {
  /// Create a new goal
  Future<Goal> createGoal(Goal goal);

  /// Get a goal by ID
  Future<Goal> getGoalById(String goalId);

  /// Get all goals for a client
  Future<List<Goal>> getClientGoals(String clientId);

  /// Get all goals for a coach (across all clients)
  Future<List<Goal>> getCoachGoals(String coachId);

  /// Update a goal
  Future<Goal> updateGoal(Goal goal);

  /// Delete a goal
  Future<void> deleteGoal(String goalId);

  /// Update goal progress
  Future<Goal> updateGoalProgress({
    required String goalId,
    required double currentValue,
  });

  /// Log goal progress
  Future<GoalProgressLog> logGoalProgress(GoalProgressLog progressLog);

  /// Get goal progress history
  Future<List<GoalProgressLog>> getGoalProgressHistory(String goalId);

  /// Mark milestone as completed
  Future<GoalMilestone> completeMilestone({
    required String goalId,
    required String milestoneId,
  });

  /// Watch goals in real-time for a client
  Stream<List<Goal>> watchClientGoals(String clientId);

  /// Watch goals in real-time for a coach
  Stream<List<Goal>> watchCoachGoals(String coachId);
}

