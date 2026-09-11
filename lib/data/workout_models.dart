import 'package:flutter/foundation.dart';

@immutable
class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.weekday,
    required this.title,
    this.muscles = '',
    this.estimatedMinutes = 0,
    this.regions = const [],
  });

  final String id;
  final int weekday;
  final String title;
  final String muscles;
  final int estimatedMinutes;
  final List<WorkoutRegion> regions;

  factory WorkoutDay.fromMap(Map<String, dynamic> map, List<WorkoutRegion> regions) {
    return WorkoutDay(
      id: map['id'] as String,
      weekday: map['weekday'] as int,
      title: map['title'] as String,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 0,
      muscles: map['notes'] ?? '', // Using notes as a muscle summary for now if needed
      regions: regions,
    );
  }
}

@immutable
class WorkoutRegion {
  const WorkoutRegion({
    required this.label,
    required this.moves,
  });

  final String label;
  final List<WorkoutMove> moves;
}

@immutable
class WorkoutMove {
  const WorkoutMove({
    required this.id,
    required this.name,
    required this.machine,
    required this.scheme,
    this.gifUrl,
    this.instructions = const [],
  });

  final String id;
  final String name;
  final String machine;
  final String scheme;
  final String? gifUrl;
  final List<String> instructions;

  factory WorkoutMove.fromMap(Map<String, dynamic> map) {
    final exercise = map['exercise_library'] as Map<String, dynamic>;
    
    // Construct GIF URL if path exists
    // Assuming bucket name is 'exercises'
    String? gifUrl;
    final gifPath = exercise['gif_path'] as String?;
    if (gifPath != null && gifPath.isNotEmpty) {
      // This will be completed in the service where we have the client
    }

    return WorkoutMove(
      id: map['id'] as String,
      name: exercise['name'] as String,
      machine: exercise['equipment'] as String,
      scheme: '${map['sets']} × ${map['reps']}',
      gifUrl: gifUrl,
      instructions: List<String>.from(exercise['instructions'] ?? []),
    );
  }
}
