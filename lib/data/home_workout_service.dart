import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_workout.dart';
import 'workout_models.dart';

class HomeWorkoutService {
  HomeWorkoutService(this.client);
  final SupabaseClient client;
  Future<HomeProposal> propose(
    WorkoutDay day,
    Set<String> equipment,
    int? minutes,
  ) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) throw const AuthException('Please sign in.');
    if (!day.canStart) {
      return HomeWorkoutEngine.build(day, [], {}, equipment, minutes);
    }
    List<Map<String, dynamic>> rows;
    try {
      rows = await client
          .from('workout_alternative_mappings')
          .select()
          .inFilter(
            'source_exercise_id',
            day.moves.map((m) => m.exerciseId!).toList(),
          )
          .eq('review_status', 'approved')
          .eq('enabled', true)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 20));
    } on PostgrestException catch (e) {
      if (['42P01', 'PGRST205'].contains(e.code)) {
        throw StateError(
          'Reviewed home alternatives are not available yet. The mapping migration needs review and deployment.',
        );
      }
      rethrow;
    }
    final mappings = rows.map(HomeMapping.fromMap).toList();
    final ids = mappings.map((m) => m.alternativeId).toSet().toList();
    final catalog = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('exercise_library')
              .select()
              .inFilter('id', ids)
              .eq('is_published', true)
              .timeout(const Duration(seconds: 20));
    if (client.auth.currentUser?.id != owner) {
      throw const AuthException('Your account changed.');
    }
    return HomeWorkoutEngine.build(
      day,
      mappings,
      {for (final ex in catalog) ex['id'] as String: ex},
      equipment,
      minutes,
      gifUrl: (path) => client.storage.from('exercise-gifs').getPublicUrl(path),
    );
  }
}
