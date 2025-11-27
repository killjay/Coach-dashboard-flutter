import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/progress.dart';
import '../repositories/progress_repository.dart';

/// Firebase implementation of ProgressRepository
class FirebaseProgressService implements ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Water tracking

  @override
  Future<WaterLog> logWater({
    required String clientId,
    required double amount,
    DateTime? loggedAt,
  }) async {
    try {
      final log = WaterLog(
        id: '', // Will be set by Firestore
        clientId: clientId,
        amount: amount,
        loggedAt: loggedAt ?? DateTime.now(),
        date: DateTime.now(),
      );

      final logData = log.toJson();
      logData.remove('id');

      final docRef = await _firestore.collection('waterLogs').add({
        ...logData,
        'loggedAt': FieldValue.serverTimestamp(),
        'date': Timestamp.fromDate(log.date),
      });

      return log.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log water: $e');
    }
  }

  @override
  Future<List<WaterLog>> getWaterLogs({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('waterLogs')
          .where('clientId', isEqualTo: clientId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return WaterLog.fromJson({
              'id': doc.id,
              ...data,
              'loggedAt': (data['loggedAt'] as Timestamp?)?.toDate(),
              'date': (data['date'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get water logs: $e');
    }
  }

  @override
  Future<double> getDailyWaterTotal(String clientId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logs = await getWaterLogs(
        clientId: clientId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      double total = 0.0;
      for (final log in logs) {
        total += log.amount;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get daily water total: $e');
    }
  }

  // Step tracking

  @override
  Future<StepLog> logSteps({
    required String clientId,
    required int steps,
    required String source,
    DateTime? date,
  }) async {
    try {
      final logDate = date ?? DateTime.now();
      final log = StepLog(
        id: '', // Will be set by Firestore
        clientId: clientId,
        steps: steps,
        date: logDate,
        source: source,
      );

      final logData = log.toJson();
      logData.remove('id');

      final docRef = await _firestore.collection('stepLogs').add({
        ...logData,
        'date': Timestamp.fromDate(logDate),
      });

      return log.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log steps: $e');
    }
  }

  @override
  Future<List<StepLog>> getStepLogs({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('stepLogs')
          .where('clientId', isEqualTo: clientId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return StepLog.fromJson({
              'id': doc.id,
              ...data,
              'date': (data['date'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get step logs: $e');
    }
  }

  @override
  Future<int> getDailyStepTotal(String clientId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logs = await getStepLogs(
        clientId: clientId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      int total = 0;
      for (final log in logs) {
        total += log.steps;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get daily step total: $e');
    }
  }

  // Weight tracking

  @override
  Future<WeightLog> logWeight({
    required String clientId,
    required double weight,
    DateTime? loggedAt,
  }) async {
    try {
      final log = WeightLog(
        id: '', // Will be set by Firestore
        clientId: clientId,
        weight: weight,
        loggedAt: loggedAt ?? DateTime.now(),
      );

      final logData = log.toJson();
      logData.remove('id');

      final docRef = await _firestore.collection('weightLogs').add({
        ...logData,
        'loggedAt': FieldValue.serverTimestamp(),
      });

      return log.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log weight: $e');
    }
  }

  @override
  Future<List<WeightLog>> getWeightLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('weightLogs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('loggedAt', descending: true);

      if (startDate != null) {
        query = query.where('loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('loggedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return WeightLog.fromJson({
              'id': doc.id,
              ...data,
              'loggedAt': (data['loggedAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get weight logs: $e');
    }
  }

  // Body measurements

  @override
  Future<BodyMeasurement> logBodyMeasurement({
    required String clientId,
    double? chest,
    double? waist,
    double? hips,
    double? arms,
    double? thighs,
    double? bodyFat,
    double? muscleMass,
    DateTime? measuredAt,
  }) async {
    try {
      final measurement = BodyMeasurement(
        id: '', // Will be set by Firestore
        clientId: clientId,
        chest: chest,
        waist: waist,
        hips: hips,
        arms: arms,
        thighs: thighs,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        measuredAt: measuredAt ?? DateTime.now(),
      );

      final measurementData = measurement.toJson();
      measurementData.remove('id');

      final docRef = await _firestore.collection('bodyMeasurements').add({
        ...measurementData,
        'measuredAt': FieldValue.serverTimestamp(),
      });

      return measurement.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log body measurement: $e');
    }
  }

  @override
  Future<List<BodyMeasurement>> getBodyMeasurements({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('bodyMeasurements')
          .where('clientId', isEqualTo: clientId)
          .orderBy('measuredAt', descending: true);

      if (startDate != null) {
        query = query.where('measuredAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('measuredAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return BodyMeasurement.fromJson({
              'id': doc.id,
              ...data,
              'measuredAt': (data['measuredAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get body measurements: $e');
    }
  }

  // Progress photos

  @override
  Future<ProgressPhoto> uploadProgressPhoto({
    required String clientId,
    String? imagePath, // No longer used, but kept for interface compatibility
    Uint8List? imageBytes,
    String? notes,
  }) async {
    debugPrint('🔥 [FirebaseProgressService] uploadProgressPhoto called');
    debugPrint('🔥 [FirebaseProgressService] Client ID: $clientId');
    
    try {
      // Validate that bytes are provided
      if (imageBytes == null) {
        throw Exception('imageBytes is required. The UI layer should read bytes from XFile using readAsBytes()');
      }
      
      debugPrint('🔥 [FirebaseProgressService] Bytes received: ${imageBytes.length} bytes');
      
      // Create storage reference with organized path structure
      // Use ISO8601 string for better file organization
      final storageRef = _storage
          .ref()
          .child('users/$clientId/progress/${DateTime.now().toIso8601String()}.jpg');
      
      debugPrint('🔥 [FirebaseProgressService] Storage path: users/$clientId/progress/...');
      
      // USE putData INSTEAD OF putFile
      // putData works with Uint8List on both Web and Mobile
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );
      
      debugPrint('🔥 [FirebaseProgressService] Uploading to Firebase Storage...');
      await storageRef.putData(imageBytes, metadata);
      debugPrint('✅ [FirebaseProgressService] Upload completed successfully');
      
      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();
      debugPrint('✅ [FirebaseProgressService] Download URL obtained');

      debugPrint('🔥 [FirebaseProgressService] Creating ProgressPhoto object...');
      // Save photo metadata to Firestore
      final photo = ProgressPhoto(
        id: '', // Will be set by Firestore
        clientId: clientId,
        imageUrl: imageUrl,
        takenAt: DateTime.now(),
        notes: notes,
      );

      debugPrint('🔥 [FirebaseProgressService] Saving metadata to Firestore...');
      final photoData = photo.toJson();
      photoData.remove('id');

      final docRef = await _firestore.collection('progressPhotos').add({
        ...photoData,
        'takenAt': FieldValue.serverTimestamp(),
      });

      final result = photo.copyWith(id: docRef.id);
      debugPrint('✅ [FirebaseProgressService] Upload process completed successfully!');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [FirebaseProgressService] Error: $e');
      debugPrint('❌ [FirebaseProgressService] Stack trace: $stackTrace');
      throw Exception('Failed to upload progress photo: $e');
    }
  }

  @override
  Future<List<ProgressPhoto>> getProgressPhotos({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('progressPhotos')
          .where('clientId', isEqualTo: clientId)
          .orderBy('takenAt', descending: true);

      if (startDate != null) {
        query = query.where('takenAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('takenAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ProgressPhoto.fromJson({
              'id': doc.id,
              ...data,
              'takenAt': (data['takenAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get progress photos: $e');
    }
  }

  @override
  Future<void> deleteProgressPhoto(String photoId) async {
    try {
      // Get photo to get image URL
      final doc = await _firestore
          .collection('progressPhotos')
          .doc(photoId)
          .get();

      if (!doc.exists) {
        throw Exception('Progress photo not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final imageUrl = data['imageUrl'] as String;

      // Delete from Storage
      await _storage.refFromURL(imageUrl).delete();

      // Delete from Firestore
      await _firestore.collection('progressPhotos').doc(photoId).delete();
    } catch (e) {
      throw Exception('Failed to delete progress photo: $e');
    }
  }

  // Real-time streams

  @override
  Stream<List<WaterLog>> watchWaterLogs(String clientId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('waterLogs')
        .where('clientId', isEqualTo: clientId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return WaterLog.fromJson({
                'id': doc.id,
                ...data,
                'loggedAt': (data['loggedAt'] as Timestamp?)?.toDate(),
                'date': (data['date'] as Timestamp?)?.toDate(),
              });
            })
            .toList());
  }

  @override
  Stream<List<StepLog>> watchStepLogs(String clientId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('stepLogs')
        .where('clientId', isEqualTo: clientId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return StepLog.fromJson({
                'id': doc.id,
                ...data,
                'date': (data['date'] as Timestamp?)?.toDate(),
              });
            })
            .toList());
  }
}

