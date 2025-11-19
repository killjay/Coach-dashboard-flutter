import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan.dart' show MealPlan, Meal, Ingredient, IngredientUsage, CookingVideo, MacroNutrients, MealPlanAssignment;
import '../repositories/meal_plan_repository.dart';

/// Firebase implementation of MealPlanRepository
class FirebaseMealPlanService implements MealPlanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ingredients

  @override
  Future<List<Ingredient>> getIngredients(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('ingredients')
          .where('coachId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Ingredient.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get ingredients: $e');
    }
  }

  @override
  Future<Ingredient> getIngredientById(String ingredientId) async {
    try {
      final doc =
          await _firestore.collection('ingredients').doc(ingredientId).get();

      if (!doc.exists) {
        throw Exception('Ingredient not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Ingredient data is null');
      }
      return Ingredient.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get ingredient: $e');
    }
  }

  @override
  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    try {
      final docRef = _firestore.collection('ingredients').doc();

      final ingredientData = ingredient.toJson();
      ingredientData.remove('id');

      await docRef.set({
        ...ingredientData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ingredient.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create ingredient: $e');
    }
  }

  @override
  Future<Ingredient> updateIngredient(Ingredient ingredient) async {
    try {
      final ingredientData = ingredient.toJson();
      ingredientData.remove('id');

      await _firestore
          .collection('ingredients')
          .doc(ingredient.id)
          .update(ingredientData);

      return ingredient;
    } catch (e) {
      throw Exception('Failed to update ingredient: $e');
    }
  }

  @override
  Future<void> deleteIngredient(String ingredientId) async {
    try {
      await _firestore.collection('ingredients').doc(ingredientId).delete();
    } catch (e) {
      throw Exception('Failed to delete ingredient: $e');
    }
  }

  // Meal Plans

  @override
  Future<List<MealPlan>> getMealPlans(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('mealPlans')
          .where('coachId', isEqualTo: coachId)
          .where('category', isEqualTo: 'meal_plan')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return MealPlan.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get meal plans: $e');
    }
  }

  @override
  Future<MealPlan> getMealPlanById(String mealPlanId) async {
    try {
      final doc =
          await _firestore.collection('mealPlans').doc(mealPlanId).get();

      if (!doc.exists) {
        throw Exception('Meal plan not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Meal plan data is null');
      }
      return MealPlan.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get meal plan: $e');
    }
  }

  @override
  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    try {
      final docRef = _firestore.collection('mealPlans').doc();

      final mealPlanData = mealPlan.toJson();
      mealPlanData.remove('id');

      await docRef.set({
        ...mealPlanData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return mealPlan.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create meal plan: $e');
    }
  }

  @override
  Future<MealPlan> updateMealPlan(MealPlan mealPlan) async {
    try {
      final mealPlanData = mealPlan.toJson();
      mealPlanData.remove('id');

      await _firestore
          .collection('mealPlans')
          .doc(mealPlan.id)
          .update(mealPlanData);

      return mealPlan;
    } catch (e) {
      throw Exception('Failed to update meal plan: $e');
    }
  }

  @override
  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _firestore.collection('mealPlans').doc(mealPlanId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal plan: $e');
    }
  }

  // Cooking Videos

  @override
  Future<List<CookingVideo>> getCookingVideos(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('cookingVideos')
          .where('coachId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return CookingVideo.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get cooking videos: $e');
    }
  }

  @override
  Future<CookingVideo> getCookingVideoById(String videoId) async {
    try {
      final doc =
          await _firestore.collection('cookingVideos').doc(videoId).get();

      if (!doc.exists) {
        throw Exception('Cooking video not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Cooking video data is null');
      }
      return CookingVideo.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get cooking video: $e');
    }
  }

  @override
  Future<CookingVideo> createCookingVideo(CookingVideo video) async {
    try {
      final docRef = _firestore.collection('cookingVideos').doc();

      final videoData = video.toJson();
      videoData.remove('id');

      await docRef.set({
        ...videoData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return video.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create cooking video: $e');
    }
  }

  @override
  Future<CookingVideo> updateCookingVideo(CookingVideo video) async {
    try {
      final videoData = video.toJson();
      videoData.remove('id');

      await _firestore
          .collection('cookingVideos')
          .doc(video.id)
          .update(videoData);

      return video;
    } catch (e) {
      throw Exception('Failed to update cooking video: $e');
    }
  }

  @override
  Future<void> deleteCookingVideo(String videoId) async {
    try {
      await _firestore.collection('cookingVideos').doc(videoId).delete();
    } catch (e) {
      throw Exception('Failed to delete cooking video: $e');
    }
  }

  // Real-time streams

  @override
  Stream<List<Ingredient>> watchIngredients(String coachId) {
    return _firestore
        .collection('ingredients')
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Ingredient.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  @override
  Stream<List<MealPlan>> watchMealPlans(String coachId) {
    return _firestore
        .collection('mealPlans')
        .where('coachId', isEqualTo: coachId)
        .where('category', isEqualTo: 'meal_plan')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return MealPlan.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  @override
  Stream<List<CookingVideo>> watchCookingVideos(String coachId) {
    return _firestore
        .collection('cookingVideos')
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CookingVideo.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  @override
  Future<MealPlanAssignment> assignMealPlan({
    required String mealPlanId,
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get meal plan to get coachId
      final mealPlan = await getMealPlanById(mealPlanId);

      final assignment = MealPlanAssignment(
        id: '',
        mealPlanId: mealPlanId,
        clientId: clientId,
        assignedDate: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        status: 'pending',
      );

      final assignmentData = assignment.toJson();
      assignmentData.remove('id');

      final docRef = await _firestore.collection('mealPlanAssignments').add({
        ...assignmentData,
        'coachId': mealPlan.coachId,
        'assignedDate': FieldValue.serverTimestamp(),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
      });

      return assignment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to assign meal plan: $e');
    }
  }

  @override
  Future<List<MealPlanAssignment>> getAssignedMealPlans(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('mealPlanAssignments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('assignedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return MealPlanAssignment.fromJson({
              'id': doc.id,
              ...data,
              'assignedDate': (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get assigned meal plans: $e');
    }
  }

  @override
  Future<List<MealPlanAssignment>> getMealPlanAssignments(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('mealPlanAssignments')
          .where('coachId', isEqualTo: coachId)
          .orderBy('assignedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return MealPlanAssignment.fromJson({
              'id': doc.id,
              ...data,
              'assignedDate': (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get meal plan assignments: $e');
    }
  }

  @override
  Future<MealPlanAssignment> updateMealPlanAssignmentStatus({
    required String assignmentId,
    required String status,
  }) async {
    try {
      final doc = await _firestore
          .collection('mealPlanAssignments')
          .doc(assignmentId)
          .get();

      if (!doc.exists) {
        throw Exception('Assignment not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final assignment = MealPlanAssignment.fromJson({
        'id': doc.id,
        ...data,
        'assignedDate': (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
      });

      final updatedAssignment = assignment.copyWith(
        status: status,
        completedAt: status == 'completed' ? DateTime.now() : null,
      );

      await _firestore
          .collection('mealPlanAssignments')
          .doc(assignmentId)
          .update({
        'status': status,
        if (status == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });

      return updatedAssignment;
    } catch (e) {
      throw Exception('Failed to update meal plan assignment: $e');
    }
  }

  @override
  Future<void> deleteMealPlanAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('mealPlanAssignments')
          .doc(assignmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete meal plan assignment: $e');
    }
  }
}

