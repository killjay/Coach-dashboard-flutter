import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';

/// Firebase implementation of WorkoutRepository
class FirebaseWorkoutService implements WorkoutRepository {
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
      }
    }
    
    return converted;
  }

  /// Convert Firestore assignment data to JSON format, handling Timestamps
  Map<String, dynamic> _convertAssignmentData(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    
    // Convert Timestamp fields to ISO 8601 strings
    if (converted['assignedDate'] != null) {
      if (converted['assignedDate'] is Timestamp) {
        converted['assignedDate'] = (converted['assignedDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
    }
    
    if (converted['dueDate'] != null) {
      if (converted['dueDate'] is Timestamp) {
        converted['dueDate'] = (converted['dueDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
    }
    
    if (converted['completedAt'] != null) {
      if (converted['completedAt'] is Timestamp) {
        converted['completedAt'] = (converted['completedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
    }
    
    return converted;
  }

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
              ..._convertFirestoreData(data),
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
      if (workoutId.isEmpty) {
        throw Exception('Workout ID is empty');
      }

      final doc = await _firestore.collection('workouts').doc(workoutId).get();

      if (!doc.exists) {
        throw Exception('Workout not found with ID: $workoutId');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Workout data is null for ID: $workoutId');
      }

      // Convert Firestore data
      final convertedData = _convertFirestoreData(data);
      
      // Ensure exercises are in the correct format (List<Map<String, dynamic>>)
      if (convertedData['exercises'] != null) {
        if (convertedData['exercises'] is List) {
          final exercisesList = convertedData['exercises'] as List;
          convertedData['exercises'] = exercisesList.map((exercise) {
            if (exercise is Map<String, dynamic>) {
              return exercise;
            }
            // If it's already serialized, return as is
            return exercise;
          }).toList();
        }
      }

      try {
        return Workout.fromJson({
          'id': doc.id,
          ...convertedData,
        });
      } catch (e) {
        throw Exception('Failed to parse workout data: $e. Workout ID: $workoutId');
      }
    } catch (e) {
      if (e.toString().contains('Workout not found') || e.toString().contains('Workout ID is empty')) {
        rethrow;
      }
      throw Exception('Failed to get workout: $e');
    }
  }

  @override
  Future<Workout> createWorkout(Workout workout) async {
    try {
      final docRef = _firestore.collection('workouts').doc();

      final workoutData = workout.toJson();
      workoutData.remove('id'); // Remove id as Firestore generates it
      
      // Explicitly serialize exercises to ensure they're converted to JSON
      if (workoutData['exercises'] != null) {
        workoutData['exercises'] = workout.exercises
            .map((exercise) => exercise.toJson())
            .toList();
      }

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
      
      // Explicitly serialize exercises to ensure they're converted to JSON
      if (workoutData['exercises'] != null) {
        workoutData['exercises'] = workout.exercises
            .map((exercise) => exercise.toJson())
            .toList();
      }

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
              ..._convertAssignmentData(cleanData),
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
              ..._convertAssignmentData(cleanData),
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
                ..._convertFirestoreData(data),
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
                ..._convertAssignmentData(data),
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

