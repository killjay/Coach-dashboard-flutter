import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_log.dart';
import '../repositories/workout_log_repository.dart';

class FirebaseWorkoutLogService implements WorkoutLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<WorkoutLog> startWorkout({
    required String workoutId,
    required String assignmentId,
    required String clientId,
  }) async {
    try {
      final workoutLog = WorkoutLog(
        id: '',
        workoutId: workoutId,
        assignmentId: assignmentId,
        clientId: clientId,
        startedAt: DateTime.now(),
        exerciseLogs: [],
        createdAt: DateTime.now(),
      );

      final logData = workoutLog.toJson();
      logData.remove('id');

      final docRef = await _firestore.collection('workoutLogs').add({
        ...logData,
        'startedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update assignment status to in_progress
      await _firestore.collection('workoutAssignments').doc(assignmentId).update({
        'status': 'in_progress',
      });

      return workoutLog.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to start workout: $e');
    }
  }

  @override
  Future<void> saveExerciseLog({
    required String workoutLogId,
    required ExerciseLog exerciseLog,
  }) async {
    try {
      final logRef = _firestore.collection('workoutLogs').doc(workoutLogId);
      final logDoc = await logRef.get();

      if (!logDoc.exists) {
        throw Exception('Workout log not found');
      }

      final currentLogs = (logDoc.data()?['exerciseLogs'] as List<dynamic>?) ?? [];
      final exerciseLogs = currentLogs
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList();

      // Update or add exercise log
      final existingIndex = exerciseLogs.indexWhere((e) => e.exerciseId == exerciseLog.exerciseId);
      if (existingIndex >= 0) {
        exerciseLogs[existingIndex] = exerciseLog;
      } else {
        exerciseLogs.add(exerciseLog);
      }

      await logRef.update({
        'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to save exercise log: $e');
    }
  }

  @override
  Future<WorkoutLog> completeWorkout({
    required String workoutLogId,
    String? notes,
  }) async {
    try {
      final logRef = _firestore.collection('workoutLogs').doc(workoutLogId);
      final logDoc = await logRef.get();

      if (!logDoc.exists) {
        throw Exception('Workout log not found');
      }

      final data = logDoc.data() as Map<String, dynamic>;
      final startedAt = (data['startedAt'] as Timestamp).toDate();
      final completedAt = DateTime.now();
      final totalDuration = completedAt.difference(startedAt).inSeconds;

      await logRef.update({
        'completedAt': FieldValue.serverTimestamp(),
        'totalDuration': totalDuration,
        if (notes != null) 'notes': notes,
      });

      // Update assignment status to completed
      final assignmentId = data['assignmentId'] as String;
      await _firestore.collection('workoutAssignments').doc(assignmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Check for personal records
      final exerciseLogs = (data['exerciseLogs'] as List<dynamic>?)
              ?.map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      await _checkAndSavePersonalRecords(
        clientId: data['clientId'] as String,
        exerciseLogs: exerciseLogs,
        workoutLogId: workoutLogId,
      );

      return getWorkoutLog(workoutLogId);
    } catch (e) {
      throw Exception('Failed to complete workout: $e');
    }
  }

  Future<void> _checkAndSavePersonalRecords({
    required String clientId,
    required List<ExerciseLog> exerciseLogs,
    required String workoutLogId,
  }) async {
    for (final exerciseLog in exerciseLogs) {
      for (final setLog in exerciseLog.sets) {
        if (!setLog.isCompleted) continue;

        // Check max weight PR
        if (setLog.weight != null) {
          final currentPR = await getPersonalRecord(
            clientId: clientId,
            exerciseId: exerciseLog.exerciseId,
            recordType: 'max_weight',
          );

          if (currentPR == null || setLog.weight! > currentPR.value) {
            await _savePersonalRecord(
              clientId: clientId,
              exerciseId: exerciseLog.exerciseId,
              exerciseName: exerciseLog.exerciseName,
              recordType: 'max_weight',
              value: setLog.weight!,
              workoutLogId: workoutLogId,
            );
          }
        }

        // Check max reps PR
        if (setLog.reps != null) {
          final currentPR = await getPersonalRecord(
            clientId: clientId,
            exerciseId: exerciseLog.exerciseId,
            recordType: 'max_reps',
          );

          if (currentPR == null || setLog.reps! > currentPR.value) {
            await _savePersonalRecord(
              clientId: clientId,
              exerciseId: exerciseLog.exerciseId,
              exerciseName: exerciseLog.exerciseName,
              recordType: 'max_reps',
              value: setLog.reps!.toDouble(),
              workoutLogId: workoutLogId,
            );
          }
        }

        // Check max duration PR
        if (setLog.duration != null) {
          final currentPR = await getPersonalRecord(
            clientId: clientId,
            exerciseId: exerciseLog.exerciseId,
            recordType: 'max_duration',
          );

          if (currentPR == null || setLog.duration! > currentPR.value) {
            await _savePersonalRecord(
              clientId: clientId,
              exerciseId: exerciseLog.exerciseId,
              exerciseName: exerciseLog.exerciseName,
              recordType: 'max_duration',
              value: setLog.duration!.toDouble(),
              workoutLogId: workoutLogId,
            );
          }
        }
      }
    }
  }

  Future<void> _savePersonalRecord({
    required String clientId,
    required String exerciseId,
    required String exerciseName,
    required String recordType,
    required double value,
    required String workoutLogId,
  }) async {
    final pr = PersonalRecord(
      id: '',
      clientId: clientId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      recordType: recordType,
      value: value,
      achievedAt: DateTime.now(),
      workoutLogId: workoutLogId,
    );

    final prData = pr.toJson();
    prData.remove('id');

    // Check if PR already exists and update or create
    final existingPRs = await _firestore
        .collection('personalRecords')
        .where('clientId', isEqualTo: clientId)
        .where('exerciseId', isEqualTo: exerciseId)
        .where('recordType', isEqualTo: recordType)
        .get();

    if (existingPRs.docs.isNotEmpty) {
      await existingPRs.docs.first.reference.update({
        ...prData,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('personalRecords').add({
        ...prData,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogs(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('workoutLogs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('startedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapWorkoutLogFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get workout logs: $e');
    }
  }

  @override
  Future<WorkoutLog> getWorkoutLog(String workoutLogId) async {
    try {
      final doc = await _firestore.collection('workoutLogs').doc(workoutLogId).get();

      if (!doc.exists) {
        throw Exception('Workout log not found');
      }

      return _mapWorkoutLogFromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get workout log: $e');
    }
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsByWorkout({
    required String workoutId,
    required String clientId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('workoutLogs')
          .where('workoutId', isEqualTo: workoutId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('startedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapWorkoutLogFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get workout logs by workout: $e');
    }
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('personalRecords')
          .where('clientId', isEqualTo: clientId)
          .orderBy('achievedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PersonalRecord.fromJson({
          'id': doc.id,
          ...data,
          'achievedAt': (data['achievedAt'] as Timestamp).toDate(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get personal records: $e');
    }
  }

  @override
  Future<PersonalRecord?> getPersonalRecord({
    required String clientId,
    required String exerciseId,
    required String recordType,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('personalRecords')
          .where('clientId', isEqualTo: clientId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('recordType', isEqualTo: recordType)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return PersonalRecord.fromJson({
        'id': doc.id,
        ...data,
        'achievedAt': (data['achievedAt'] as Timestamp).toDate(),
      });
    } catch (e) {
      throw Exception('Failed to get personal record: $e');
    }
  }

  @override
  Stream<List<WorkoutLog>> watchWorkoutLogs(String clientId) {
    return _firestore
        .collection('workoutLogs')
        .where('clientId', isEqualTo: clientId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _mapWorkoutLogFromFirestore(doc.id, data);
            }).toList());
  }

  WorkoutLog _mapWorkoutLogFromFirestore(String id, Map<String, dynamic> data) {
    return WorkoutLog.fromJson({
      'id': id,
      'workoutId': data['workoutId'],
      'assignmentId': data['assignmentId'],
      'clientId': data['clientId'],
      'startedAt': (data['startedAt'] as Timestamp).toDate(),
      'completedAt': data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      'totalDuration': data['totalDuration'],
      'notes': data['notes'],
      'exerciseLogs': data['exerciseLogs'] ?? [],
      'createdAt': data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    });
  }
}

