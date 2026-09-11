import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_models.dart';

class WorkoutService {
  WorkoutService._();
  static final instance = WorkoutService._();

  final _supabase = Supabase.instance.client;

  Future<List<WorkoutDay>> fetchWorkoutPlan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Try to get real plan first
      final plans = await _supabase
          .from('workout_plans')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (plans.isNotEmpty) {
        final planId = plans.first['id'] as String;
        final data = await _supabase
            .from('workout_days')
            .select('*, workout_day_exercises(*, exercise_library(*))')
            .eq('workout_plan_id', planId)
            .order('weekday');
        
        if (data.isNotEmpty) {
          return _parseDays(data);
        }
      }

      // 2. Fallback: Create a "Global Discovery" plan from the library
      print('DEBUG: No user plan found. Fetching global library for discovery plan.');
      final libraryData = await _supabase
          .from('exercise_library')
          .select('*')
          .limit(20);

      if (libraryData.isEmpty) return [];

      // Create fake days based on body parts in the library
      final Map<String, List<WorkoutMove>> bodyPartMap = {};
      for (final ex in libraryData) {
        final part = ex['body_part'] as String? ?? 'General';
        
        final gifPath = ex['gif_path'] as String?;
        String? gifUrl;
        if (gifPath != null && gifPath.isNotEmpty) {
          gifUrl = _supabase.storage.from('exercise-gifs').getPublicUrl(gifPath);
        }

        final move = WorkoutMove(
          id: ex['id'] as String,
          name: ex['name'] as String,
          machine: ex['equipment'] as String,
          scheme: '3 × 10', // Standard placeholder
          gifUrl: gifUrl,
          instructions: List<String>.from(ex['instructions'] ?? []),
        );

        bodyPartMap.putIfAbsent(part, () => []).add(move);
      }

      // Convert body parts to "Days"
      final List<WorkoutDay> discoveryDays = [];
      int dayCount = 1;
      bodyPartMap.forEach((part, moves) {
        if (dayCount > 5) return; // Limit to 5 days
        
        // Split moves into regions based on target_muscle
        final Map<String, List<WorkoutMove>> regionMap = {};
        for (var m in moves) {
           // We don't have the muscle here directly easily without re-querying or storing, 
           // let's just group by "Prime" for discovery
           regionMap.putIfAbsent(part, () => []).add(m);
        }

        discoveryDays.add(WorkoutDay(
          id: 'discovery_$dayCount',
          weekday: dayCount,
          title: '$part Day',
          muscles: part,
          estimatedMinutes: 45,
          regions: regionMap.entries.map((e) => WorkoutRegion(label: e.key, moves: e.value)).toList(),
        ));
        dayCount++;
      });

      return discoveryDays;

    } catch (e) {
      print('ERROR FETCHING WORKOUT: $e');
      return [];
    }
  }

  List<WorkoutDay> _parseDays(List<dynamic> data) {
    final List<WorkoutDay> workoutDays = [];
    for (final dayMap in data) {
      final exerciseMaps = dayMap['workout_day_exercises'] as List<dynamic>;
      final Map<String, List<WorkoutMove>> groupedMoves = {};

      for (final exMap in exerciseMaps) {
        final exercise = exMap['exercise_library'] as Map<String, dynamic>;
        final muscle = exercise['target_muscle'] as String? ?? 'Other';
        
        final gifPath = exercise['gif_path'] as String?;
        String? gifUrl;
        if (gifPath != null && gifPath.isNotEmpty) {
          gifUrl = _supabase.storage.from('exercise-gifs').getPublicUrl(gifPath);
        }

        final move = WorkoutMove(
          id: exMap['id'] as String,
          name: exercise['name'] as String,
          machine: exercise['equipment'] as String,
          scheme: '${exMap['sets'] ?? 3} × ${exMap['reps'] ?? 10}',
          gifUrl: gifUrl,
          instructions: List<String>.from(exercise['instructions'] ?? []),
        );

        groupedMoves.putIfAbsent(muscle, () => []).add(move);
      }

      final regions = groupedMoves.entries.map((e) {
        return WorkoutRegion(label: e.key, moves: e.value);
      }).toList();

      workoutDays.add(WorkoutDay.fromMap(dayMap, regions));
    }
    return workoutDays;
  }
}
