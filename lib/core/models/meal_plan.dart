import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_plan.freezed.dart';
part 'meal_plan.g.dart';

/// Meal plan model
@freezed
class MealPlan with _$MealPlan {
  const factory MealPlan({
    required String id,
    required String coachId,
    required String name,
    String? description,
    required String category, // 'meal_plan', 'ingredient', 'cooking_video'
    required List<Meal> meals,
    required int duration, // in days
    required int totalCalories,
    required MacroNutrients macros,
    DateTime? createdAt,
  }) = _MealPlan;

  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      _$MealPlanFromJson(json);
}

/// Cooking video model
@freezed
class CookingVideo with _$CookingVideo {
  const factory CookingVideo({
    required String id,
    required String coachId,
    required String title,
    String? description,
    required String videoUrl, // YouTube link or uploaded video URL
    String? thumbnailUrl,
    List<String>? tags,
    DateTime? createdAt,
  }) = _CookingVideo;

  factory CookingVideo.fromJson(Map<String, dynamic> json) =>
      _$CookingVideoFromJson(json);
}

/// Meal model
@freezed
class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String name,
    required String type, // 'breakfast', 'lunch', 'dinner', 'snack'
    String? description,
    required List<IngredientUsage> ingredients,
    String? recipe,
    String? imageUrl,
    required int calories,
    required MacroNutrients macros,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}

/// Ingredient model (standalone ingredient with nutritional info)
@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,
    required String coachId,
    required String name,
    required double quantity, // per 100g or per unit
    required String unit, // 'g', 'ml', 'pieces', etc.
    required int calories, // per quantity
    required double protein, // in grams per quantity
    required double carbs, // in grams per quantity
    required double fats, // in grams per quantity
    String? description,
    DateTime? createdAt,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

/// Ingredient usage in a meal (references an ingredient with specific quantity)
@freezed
class IngredientUsage with _$IngredientUsage {
  const factory IngredientUsage({
    required String ingredientId,
    required double quantity,
    required String unit, // 'g', 'ml', 'pieces', etc.
  }) = _IngredientUsage;

  factory IngredientUsage.fromJson(Map<String, dynamic> json) =>
      _$IngredientUsageFromJson(json);
}

/// Meal plan assignment model
@freezed
class MealPlanAssignment with _$MealPlanAssignment {
  const factory MealPlanAssignment({
    required String id,
    required String mealPlanId,
    required String clientId,
    required DateTime assignedDate,
    required DateTime startDate,
    required DateTime endDate,
    required String status, // 'pending', 'active', 'completed', 'cancelled'
    DateTime? completedAt,
  }) = _MealPlanAssignment;

  factory MealPlanAssignment.fromJson(Map<String, dynamic> json) =>
      _$MealPlanAssignmentFromJson(json);
}

/// Macro nutrients model
@freezed
class MacroNutrients with _$MacroNutrients {
  const factory MacroNutrients({
    required double protein, // in grams
    required double carbs, // in grams
    required double fats, // in grams
  }) = _MacroNutrients;

  factory MacroNutrients.fromJson(Map<String, dynamic> json) =>
      _$MacroNutrientsFromJson(json);
}

/// Meal completion model - tracks when a client completes a meal
@freezed
class MealCompletion with _$MealCompletion {
  const factory MealCompletion({
    required String id,
    required String mealPlanId,
    required String assignmentId,
    required String mealId,
    required String clientId,
    required DateTime date, // Date of the meal
    required DateTime completedAt,
    String? notes,
    double? rating, // Optional rating (1-5 stars)
  }) = _MealCompletion;

  factory MealCompletion.fromJson(Map<String, dynamic> json) =>
      _$MealCompletionFromJson(json);
}


