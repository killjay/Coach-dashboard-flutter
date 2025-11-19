import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';

/// Firebase implementation of WorkoutRepository
class FirebaseWorkoutService implements WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Workout>> getWorkouts(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .where('coachId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Workout.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get workouts: $e');
    }
  }

  @override
  Future<Workout> getWorkoutById(String workoutId) async {
    try {
      final doc = await _firestore.collection('workouts').doc(workoutId).get();

      if (!doc.exists) {
        throw Exception('Workout not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Workout data is null');
      }
      return Workout.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get workout: $e');
    }
  }

  @override
  Future<Workout> createWorkout(Workout workout) async {
    try {
      final docRef = _firestore.collection('workouts').doc();

      final workoutData = workout.toJson();
      workoutData.remove('id'); // Remove id as Firestore generates it

      await docRef.set({
        ...workoutData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return workout.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create workout: $e');
    }
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    try {
      final workoutData = workout.toJson();
      workoutData.remove('id');

      await _firestore.collection('workouts').doc(workout.id).update(
            workoutData,
          );

      return workout;
    } catch (e) {
      throw Exception('Failed to update workout: $e');
    }
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _firestore.collection('workouts').doc(workoutId).delete();
    } catch (e) {
      throw Exception('Failed to delete workout: $e');
    }
  }

  @override
  Future<void> assignWorkout({
    required String workoutId,
    required String clientId,
    required DateTime dueDate,
  }) async {
    try {
      // Get workout to get coachId
      final workout = await getWorkoutById(workoutId);

      final assignment = WorkoutAssignment(
        id: '', // Will be set by Firestore
        workoutId: workoutId,
        clientId: clientId,
        assignedDate: DateTime.now(),
        dueDate: dueDate,
        status: 'pending',
      );

      final assignmentData = assignment.toJson();
      assignmentData.remove('id');

      await _firestore.collection('workoutAssignments').add({
        ...assignmentData,
        'coachId': workout.coachId,
        'assignedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign workout: $e');
    }
  }

  @override
  Future<List<WorkoutAssignment>> getAssignedWorkouts(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('workoutAssignments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('assignedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Remove coachId if present (not part of model)
            final cleanData = Map<String, dynamic>.from(data);
            cleanData.remove('coachId');
            return WorkoutAssignment.fromJson({
              'id': doc.id,
              ...cleanData,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get assigned workouts: $e');
    }
  }

  @override
  Future<List<WorkoutAssignment>> getClientWorkoutAssignments(
    String coachId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('workoutAssignments')
          .where('coachId', isEqualTo: coachId)
          .orderBy('assignedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Remove coachId if present (not part of model)
            final cleanData = Map<String, dynamic>.from(data);
            cleanData.remove('coachId');
            return WorkoutAssignment.fromJson({
              'id': doc.id,
              ...cleanData,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get client workout assignments: $e');
    }
  }

  @override
  Future<void> updateWorkoutAssignmentStatus({
    required String assignmentId,
    required String status,
  }) async {
    try {
      await _firestore.collection('workoutAssignments').doc(assignmentId).update(
        {
          'status': status,
          if (status == 'completed')
            'completedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update workout assignment status: $e');
    }
  }

  @override
  Stream<List<Workout>> watchWorkouts(String coachId) {
    return _firestore
        .collection('workouts')
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Workout.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  @override
  Stream<List<WorkoutAssignment>> watchAssignedWorkouts(String clientId) {
    return _firestore
        .collection('workoutAssignments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return WorkoutAssignment.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  @override
  Future<int> getWorkoutAssignmentCount(String workoutId) async {
    try {
      final snapshot = await _firestore
          .collection('workoutAssignments')
          .where('workoutId', isEqualTo: workoutId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get workout assignment count: $e');
    }
  }
}

