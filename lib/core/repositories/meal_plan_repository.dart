import '../models/meal_plan.dart';

/// Abstract repository interface for meal plan management
/// This abstraction allows switching between Firebase and Node.js backends
abstract class MealPlanRepository {
  // Ingredients
  /// Get all ingredients for a coach
  Future<List<Ingredient>> getIngredients(String coachId);

  /// Get a single ingredient by ID
  Future<Ingredient> getIngredientById(String ingredientId);

  /// Create a new ingredient
  Future<Ingredient> createIngredient(Ingredient ingredient);

  /// Update an existing ingredient
  Future<Ingredient> updateIngredient(Ingredient ingredient);

  /// Delete an ingredient
  Future<void> deleteIngredient(String ingredientId);

  // Meal Plans
  /// Get all meal plans for a coach
  Future<List<MealPlan>> getMealPlans(String coachId);

  /// Get a single meal plan by ID
  Future<MealPlan> getMealPlanById(String mealPlanId);

  /// Create a new meal plan
  Future<MealPlan> createMealPlan(MealPlan mealPlan);

  /// Update an existing meal plan
  Future<MealPlan> updateMealPlan(MealPlan mealPlan);

  /// Delete a meal plan
  Future<void> deleteMealPlan(String mealPlanId);

  // Cooking Videos
  /// Get all cooking videos for a coach
  Future<List<CookingVideo>> getCookingVideos(String coachId);

  /// Get a single cooking video by ID
  Future<CookingVideo> getCookingVideoById(String videoId);

  /// Create a new cooking video
  Future<CookingVideo> createCookingVideo(CookingVideo video);

  /// Update an existing cooking video
  Future<CookingVideo> updateCookingVideo(CookingVideo video);

  /// Delete a cooking video
  Future<void> deleteCookingVideo(String videoId);

  // Real-time streams
  /// Watch ingredients in real-time
  Stream<List<Ingredient>> watchIngredients(String coachId);

  /// Watch meal plans in real-time
  Stream<List<MealPlan>> watchMealPlans(String coachId);

  /// Watch cooking videos in real-time
  Stream<List<CookingVideo>> watchCookingVideos(String coachId);

  // Meal Plan Assignments
  /// Assign a meal plan to a client
  Future<MealPlanAssignment> assignMealPlan({
    required String mealPlanId,
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get assigned meal plans for a client
  Future<List<MealPlanAssignment>> getAssignedMealPlans(String clientId);

  /// Get all meal plan assignments for a coach
  Future<List<MealPlanAssignment>> getMealPlanAssignments(String coachId);

  /// Update meal plan assignment status
  Future<MealPlanAssignment> updateMealPlanAssignmentStatus({
    required String assignmentId,
    required String status,
  });

  /// Delete a meal plan assignment
  Future<void> deleteMealPlanAssignment(String assignmentId);
}

