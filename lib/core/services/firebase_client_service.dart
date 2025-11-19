import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/client_coach_relationship.dart';
import '../models/progress.dart';
import '../models/workout.dart';
import '../repositories/client_repository.dart';
import 'firebase_user_service.dart';

/// Firebase implementation of ClientRepository
class FirebaseClientService implements ClientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseUserService _userService = FirebaseUserService();

  @override
  Future<List<User>> getClients(String coachId) async {
    try {
      debugPrint('🔍 Fetching clients for coach: $coachId');
      
      // Get all client-coach relationships for this coach
      debugPrint('📝 Querying clientCoachRelationships collection...');
      final relationshipsSnapshot = await _firestore
          .collection('clientCoachRelationships')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📊 Found ${relationshipsSnapshot.docs.length} relationships');

      final clientIds = relationshipsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('📝 Relationship doc: ${doc.id}, data: $data');
            return data['clientId'] as String?;
          })
          .whereType<String>()
          .toList();

      debugPrint('📊 Extracted ${clientIds.length} client IDs: $clientIds');

      if (clientIds.isEmpty) {
        debugPrint('⚠️⚠️⚠️ No client IDs found. Checking all relationships...');
        debugPrint('⚠️ Query was: coachId = "$coachId", status = "active"');
        
        // Debug: Check if there are any relationships at all
        final allRelationships = await _firestore
            .collection('clientCoachRelationships')
            .get();
        debugPrint('📊 Total relationships in collection: ${allRelationships.docs.length}');
        
        if (allRelationships.docs.isEmpty) {
          debugPrint('❌❌❌ NO RELATIONSHIPS FOUND IN COLLECTION!');
          debugPrint('❌ The clientCoachRelationships collection is empty.');
          debugPrint('❌ This means the relationship was not created when adding the client.');
        } else {
          debugPrint('📝 All relationships in database:');
          for (final doc in allRelationships.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final docCoachId = data['coachId']?.toString() ?? 'null';
            final docClientId = data['clientId']?.toString() ?? 'null';
            final docStatus = data['status']?.toString() ?? 'null';
            debugPrint('   📄 Doc ID: ${doc.id}');
            debugPrint('      coachId: "$docCoachId" (querying for: "$coachId")');
            debugPrint('      clientId: "$docClientId"');
            debugPrint('      status: "$docStatus" (querying for: "active")');
            
            // Check if coach ID matches
            if (docCoachId != coachId) {
              debugPrint('      ⚠️ COACH ID MISMATCH! Expected: "$coachId", Found: "$docCoachId"');
            }
            if (docStatus != 'active') {
              debugPrint('      ⚠️ STATUS MISMATCH! Expected: "active", Found: "$docStatus"');
            }
          }
        }
        return [];
      }

      // Fetch user data for each client
      final clients = <User>[];
      for (final clientId in clientIds) {
        try {
          debugPrint('📝 Fetching user data for client: $clientId');
          final client = await _userService.getUser(clientId);
          if (client != null) {
            debugPrint('✅ Found user: ${client.name} (${client.email}), role: ${client.role}');
            if (client.role == 'client') {
              clients.add(client);
              debugPrint('✅ Added client to list');
            } else {
              debugPrint('⚠️ User role is "${client.role}", not "client"');
            }
          } else {
            debugPrint('⚠️ User not found for ID: $clientId');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error fetching user $clientId: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          // Skip if user not found
          continue;
        }
      }

      debugPrint('✅ Returning ${clients.length} clients');
      return clients;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getClients: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to get clients: $e');
    }
  }

  @override
  Future<List<ClientCoachRelationship>> getClientRelationships(
      String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('clientCoachRelationships')
          .where('coachId', isEqualTo: coachId)
          .orderBy('joinedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ClientCoachRelationship.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get client relationships: $e');
    }
  }

  @override
  Future<void> addClient({
    required String coachId,
    required String clientId,
  }) async {
    try {
      // Check if relationship already exists
      final existing = await _firestore
          .collection('clientCoachRelationships')
          .where('coachId', isEqualTo: coachId)
          .where('clientId', isEqualTo: clientId)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing relationship to active
        await existing.docs.first.reference.update({
          'status': 'active',
          'joinedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Create new relationship
      final relationshipData = {
        'coachId': coachId,
        'clientId': clientId,
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('📝 Creating client-coach relationship');
      debugPrint('📝 Relationship data: $relationshipData');
      
      final docRef = await _firestore.collection('clientCoachRelationships').add(relationshipData);
      
      debugPrint('✅ Client-coach relationship created with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating client-coach relationship: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to add client: $e');
    }
  }

  @override
  Future<void> removeClient({
    required String coachId,
    required String clientId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('clientCoachRelationships')
          .where('coachId', isEqualTo: coachId)
          .where('clientId', isEqualTo: clientId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'status': 'inactive'});
      }
    } catch (e) {
      throw Exception('Failed to remove client: $e');
    }
  }

  @override
  Future<BodyComposition?> getLatestBodyComposition(String clientId) async {
    try {
      // Get latest weight
      final weightSnapshot = await _firestore
          .collection('weightLogs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('loggedAt', descending: true)
          .limit(1)
          .get();

      // Get latest body measurement
      final measurementSnapshot = await _firestore
          .collection('bodyMeasurements')
          .where('clientId', isEqualTo: clientId)
          .orderBy('measuredAt', descending: true)
          .limit(1)
          .get();

      double? weight;
      double? bodyFat;
      double? muscleMass;
      DateTime? lastUpdated;

      if (weightSnapshot.docs.isNotEmpty) {
        final weightData = weightSnapshot.docs.first.data() as Map<String, dynamic>;
        weight = (weightData['weight'] as num?)?.toDouble();
        final loggedAt = weightData['loggedAt'] as Timestamp?;
        if (loggedAt != null) {
          lastUpdated = loggedAt.toDate();
        }
      }

      if (measurementSnapshot.docs.isNotEmpty) {
        final measurementData = measurementSnapshot.docs.first.data() as Map<String, dynamic>;
        bodyFat = (measurementData['bodyFat'] as num?)?.toDouble();
        muscleMass = (measurementData['muscleMass'] as num?)?.toDouble();
        final measuredAt = measurementData['measuredAt'] as Timestamp?;
        if (measuredAt != null) {
          final measuredDate = measuredAt.toDate();
          if (lastUpdated == null || measuredDate.isAfter(lastUpdated)) {
            lastUpdated = measuredDate;
          }
        }
      }

      if (weight == null && bodyFat == null && muscleMass == null) {
        return null;
      }

      return BodyComposition(
        weight: weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      throw Exception('Failed to get body composition: $e');
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
              'takenAt': (data['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get progress photos: $e');
    }
  }

  @override
  Future<List<WorkoutAssignment>> getClientWorkoutProgress(
      String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('workoutAssignments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('assignedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cleanData = Map<String, dynamic>.from(data);
            cleanData.remove('coachId');
            return WorkoutAssignment.fromJson({
              'id': doc.id,
              ...cleanData,
              'assignedDate': (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get workout progress: $e');
    }
  }

  @override
  Future<List<WaterLog>> getClientWaterLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('waterLogs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(30).get(); // Last 30 days

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return WaterLog.fromJson({
              'id': doc.id,
              ...data,
              'loggedAt': (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get water logs: $e');
    }
  }

  @override
  Future<List<StepLog>> getClientStepLogs({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('stepLogs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(30).get(); // Last 30 days

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return StepLog.fromJson({
              'id': doc.id,
              ...data,
              'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get step logs: $e');
    }
  }
}

