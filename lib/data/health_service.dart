import 'dart:io';

import 'package:health/health.dart';

import 'health_models.dart';

class HealthService {
  HealthService._();

  static final HealthService instance = HealthService._();

  final Health _health = Health();

  bool _configured = false;
  bool _authorized = false;

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED, // Added basal (resting) calories

    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,

    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_AWAKE,

    HealthDataType.FLIGHTS_CLIMBED,

    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BLOOD_OXYGEN,

    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,

    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  ];

  Future<void> configure() async {
    if (_configured) return;

    await _health.configure();

    _configured = true;
  }

  Future<bool> requestAuthorization() async {
    await configure();

    try {
      _authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      return _authorized;
    } catch (_) {
      _authorized = false;
      return false;
    }
  }

  Future<ArcHealthData> fetchToday() async {
    await configure();

    if (!_authorized) {
      final authorized = await requestAuthorization();

      if (!authorized) {
        return const ArcHealthData();
      }
    }

    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );

      print('DEBUG: Fetched ${points.length} health data points');
      for (var type in _types) {
        final count = points.where((p) => p.type == type).length;
        if (count > 0) print('DEBUG: Found $count points for $type');
      }

      final uniquePoints = _health.removeDuplicates(points);

      return _buildData(uniquePoints);
    } catch (_) {
      return const ArcHealthData();
    }
  }

  ArcHealthData _buildData(
    List<HealthDataPoint> points,
  ) {
    double sum(HealthDataType type) {
      return points
          .where((p) => p.type == type)
          .map(_numericValue)
          .fold(0.0, (a, b) => a + b);
    }

    double? latest(HealthDataType type) {
      final matching = points
          .where((p) => p.type == type)
          .toList()
        ..sort(
          (a, b) => b.dateTo.compareTo(a.dateTo),
        );

      if (matching.isEmpty) return null;

      return _numericValue(matching.first);
    }

    Duration durationFor(HealthDataType type) {
      final minutes = points
          .where((p) => p.type == type)
          .fold<double>(
            0,
            (total, point) {
              final value = _numericValue(point);

              // Sleep and exercise values are represented in minutes.
              if (value > 0) {
                return total + value;
              }

              return total +
                  point.dateTo
                      .difference(point.dateFrom)
                      .inSeconds /
                      60.0;
            },
          );

      return Duration(
        seconds: (minutes * 60).round(),
      );
    }

    final heartRates = points
        .where(
          (p) => p.type == HealthDataType.HEART_RATE,
        )
        .map(_numericValue)
        .where((v) => v > 0)
        .toList();

    final averageHeartRate = heartRates.isEmpty
        ? null
        : heartRates.reduce((a, b) => a + b) /
            heartRates.length;

    final hrv = latest(
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    );

    return ArcHealthData(
      steps: sum(HealthDataType.STEPS).round(),

      distanceKm:0,

      activeCalories:
          sum(HealthDataType.ACTIVE_ENERGY_BURNED),

      totalCalories:
          sum(HealthDataType.TOTAL_CALORIES_BURNED),

      sleep: durationFor(
        HealthDataType.SLEEP_ASLEEP,
      ),

      deepSleep: durationFor(
        HealthDataType.SLEEP_DEEP,
      ),

      remSleep: durationFor(
        HealthDataType.SLEEP_REM,
      ),

      lightSleep: durationFor(
        HealthDataType.SLEEP_LIGHT,
      ),

      awakeSleep: durationFor(
        HealthDataType.SLEEP_AWAKE,
      ),

      heartRate: averageHeartRate?.round(),

      restingHeartRate:
          latest(HealthDataType.RESTING_HEART_RATE)
              ?.round(),

      exercise: Duration.zero,

      flightsClimbed:
          sum(HealthDataType.FLIGHTS_CLIMBED).round(),

      respiratoryRate:
          latest(HealthDataType.RESPIRATORY_RATE),

      bloodOxygen:
          latest(HealthDataType.BLOOD_OXYGEN),

      weightKg:
          latest(HealthDataType.WEIGHT),

      bodyFatPercentage:
          latest(HealthDataType.BODY_FAT_PERCENTAGE),

      hrvMs: hrv,
    );
  }

  double _numericValue(HealthDataPoint point) {
    final value = point.value;

    if (value is NumericHealthValue) {
      final val = value.numericValue.toDouble();
      // Debug print for calories to see what we're getting
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        print('DEBUG: Active Calorie point: $val ${point.unit}');
      }
      return val;
    }

    return 0;
  }

  Future<bool> isAvailable() async {
    try {
      await configure();

      if (Platform.isAndroid) {
        final status =
            await _health.getHealthConnectSdkStatus();

        return status != null;
      }

      if (Platform.isIOS) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}