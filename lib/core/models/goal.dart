import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

/// Goal type enum
@JsonEnum()
enum GoalType {
  @JsonValue('weight_loss')
  weightLoss,
  @JsonValue('weight_gain')
  weightGain,
  @JsonValue('muscle_gain')
  muscleGain,
  @JsonValue('body_fat_reduction')
  bodyFatReduction,
  @JsonValue('endurance')
  endurance,
  @JsonValue('strength')
  strength,
  @JsonValue('flexibility')
  flexibility,
  @JsonValue('water_intake')
  waterIntake,
  @JsonValue('steps')
  steps,
  @JsonValue('workout_completion')
  workoutCompletion,
  @JsonValue('custom')
  custom,
}

/// Goal status enum
@JsonEnum()
enum GoalStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('paused')
  paused,
  @JsonValue('cancelled')
  cancelled,
}

/// Goal model
@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String clientId,
    required String coachId,
    required String title,
    String? description,
    required GoalType type,
    required double targetValue,
    required String targetUnit, // 'kg', 'lbs', '%', 'steps', 'liters', etc.
    double? currentValue,
    required DateTime startDate,
    required DateTime targetDate,
    required GoalStatus status,
    double? progressPercentage, // 0-100
    List<GoalMilestone>? milestones,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}

/// Goal milestone model
@freezed
class GoalMilestone with _$GoalMilestone {
  const factory GoalMilestone({
    required String id,
    required String goalId,
    required String title,
    required double targetValue,
    required DateTime targetDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) = _GoalMilestone;

  factory GoalMilestone.fromJson(Map<String, dynamic> json) =>
      _$GoalMilestoneFromJson(json);
}

/// Goal progress log model (for tracking progress over time)
@freezed
class GoalProgressLog with _$GoalProgressLog {
  const factory GoalProgressLog({
    required String id,
    required String goalId,
    required double value,
    required DateTime loggedAt,
    String? notes,
  }) = _GoalProgressLog;

  factory GoalProgressLog.fromJson(Map<String, dynamic> json) =>
      _$GoalProgressLogFromJson(json);
}

