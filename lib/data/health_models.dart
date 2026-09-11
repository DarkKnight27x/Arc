import 'package:flutter/foundation.dart';

@immutable
class ArcHealthData {
  const ArcHealthData({
    this.steps = 0,
    this.distanceKm = 0,
    this.activeCalories = 0,
    this.totalCalories = 0,
    this.sleep = Duration.zero,
    this.deepSleep = Duration.zero,
    this.remSleep = Duration.zero,
    this.lightSleep = Duration.zero,
    this.awakeSleep = Duration.zero,
    this.heartRate,
    this.restingHeartRate,
    this.exercise = Duration.zero,
    this.flightsClimbed = 0,
    this.respiratoryRate,
    this.bloodOxygen,
    this.weightKg,
    this.bodyFatPercentage,
    this.hrvMs,
  });

  final int steps;
  final double distanceKm;
  final double activeCalories;
  final double totalCalories;

  final Duration sleep;
  final Duration deepSleep;
  final Duration remSleep;
  final Duration lightSleep;
  final Duration awakeSleep;

  final int? heartRate;
  final int? restingHeartRate;

  final Duration exercise;

  final int flightsClimbed;

  final double? respiratoryRate;
  final double? bloodOxygen;

  final double? weightKg;
  final double? bodyFatPercentage;
  final double? hrvMs;

  double get sleepHours => sleep.inMinutes / 60.0;

  double get sleepScore {
    if (sleep.inMinutes <= 0) return 0;

    // Simple baseline score for now.
    // Later we can make this a proper recovery score.
    final hours = sleep.inMinutes / 60.0;

    if (hours >= 8) return 1.0;
    if (hours >= 7) return 0.9;
    if (hours >= 6) return 0.75;
    if (hours >= 5) return 0.55;
    return 0.35;
  }

  ArcHealthData copyWith({
    int? steps,
    double? distanceKm,
    double? activeCalories,
    double? totalCalories,
    Duration? sleep,
    Duration? deepSleep,
    Duration? remSleep,
    Duration? lightSleep,
    Duration? awakeSleep,
    int? heartRate,
    int? restingHeartRate,
    Duration? exercise,
    int? flightsClimbed,
    double? respiratoryRate,
    double? bloodOxygen,
    double? weightKg,
    double? bodyFatPercentage,
    double? hrvMs,
  }) {
    return ArcHealthData(
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      activeCalories: activeCalories ?? this.activeCalories,
      totalCalories: totalCalories ?? this.totalCalories,
      sleep: sleep ?? this.sleep,
      deepSleep: deepSleep ?? this.deepSleep,
      remSleep: remSleep ?? this.remSleep,
      lightSleep: lightSleep ?? this.lightSleep,
      awakeSleep: awakeSleep ?? this.awakeSleep,
      heartRate: heartRate ?? this.heartRate,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      exercise: exercise ?? this.exercise,
      flightsClimbed: flightsClimbed ?? this.flightsClimbed,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      bloodOxygen: bloodOxygen ?? this.bloodOxygen,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage:
          bodyFatPercentage ?? this.bodyFatPercentage,
      hrvMs: hrvMs ?? this.hrvMs,
    );
  }
}