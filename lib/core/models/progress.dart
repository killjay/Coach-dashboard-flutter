import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

/// Water log model
@freezed
class WaterLog with _$WaterLog {
  const factory WaterLog({
    required String id,
    required String clientId,
    required double amount, // in ml
    required DateTime loggedAt,
    required DateTime date,
  }) = _WaterLog;

  factory WaterLog.fromJson(Map<String, dynamic> json) =>
      _$WaterLogFromJson(json);
}

/// Step log model
@freezed
class StepLog with _$StepLog {
  const factory StepLog({
    required String id,
    required String clientId,
    required int steps,
    required DateTime date,
    required String source, // 'healthkit', 'google_fit', 'manual'
  }) = _StepLog;

  factory StepLog.fromJson(Map<String, dynamic> json) =>
      _$StepLogFromJson(json);
}

/// Weight log model
@freezed
class WeightLog with _$WeightLog {
  const factory WeightLog({
    required String id,
    required String clientId,
    required double weight, // in kg
    required DateTime loggedAt,
  }) = _WeightLog;

  factory WeightLog.fromJson(Map<String, dynamic> json) =>
      _$WeightLogFromJson(json);
}

/// Body measurement model
@freezed
class BodyMeasurement with _$BodyMeasurement {
  const factory BodyMeasurement({
    required String id,
    required String clientId,
    double? chest, // in cm
    double? waist, // in cm
    double? hips, // in cm
    double? arms, // in cm
    double? thighs, // in cm
    double? bodyFat, // in percentage
    double? muscleMass, // in kg
    required DateTime measuredAt,
  }) = _BodyMeasurement;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      _$BodyMeasurementFromJson(json);
}

/// Progress photo model
@freezed
class ProgressPhoto with _$ProgressPhoto {
  const factory ProgressPhoto({
    required String id,
    required String clientId,
    required String imageUrl,
    required DateTime takenAt,
    String? notes,
  }) = _ProgressPhoto;

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) =>
      _$ProgressPhotoFromJson(json);
}


