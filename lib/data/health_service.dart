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
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.WORKOUT,

    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,

    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_SESSION,

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
      print('DEBUG: Requesting health permissions for ${_types.length} types...');
      _authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      print('DEBUG: Authorization result: $_authorized');
      return _authorized;
    } catch (e) {
      print('DEBUG: Authorization error: $e');
      _authorized = false;
      return false;
    }
  }

  Future<ArcHealthData> fetchToday() async {
    await configure();

    if (!_authorized) {
      final authorized = await requestAuthorization();
      if (!authorized) return const ArcHealthData();
    }

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final yesterday = now.subtract(const Duration(hours: 24));
    final monthAgo = now.subtract(const Duration(days: 30));

    List<HealthDataPoint> allPoints = [];

    // Helper to fetch and catch errors for specific lists
    Future<void> safeFetch(DateTime start, DateTime end, List<HealthDataType> types) async {
      try {
        final pts = await _health.getHealthDataFromTypes(
          startTime: start,
          endTime: end,
          types: types,
        );
        allPoints.addAll(pts);
      } catch (e) {
        print('DEBUG: SafeFetch error for types $types: $e');
      }
    }

    try {
      // 1. Fetch Today's Activity
      await safeFetch(midnight, now, [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.FLIGHTS_CLIMBED,
      ]);

      // 2. Fetch Sleep & Vitals (24h lookback)
      await safeFetch(yesterday, now, [
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      ]);

      // 3. Fetch Biometrics (30d lookback)
      await safeFetch(monthAgo, now, [
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.HEIGHT,
      ]);

      int? totalSteps;
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          totalSteps = await _health.getTotalStepsInInterval(midnight, now);
        }
      } catch (_) {}

      print('DEBUG: Fetched ${allPoints.length} total data points');
      
      final typeCounts = <String, int>{};
      for (var p in allPoints) {
        final typeName = p.type.toString().split('.').last;
        typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
      }
      print('DEBUG: TYPE COUNTS -> $typeCounts');

      final sourceCounts = <String, int>{};
      for (var p in allPoints) {
        final source = p.sourceId;
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }
      print('DEBUG: SOURCE COUNTS -> $sourceCounts');
      
      final uniquePoints = _health.removeDuplicates(allPoints);
      return _buildData(uniquePoints, totalSteps);
    } catch (e) {
      print('DEBUG: Master health fetch error: $e');
      return const ArcHealthData();
    }
  }

  ArcHealthData _buildData(
    List<HealthDataPoint> points,
    int? platformSteps,
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
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

      if (matching.isEmpty) return null;
      return _numericValue(matching.first);
    }

    Duration durationFor(HealthDataType type) {
      final relevant = points.where((p) => p.type == type).toList();
      int totalMs = 0;
      for (var p in relevant) {
        // Method 1: Use the numeric value if it's already in minutes/seconds
        final val = _numericValue(p);
        if (val > 0) {
          // If the unit is minutes, convert to ms
          if (p.unit == HealthDataUnit.MINUTE) {
            totalMs += (val * 60000).round();
            continue;
          }
        }
        // Method 2: Calculate from interval
        totalMs += p.dateTo.difference(p.dateFrom).inMilliseconds;
      }
      return Duration(milliseconds: totalMs);
    }

    final heartRates = points
        .where((p) => p.type == HealthDataType.HEART_RATE)
        .map(_numericValue)
        .where((v) => v > 0)
        .toList();

    final averageHeartRate = heartRates.isEmpty
        ? null
        : heartRates.reduce((a, b) => a + b) / heartRates.length;

    // Steps: Use platform-deduplicated value if available, else sum
    final steps = platformSteps ?? sum(HealthDataType.STEPS).round();

    // Distance: Check delta first, then ESTIMATE from steps
    var distanceMeters = sum(HealthDataType.DISTANCE_DELTA);
    if (distanceMeters == 0 && steps > 0) {
      // Fallback: estimate distance (avg stride ~0.76m)
      distanceMeters = steps * 0.762;
    }
    
    // Calories: Check active first, then fallback to step-based estimate if 0
    var activeCals = sum(HealthDataType.ACTIVE_ENERGY_BURNED);
    if (activeCals == 0 && steps > 0) {
      // Fallback: ~0.04 calories per step
      activeCals = steps * 0.04;
    }
    
    // Sleep: Sum up all stages + session + unknown
    var sleepDuration = durationFor(HealthDataType.SLEEP_SESSION);
    if (sleepDuration.inMinutes == 0) {
      sleepDuration = durationFor(HealthDataType.SLEEP_ASLEEP) + 
                      durationFor(HealthDataType.SLEEP_DEEP) + 
                      durationFor(HealthDataType.SLEEP_REM) + 
                      durationFor(HealthDataType.SLEEP_LIGHT) +
                      durationFor(HealthDataType.SLEEP_UNKNOWN);
    }

    // Exercise Time: Sum up workout duration
    final exerciseDuration = durationFor(HealthDataType.WORKOUT);

    final data = ArcHealthData(
      steps: steps,
      distanceKm: distanceMeters / 1000.0,
      activeCalories: activeCals,
      totalCalories: sum(HealthDataType.TOTAL_CALORIES_BURNED),
      sleep: sleepDuration,
      deepSleep: durationFor(HealthDataType.SLEEP_DEEP),
      remSleep: durationFor(HealthDataType.SLEEP_REM),
      lightSleep: durationFor(HealthDataType.SLEEP_LIGHT),
      awakeSleep: durationFor(HealthDataType.SLEEP_AWAKE) + durationFor(HealthDataType.SLEEP_IN_BED),
      heartRate: averageHeartRate?.round(),
      restingHeartRate: latest(HealthDataType.RESTING_HEART_RATE)?.round(),
      exercise: exerciseDuration,
      flightsClimbed: sum(HealthDataType.FLIGHTS_CLIMBED).round(),
      respiratoryRate: latest(HealthDataType.RESPIRATORY_RATE),
      bloodOxygen: latest(HealthDataType.BLOOD_OXYGEN),
      weightKg: latest(HealthDataType.WEIGHT),
      bodyFatPercentage: latest(HealthDataType.BODY_FAT_PERCENTAGE),
      hrvMs: latest(HealthDataType.HEART_RATE_VARIABILITY_RMSSD),
    );

    print('DEBUG: FINAL DATA -> Steps: ${data.steps}, Dist: ${data.distanceKm}km, Sleep: ${data.sleep.inHours}h, Exercise: ${data.exercise.inMinutes}m');
    
    return data;
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