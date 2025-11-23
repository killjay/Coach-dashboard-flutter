import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';

/// Firebase implementation of GoalRepository
class FirebaseGoalService implements GoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convert Firestore data to JSON format, handling Timestamps
  Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    
    // Convert Timestamp to ISO 8601 string
    if (converted['createdAt'] != null) {
      if (converted['createdAt'] is Timestamp) {
        converted['createdAt'] = (converted['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (converted['createdAt'] is DateTime) {
        converted['createdAt'] = (converted['createdAt'] as DateTime)
            .toIso8601String();
      }
    }
    
    if (converted['updatedAt'] != null) {
      if (converted['updatedAt'] is Timestamp) {
        converted['updatedAt'] = (converted['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (converted['updatedAt'] is DateTime) {
        converted['updatedAt'] = (converted['updatedAt'] as DateTime)
            .toIso8601String();
      }
    }
    
    if (converted['startDate'] != null) {
      if (converted['startDate'] is Timestamp) {
        converted['startDate'] = (converted['startDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (converted['startDate'] is DateTime) {
        converted['startDate'] = (converted['startDate'] as DateTime)
            .toIso8601String();
      }
    }
    
    if (converted['targetDate'] != null) {
      if (converted['targetDate'] is Timestamp) {
        converted['targetDate'] = (converted['targetDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (converted['targetDate'] is DateTime) {
        converted['targetDate'] = (converted['targetDate'] as DateTime)
            .toIso8601String();
      }
    }
    
    if (converted['completedAt'] != null) {
      if (converted['completedAt'] is Timestamp) {
        converted['completedAt'] = (converted['completedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (converted['completedAt'] is DateTime) {
        converted['completedAt'] = (converted['completedAt'] as DateTime)
            .toIso8601String();
      }
    }
    
    return converted;
  }

  @override
  Future<Goal> createGoal(Goal goal) async {
    try {
      final docRef = _firestore.collection('goals').doc();

      final goalData = goal.toJson();
      goalData.remove('id');

      await docRef.set({
        ...goalData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'startDate': Timestamp.fromDate(goal.startDate),
        'targetDate': Timestamp.fromDate(goal.targetDate),
        'completedAt': goal.completedAt != null
            ? Timestamp.fromDate(goal.completedAt!)
            : null,
      });

      return goal.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  @override
  Future<Goal> getGoalById(String goalId) async {
    try {
      final doc = await _firestore.collection('goals').doc(goalId).get();

      if (!doc.exists) {
        throw Exception('Goal not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      return Goal.fromJson({
        'id': doc.id,
        ..._convertFirestoreData(data),
      });
    } catch (e) {
      throw Exception('Failed to get goal: $e');
    }
  }

  @override
  Future<List<Goal>> getClientGoals(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Goal.fromJson({
              'id': doc.id,
              ..._convertFirestoreData(data),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get client goals: $e');
    }
  }

  @override
  Future<List<Goal>> getCoachGoals(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('coachId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Goal.fromJson({
              'id': doc.id,
              ..._convertFirestoreData(data),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get coach goals: $e');
    }
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    try {
      final goalData = goal.toJson();
      goalData.remove('id');

      await _firestore.collection('goals').doc(goal.id).update({
        ...goalData,
        'updatedAt': FieldValue.serverTimestamp(),
        'startDate': Timestamp.fromDate(goal.startDate),
        'targetDate': Timestamp.fromDate(goal.targetDate),
        'completedAt': goal.completedAt != null
            ? Timestamp.fromDate(goal.completedAt!)
            : null,
      });

      return goal;
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('goals').doc(goalId).delete();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  @override
  Future<Goal> updateGoalProgress({
    required String goalId,
    required double currentValue,
  }) async {
    try {
      final goal = await getGoalById(goalId);
      
      // Calculate progress percentage
      final progressPercentage = (currentValue / goal.targetValue) * 100;
      
      // Check if goal is completed
      final isCompleted = progressPercentage >= 100;
      
      final updatedGoal = goal.copyWith(
        currentValue: currentValue,
        progressPercentage: progressPercentage.clamp(0, 100),
        status: isCompleted ? GoalStatus.completed : goal.status,
        completedAt: isCompleted ? DateTime.now() : goal.completedAt,
      );

      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('Failed to update goal progress: $e');
    }
  }

  @override
  Future<GoalProgressLog> logGoalProgress(GoalProgressLog progressLog) async {
    try {
      final docRef = _firestore.collection('goalProgressLogs').doc();

      final logData = progressLog.toJson();
      logData.remove('id');

      await docRef.set({
        ...logData,
        'loggedAt': Timestamp.fromDate(progressLog.loggedAt),
      });

      // Update goal progress
      await updateGoalProgress(
        goalId: progressLog.goalId,
        currentValue: progressLog.value,
      );

      return progressLog.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log goal progress: $e');
    }
  }

  @override
  Future<List<GoalProgressLog>> getGoalProgressHistory(String goalId) async {
    try {
      final snapshot = await _firestore
          .collection('goalProgressLogs')
          .where('goalId', isEqualTo: goalId)
          .orderBy('loggedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final converted = Map<String, dynamic>.from(data);
            
            // Convert Timestamp to ISO 8601 string
            if (converted['loggedAt'] != null) {
              if (converted['loggedAt'] is Timestamp) {
                converted['loggedAt'] = (converted['loggedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String();
              } else if (converted['loggedAt'] is DateTime) {
                converted['loggedAt'] = (converted['loggedAt'] as DateTime)
                    .toIso8601String();
              }
            }
            
            return GoalProgressLog.fromJson({
              'id': doc.id,
              ...converted,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get goal progress history: $e');
    }
  }

  @override
  Future<GoalMilestone> completeMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    try {
      final goal = await getGoalById(goalId);
      
      final updatedMilestones = goal.milestones?.map((milestone) {
        if (milestone.id == milestoneId) {
          return milestone.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        }
        return milestone;
      }).toList();

      final updatedGoal = goal.copyWith(milestones: updatedMilestones);
      await updateGoal(updatedGoal);

      final completedMilestone = updatedMilestones?.firstWhere(
        (m) => m.id == milestoneId,
        orElse: () => throw Exception('Milestone not found'),
      );
      
      if (completedMilestone == null) {
        throw Exception('Milestone not found');
      }
      
      return completedMilestone;
    } catch (e) {
      throw Exception('Failed to complete milestone: $e');
    }
  }

  @override
  Stream<List<Goal>> watchClientGoals(String clientId) {
    return _firestore
        .collection('goals')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Goal.fromJson({
                'id': doc.id,
                ..._convertFirestoreData(data),
              });
            })
            .toList());
  }

  @override
  Stream<List<Goal>> watchCoachGoals(String coachId) {
    return _firestore
        .collection('goals')
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Goal.fromJson({
                'id': doc.id,
                ..._convertFirestoreData(data),
              });
            })
            .toList());
  }
}

