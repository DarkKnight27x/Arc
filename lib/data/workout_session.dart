import 'exercise_media.dart';

import 'package:uuid/uuid.dart';

import 'workout_models.dart';
import 'home_workout.dart';

enum WorkoutSessionStatus { inProgress, completed, abandoned }

class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.userId,
    required this.planId,
    required this.dayId,
    required this.dayTitle,
    required this.startedAt,
    required this.exercises,
    required this.completion,
    this.currentIndex = 0,
    this.status = WorkoutSessionStatus.inProgress,
    this.completedAt,
    this.outcome,
    this.trainingLocation = 'gym',
    this.equipment = const [],
    this.requestedMinutes,
    this.estimatedSeconds,
    this.originalTargets = const [],
    this.sourcePrescription = const [],
    this.revision = 0,
    this.baseRevision = -1,
    this.injuryWarning = false,
  });
  factory WorkoutSession.start(
    String userId,
    WorkoutDay day, {
    HomeProposal? home,
  }) {
    if (!day.canStart || day.planId == null) {
      throw StateError('Workout cannot start');
    }
    if (home != null &&
        (!home.available ||
            home.source.id != day.id ||
            home.source.planId != day.planId)) {
      throw StateError('Home proposal does not match the scheduled workout');
    }
    final moves = home?.moves ?? day.moves;
    return WorkoutSession(
      trainingLocation: home == null ? 'gym' : 'home',
      equipment: home == null
          ? const []
          : List.unmodifiable(home.equipment.toList()..sort()),
      requestedMinutes: home?.requestedMinutes,
      estimatedSeconds: home?.estimatedSeconds,
      originalTargets: List.unmodifiable(
        day.moves
            .map((m) => m.primaryTarget)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort(),
      ),
      sourcePrescription: List.unmodifiable(
        List.generate(
          day.moves.length,
          (i) => sessionMoveFromMap(sessionMoveToMap(day.moves[i], i)),
        ),
      ),
      id: const Uuid().v4(),
      userId: userId,
      planId: day.planId!,
      dayId: day.id,
      dayTitle: day.title,
      startedAt: DateTime.now().toUtc(),
      exercises: List.unmodifiable(
        List.generate(
          moves.length,
          (i) => sessionMoveFromMap(sessionMoveToMap(moves[i], i)),
        ),
      ),
      completion: moves.map((m) => List.filled(m.trackingSets, false)).toList(),
    );
  }
  final String id, userId, planId, dayId, dayTitle;
  final DateTime startedAt;
  final String trainingLocation;
  String get sessionVariant =>
      trainingLocation == 'home' ? 'home_curated' : 'gym_original';
  final List<String> equipment, originalTargets;
  final int? requestedMinutes, estimatedSeconds;
  final List<WorkoutMove> sourcePrescription;
  int revision, baseRevision;
  bool injuryWarning;
  final List<WorkoutMove> exercises;
  final List<List<bool>> completion;
  int currentIndex;
  WorkoutSessionStatus status;
  DateTime? completedAt;
  String? outcome;
  int get totalSets => completion.fold(0, (n, row) => n + row.length);
  int get doneSets =>
      completion.expand((row) => row).where((done) => done).length;
  bool get allComplete => totalSets > 0 && doneSets == totalSets;
  void toggle(int exercise, int set) {
    if (status != WorkoutSessionStatus.inProgress) {
      throw StateError('Session has ended');
    }
    completion[exercise][set] = !completion[exercise][set];
    revision++;
  }

  void finish({bool discard = false}) {
    if (status != WorkoutSessionStatus.inProgress) {
      throw StateError('Session has ended');
    }
    outcome = discard
        ? 'discarded'
        : allComplete
        ? 'completed'
        : 'partial';
    status = outcome == 'completed'
        ? WorkoutSessionStatus.completed
        : WorkoutSessionStatus.abandoned;
    completedAt = DateTime.now().toUtc();
    revision++;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'workout_plan_id': planId,
    'workout_day_id': dayId,
    'day_title': dayTitle,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'status': status == WorkoutSessionStatus.inProgress
        ? 'in_progress'
        : status.name,
    'outcome': outcome,
    'current_index': currentIndex,
    'injury_warning': injuryWarning,
    'contract_version': 2,
    'training_location': trainingLocation,
    'session_variant': sessionVariant,
    'equipment_selection': equipment,
    'requested_duration_minutes': requestedMinutes,
    'estimated_duration_seconds': estimatedSeconds,
    'original_targets': originalTargets,
    'source_prescription': List.generate(
      sourcePrescription.length,
      (i) => sessionMoveToMap(sourcePrescription[i], i),
    ),
    'revision': revision,
    'base_revision': baseRevision,
    'prescription': List.generate(
      exercises.length,
      (i) => sessionMoveToMap(exercises[i], i),
    ),
    'completion': completion.map((row) => List<bool>.of(row)).toList(),
  };
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final moves = (map['prescription'] as List)
        .map((raw) => sessionMoveFromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
    final completion = (map['completion'] as List)
        .map((r) => List<bool>.from(r as List))
        .toList();
    final index = map['current_index'] as int;
    if (moves.any(
          (m) => m.trackingSets <= 0 || m.timerSeconds < 0 || m.sortOrder < 0,
        ) ||
        moves.map((m) => m.id).toSet().length != moves.length ||
        moves.isEmpty ||
        completion.length != moves.length ||
        index < 0 ||
        index >= moves.length ||
        List.generate(
          moves.length,
          (i) => completion[i].length == moves[i].trackingSets,
        ).contains(false)) {
      throw const FormatException('Invalid session snapshot');
    }
    final session = WorkoutSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      planId: map['workout_plan_id'] as String,
      dayId: map['workout_day_id'] as String,
      dayTitle: map['day_title'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      exercises: List.unmodifiable(moves),
      completion: completion,
      currentIndex: index,
      status: switch (map['status']) {
        'in_progress' => WorkoutSessionStatus.inProgress,
        'completed' => WorkoutSessionStatus.completed,
        'abandoned' => WorkoutSessionStatus.abandoned,
        _ => throw const FormatException('Invalid session status'),
      },
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
      outcome: map['outcome'] as String?,
      injuryWarning: map['injury_warning'] as bool? ?? false,
      trainingLocation: map['training_location'] as String? ?? 'gym',
      equipment: List<String>.unmodifiable(
        map['equipment_selection'] as List? ?? const [],
      ),
      requestedMinutes: map['requested_duration_minutes'] as int?,
      estimatedSeconds: map['estimated_duration_seconds'] as int?,
      originalTargets: List<String>.unmodifiable(
        map['original_targets'] as List? ?? const [],
      ),
      sourcePrescription: List<WorkoutMove>.unmodifiable(
        (map['source_prescription'] as List? ?? map['prescription'] as List)
            .map(
              (m) => sessionMoveFromMap(Map<String, dynamic>.from(m as Map)),
            ),
      ),
      revision: map['revision'] as int? ?? 0,
      baseRevision:
          map['base_revision'] as int? ?? map['revision'] as int? ?? -1,
    );
    if (!['gym', 'home'].contains(session.trainingLocation) ||
        session.revision < 0 ||
        (session.requestedMinutes != null && session.requestedMinutes! <= 0) ||
        (session.trainingLocation == 'home' &&
            (!session.equipment.contains('bodyweight') ||
                !homeCapabilities.containsAll(session.equipment) ||
                session.exercises.any(
                  (m) =>
                      m.mappingId == null ||
                      m.mappingVersion == null ||
                      m.exerciseId == null,
                )))) {
      throw const FormatException('Invalid session variant');
    }
    final ended = session.status != WorkoutSessionStatus.inProgress;
    if ((!ended && (session.completedAt != null || session.outcome != null)) ||
        (ended &&
            (session.completedAt == null ||
                session.completedAt!.isBefore(session.startedAt))) ||
        (session.status == WorkoutSessionStatus.completed &&
            (!session.allComplete || session.outcome != 'completed')) ||
        (session.status == WorkoutSessionStatus.abandoned &&
            !['partial', 'discarded'].contains(session.outcome))) {
      throw const FormatException('Invalid session outcome');
    }
    return session;
  }
}

Map<String, dynamic> sessionMoveToMap(WorkoutMove m, int position) => {
  'source_workout_day_exercise_id': m.id,
  'actual_exercise_library_id': m.exerciseId,
  'exercise_position': position,
  'name': m.name,
  'equipment': m.machine,
  'sets': m.sets,
  'reps': m.reps,
  'rest_seconds': m.restSeconds,
  'sort_order': m.sortOrder,
  'notes': m.notes,
  'gif_url': m.gifUrl,
  'gif_path': m.gifPath,
  'instructions': m.instructions,
  'primary_target': m.primaryTarget,
  'secondary_muscles': m.secondaryTargets,
  'body_part': m.bodyPart,
  'mapping_id': m.mappingId,
  'mapping_version': m.mappingVersion,
  'movement_pattern': m.movementPattern,
};
WorkoutMove sessionMoveFromMap(Map<String, dynamic> m) => WorkoutMove(
  id: (m['source_workout_day_exercise_id'] ?? m['id']) as String,
  exerciseId: (m['actual_exercise_library_id'] ?? m['exercise_id']) as String?,
  name: m['name'] as String,
  machine: m['equipment'] as String,
  sortOrder: m['sort_order'] as int,
  sets: m['sets'] as int?,
  reps: m['reps'] as String?,
  restSeconds: m['rest_seconds'] as int?,
  notes: m['notes'] as String?,
  gifUrl: ExerciseMediaPath.storedPath(m['gif_url']),
  gifPath: ExerciseMediaPath.storedPath(m['gif_path']),
  instructions: List<String>.unmodifiable(m['instructions'] as List),
  primaryTarget: m['primary_target'] as String?,
  secondaryTargets: List<String>.unmodifiable(
    m['secondary_muscles'] as List? ?? const [],
  ),
  bodyPart: m['body_part'] as String?,
  mappingId: m['mapping_id'] as String?,
  mappingVersion: m['mapping_version'] as int?,
  movementPattern: m['movement_pattern'] as String?,
);
