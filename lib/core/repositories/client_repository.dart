import '../models/user.dart';
import '../models/client_coach_relationship.dart';
import '../models/progress.dart';
import '../models/workout.dart';

/// Abstract repository interface for client management
abstract class ClientRepository {
  /// Get all clients for a coach
  Future<List<User>> getClients(String coachId);

  /// Get client-coach relationships for a coach
  Future<List<ClientCoachRelationship>> getClientRelationships(String coachId);

  /// Add a client to a coach
  Future<void> addClient({
    required String coachId,
    required String clientId,
  });

  /// Remove a client from a coach
  Future<void> removeClient({
    required String coachId,
    required String clientId,
  });

  /// Get latest body composition for a client
  Future<BodyComposition?> getLatestBodyComposition(String clientId);

  /// Get progress photos for a client
  Future<List<ProgressPhoto>> getProgressPhotos({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get workout progress for a client
  Future<List<WorkoutAssignment>> getClientWorkoutProgress(String clientId);

  /// Get water intake logs for a client
  Future<List<WaterLog>> getClientWaterLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get step logs for a client
  Future<List<StepLog>> getClientStepLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Body composition summary model
class BodyComposition {
  final double? weight;
  final double? bodyFat;
  final double? muscleMass;
  final DateTime? lastUpdated;

  BodyComposition({
    this.weight,
    this.bodyFat,
    this.muscleMass,
    this.lastUpdated,
  });
}

