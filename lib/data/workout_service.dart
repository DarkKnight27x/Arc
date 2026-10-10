import 'exercise_media.dart';

import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'workout_models.dart';

class WorkoutService {
  static final changes = ValueNotifier<({String owner, int revision})?>(null);
  static void invalidate(String owner) => changes.value = (
    owner: owner,
    revision: (changes.value?.revision ?? 0) + 1,
  );
  WorkoutService(this.client);
  static WorkoutService get instance =>
      WorkoutService(Supabase.instance.client);
  final SupabaseClient client;
  Future<List<WorkoutDay>> fetchWorkoutPlan() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Please sign in to view your plan.');
    }
    final plans = await client
        .from('workout_plans')
        .select('id')
        .eq('user_id', userId)
        .eq('plan_type', 'training')
        .eq('status', 'active')
        .order('version', ascending: false)
        .order('updated_at', ascending: false)
        .order('id', ascending: true)
        .limit(1)
        .timeout(const Duration(seconds: 20));
    if (client.auth.currentUser?.id != userId) {
      throw const AuthException('Your account changed.');
    }
    if (plans.isEmpty) return [];
    final planId = plans.single['id'] as String;
    final data = await client
        .from('workout_days')
        .select('*, workout_day_exercises(*, exercise_library(*))')
        .eq('workout_plan_id', planId)
        .order('weekday')
        .timeout(const Duration(seconds: 20));
    if (client.auth.currentUser?.id != userId) {
      throw const AuthException('Your account changed.');
    }
    try {
      return workoutWeek(
        planId,
        parseDays(
          data,
          gifUrl: (path) =>
              client.storage.from('exercise-gifs').getPublicUrl(path),
        ),
      );
    } on TypeError {
      throw const FormatException('Malformed workout relations');
    }
  }

  static List<WorkoutDay> parseDays(
    List<dynamic> data, {
    String Function(String)? gifUrl,
  }) {
    return data.map((raw) {
      final day = raw as Map<String, dynamic>;
      final rows = List<Map<String, dynamic>>.from(
        day['workout_day_exercises'] as List,
      );
      rows.sort(
        (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
      );
      if (rows.map((r) => r['sort_order']).toSet().length != rows.length) {
        throw const FormatException('Duplicate exercise order');
      }
      final moves = rows.map((row) {
        final ex = row['exercise_library'];
        final path = ex is Map ? ex['gif_path'] : null;
        return WorkoutMove.fromMap(
          row,
          gifUrl: ExerciseMediaPath.resolve(path, storageUrl: gifUrl),
        );
      }).toList();
      return WorkoutDay.fromMap(day, [
        WorkoutRegion(label: 'Prescribed sequence', moves: moves),
      ]);
    }).toList();
  }
}
