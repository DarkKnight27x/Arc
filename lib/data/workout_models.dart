import 'exercise_media.dart';

import 'package:flutter/foundation.dart';

@immutable
class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.weekday,
    required this.title,
    this.planId,
    this.muscles = '',
    this.estimatedMinutes,
    this.regions = const [],
    this.isRestDay = false,
  });
  final String id;
  final String? planId;
  final int weekday;
  final String title, muscles;
  final int? estimatedMinutes;
  final List<WorkoutRegion> regions;
  final bool isRestDay;
  List<WorkoutMove> get moves => regions.expand((r) => r.moves).toList();
  bool get canStart =>
      !isRestDay && moves.isNotEmpty && moves.every((m) => m.available);
  factory WorkoutDay.fromMap(
    Map<String, dynamic> map,
    List<WorkoutRegion> regions,
  ) {
    final weekday = map['weekday'] as int;
    if (weekday < 1 || weekday > 7) {
      throw const FormatException('Invalid weekday');
    }
    return WorkoutDay(
      id: map['id'] as String,
      planId: map['workout_plan_id'] as String,
      weekday: weekday,
      title: map['title'] as String,
      estimatedMinutes: map['estimated_minutes'] as int?,
      muscles: map['notes'] as String? ?? '',
      regions: regions,
    );
  }
}

List<WorkoutDay> workoutWeek(String planId, List<WorkoutDay> days) {
  if (days.map((d) => d.weekday).toSet().length != days.length) {
    throw const FormatException('Duplicate weekday');
  }
  return List.generate(
    7,
    (i) => days.firstWhere(
      (d) => d.weekday == i + 1,
      orElse: () => WorkoutDay(
        id: '',
        planId: planId,
        weekday: i + 1,
        title: 'Rest Day',
        isRestDay: true,
      ),
    ),
  );
}

@immutable
class WorkoutRegion {
  const WorkoutRegion({required this.label, required this.moves});
  final String label;
  final List<WorkoutMove> moves;
}

@immutable
class WorkoutMove {
  const WorkoutMove({
    required this.id,
    required this.name,
    required this.machine,
    required this.sortOrder,
    this.exerciseId,
    this.sets,
    this.reps,
    this.restSeconds,
    this.notes,
    this.gifUrl,
    this.instructions = const [],
    this.available = true,
    this.primaryTarget,
    this.bodyPart,
    this.secondaryTargets = const [],
    this.mappingId,
    this.mappingVersion,
    this.movementPattern,
    this.gifPath,
  });
  final String
  id; // Source workout_day_exercises UUID; never the selected library UUID.
  final String? exerciseId; // Actual selected exercise_library UUID.
  final String? primaryTarget, bodyPart, mappingId, movementPattern, gifPath;
  final int? mappingVersion;
  final List<String> secondaryTargets;
  final String name, machine;
  final int sortOrder;
  final int? sets, restSeconds;
  final String? reps, notes, gifUrl;
  final List<String> instructions;
  final bool available;
  // Optional defaults are labelled; snapshots preserve the absent prescription.
  int get trackingSets => sets ?? 1;
  int get timerSeconds => restSeconds ?? 0;
  String get scheme =>
      '${sets == null ? 'Sets unspecified (track 1)' : '$sets sets'} · ${reps ?? 'Reps unspecified'}';
  String get restLabel => restSeconds == null
      ? 'Rest unspecified (no timer)'
      : '${restSeconds}s rest';
  factory WorkoutMove.fromMap(Map<String, dynamic> map, {String? gifUrl}) {
    final relation = map['exercise_library'];
    if (relation != null && relation is! Map<String, dynamic>) {
      throw const FormatException('Malformed exercise relation');
    }
    final exercise = relation as Map<String, dynamic>?;
    final sets = map['sets'] as int?;
    final rest = map['rest_seconds'] as int?;
    final order = map['sort_order'] as int;
    if ((sets != null && sets <= 0) ||
        (rest != null && rest < 0) ||
        order < 0) {
      throw const FormatException('Invalid prescription');
    }
    return WorkoutMove(
      id: map['id'] as String,
      exerciseId: map['exercise_id'] as String,
      name: exercise?['name'] as String? ?? 'Exercise unavailable',
      machine: exercise?['equipment'] as String? ?? 'Equipment unavailable',
      sortOrder: order,
      sets: sets,
      reps: map['reps'] as String?,
      restSeconds: rest,
      notes: map['notes'] as String?,
      gifUrl: gifUrl,
      gifPath: ExerciseMediaPath.storedPath(exercise?['gif_path']),
      primaryTarget: exercise?['target_muscle'] as String?,
      bodyPart: exercise?['body_part'] as String?,
      secondaryTargets: List<String>.from(
        exercise?['secondary_muscles'] ?? const [],
      ),
      available: exercise != null && exercise['is_published'] != false,
      instructions: List<String>.from(exercise?['instructions'] ?? const []),
    );
  }
}
