import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';

/// Firebase implementation of GoalRepository
class FirebaseGoalService implements GoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        ...data,
        'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'targetDate': (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
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
              ...data,
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'targetDate': (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
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
              ...data,
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'targetDate': (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
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
            return GoalProgressLog.fromJson({
              'id': doc.id,
              ...data,
              'loggedAt': (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
                ...data,
                'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'targetDate': (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
                'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
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
                ...data,
                'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'targetDate': (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
                'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
              });
            })
            .toList());
  }
}

