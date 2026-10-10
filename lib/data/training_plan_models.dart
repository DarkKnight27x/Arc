import 'dart:convert';

export 'training_metadata.dart';
import 'training_metadata.dart';

bool stableExerciseId(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

Object? frozenJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      value.map((key, item) => MapEntry(key as String, frozenJson(item))),
    );
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(frozenJson));
  }
  return value;
}

String canonicalJson(Object? value) {
  Object? ordered(Object? item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(item[key])};
    }
    if (item is List) return item.map(ordered).toList();
    return item;
  }

  return jsonEncode(ordered(value));
}

enum TrainingGoal { buildMuscle, loseFat, consistency }

enum TrainingExperience { beginner, intermediate, advanced }

enum TrainingIssueCode {
  invalidConfiguration,
  unsupportedFrequency,
  unsupportedPriority,
  safetyReviewRequired,
  unsupportedLocation,
  catalogUnavailable,
  invalidCatalog,
  noEligibleExercises,
  missingMuscles,
  missingPatterns,
  equipmentUnavailable,
  experienceUnavailable,
  recoveryConflict,
  durationExceeded,
  volumeExceeded,
  insufficientFrequency,
}

class TrainingIssue {
  TrainingIssue(this.code, this.message, {Iterable<String> details = const []})
    : details = List.unmodifiable(details);
  final TrainingIssueCode code;
  final String message;
  final List<String> details;
  Map<String, Object?> toMap() => {
    'code': code.name,
    'message': message,
    'details': details,
  };
}

class TrainingPlanConfig {
  TrainingPlanConfig({
    required this.goal,
    required this.experience,
    required Iterable<int> weekdays,
    required Iterable<String> equipment,
    required this.sessionMinutes,
    required this.journeyDays,
    required this.age,
    this.location = 'gym',
    this.hasReportedLimitations = false,
    Iterable<String> priorities = const [],
  }) : weekdays = List.unmodifiable(weekdays.toList()..sort()),
       equipment = Set.unmodifiable(equipment.map(canonicalEquipment)),
       priorities = Set.unmodifiable(priorities.map(canonicalMuscle));
  final TrainingGoal goal;
  final TrainingExperience experience;
  final List<int> weekdays;
  final Set<String> equipment, priorities;
  final int sessionMinutes, journeyDays, age;
  final String location;
  final bool hasReportedLimitations;
}

class TrainingCatalogExercise {
  TrainingCatalogExercise.fromMap(Map<String, dynamic> row)
    : id = row['id'] is String ? (row['id'] as String).toLowerCase() : '',
      name = row['name'] is String ? row['name'] as String : '',
      published = row['is_published'] == true,
      sourceSnapshot = frozenJson({
        for (final key in snapshotFields) key: row[key],
      }) as Map<String, Object?>,
      metadata = ExerciseMetadata.fromMap(row);
  static const snapshotFields = [
    'name',
    'body_part',
    'target_muscle',
    'secondary_muscles',
    'equipment',
    'difficulty',
    'instructions',
    'gif_path',
    'tags',
  ];
  final String id, name;
  final bool published;
  final Map<String, Object?> sourceSnapshot;
  final ExerciseMetadata metadata;
  bool get usable {
    final instructions = sourceSnapshot['instructions'];
    return stableExerciseId(id) &&
        name.trim().isNotEmpty &&
        published &&
        metadata.valid &&
        instructions is List &&
        instructions.isNotEmpty &&
        instructions.every((x) => x is String && x.trim().isNotEmpty);
  }
}

class TrainingCatalog {
  TrainingCatalog(
    Iterable<TrainingCatalogExercise> exercises, {
    Iterable<TrainingIssue> issues = const [],
  }) : exercises = List.unmodifiable(exercises),
       issues = List.unmodifiable(issues);
  final List<TrainingCatalogExercise> exercises;
  final List<TrainingIssue> issues;
}

class PlannedTrainingExercise {
  const PlannedTrainingExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.transitionSeconds,
  });
  final TrainingCatalogExercise exercise;
  final int sets, restSeconds, transitionSeconds;
  final String reps;
  String get primaryMuscle => exercise.metadata.primaryMuscle;
  Set<String> get patterns => exercise.metadata.patterns;
  int get estimatedSeconds =>
      sets * exercise.metadata.workSecondsPerSet +
      (sets - 1) * restSeconds +
      transitionSeconds;
  Map<String, Object?> toMap() => {
    'exercise_id': exercise.id,
    'name': exercise.name,
    'gif_path': exercise.sourceSnapshot['gif_path'],
    'primary_muscle': primaryMuscle,
    'movement_patterns': patterns.toList()..sort(),
    'sets': sets,
    'reps': reps,
    'rest_seconds': restSeconds,
    'estimated_seconds': estimatedSeconds,
  };
}

class PlannedTrainingDay {
  PlannedTrainingDay({
    required this.weekday,
    required this.split,
    required Iterable<PlannedTrainingExercise> exercises,
    required this.warmupSeconds,
  }) : exercises = List.unmodifiable(exercises);
  final int weekday, warmupSeconds;
  final String split;
  final List<PlannedTrainingExercise> exercises;
  int get estimatedSeconds =>
      warmupSeconds + exercises.fold(0, (sum, e) => sum + e.estimatedSeconds);
  Map<String, Object?> toMap() => {
    'weekday': weekday,
    'title': split,
    'estimated_minutes': (estimatedSeconds / 60).ceil(),
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };
}

class TrainingPlanPreview {
  TrainingPlanPreview({
    required this.config,
    required this.ruleVersion,
    required this.blockWeeks,
    required Iterable<PlannedTrainingDay> days,
  }) : days = List.unmodifiable(days);
  final TrainingPlanConfig config;
  final String ruleVersion;
  final int blockWeeks;
  final List<PlannedTrainingDay> days;
  // Checkpoint 1 has no activation authority or persistence entry point.
  bool get canActivate => false;
  List<Map<String, Object?>> get week => List.generate(7, (index) {
    final scheduled = days.where((day) => day.weekday == index + 1);
    return scheduled.isNotEmpty
        ? {...scheduled.single.toMap(), 'rest_day': false}
        : {
            'weekday': index + 1,
            'title': 'Rest day',
            'rest_day': true,
            'estimated_minutes': 0,
            'exercises': <Object?>[],
          };
  });
  Map<String, Object?> toMap() => {
    'journey_days': config.journeyDays,
    'block_weeks': blockWeeks,
    'rule_version': ruleVersion,
    'can_activate': false,
    'progression': 'No automatic load increases. Reassess at the block review.',
    'days': days.map((d) => d.toMap()).toList(),
    'week': week,
  };
}

class TrainingGenerationResult {
  TrainingGenerationResult({
    required this.catalogCount,
    required this.eligibleCount,
    required Iterable<TrainingIssue> issues,
    this.preview,
  }) : issues = List.unmodifiable(issues);
  final int catalogCount, eligibleCount;
  final List<TrainingIssue> issues;
  final TrainingPlanPreview? preview;
  bool get available => issues.isEmpty && preview != null;
  bool get canActivate => false;
  Map<String, Object?> toMap() => {
    'status': available ? 'available_for_review' : 'unavailable',
    'catalog_count': catalogCount,
    'eligible_count': eligibleCount,
    'can_activate': false,
    'issues': issues.map((issue) => issue.toMap()).toList(),
    'preview': preview?.toMap(),
  };
}
