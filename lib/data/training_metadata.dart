/// Shared catalog and anatomy vocabulary. Never examines exercise names.
String canonicalMuscle(String value) => switch (value.trim().toLowerCase()) {
  'pectorals' => 'chest',
  'delts' || 'deltoids' => 'shoulders',
  'upper-back' || 'upper back' => 'upper_back',
  'lower-back' || 'lower back' || 'spine' => 'spinal_extensors',
  'gluteal' => 'glutes',
  'hamstring' => 'hamstrings',
  'quads' => 'quadriceps',
  'forearm' => 'forearms',
  'traps' => 'trapezius',
  _ => value.trim().toLowerCase(),
};

String canonicalEquipment(String value) => switch (value.trim().toLowerCase()) {
  'body weight' || 'bodyweight' => 'bodyweight',
  'dumbbell' || 'dumbbells' => 'dumbbells',
  _ => value.trim().toLowerCase().replaceAll(' ', '_'),
};

String trainingLabel(String id) => id
    .replaceAll('_', ' ')
    .split(' ')
    .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');

const anatomyPriorityIds = [
  'abs',
  'adductors',
  'biceps',
  'calves',
  'chest',
  'deltoids',
  'forearm',
  'gluteal',
  'hamstring',
  'lower-back',
  'obliques',
  'quadriceps',
  'tibialis',
  'trapezius',
  'triceps',
  'upper-back',
];

class ExerciseMetadata {
  factory ExerciseMetadata.fromMap(Map<String, dynamic> row) {
    final primaryMuscle = row['target_muscle'] is String
        ? canonicalMuscle(row['target_muscle'])
        : '';
    final equipment = row['equipment'];
    var requiredEquipment = Set.unmodifiable(
      equipment is String ? [canonicalEquipment(equipment)] : <String>[],
    );
    Set<String> patterns = const {};
    Set<String> locations = const {'gym', 'home'};
    var minimumExperience =
        0; // Missing difficulty is unknown, not a verified beginner rating.
    var valid =
        _id(primaryMuscle) &&
        requiredEquipment.isNotEmpty &&
        requiredEquipment.every(_id);
    final difficulty = row['difficulty'];
    if (difficulty != null) {
      final level = difficulty is String
          ? [
              'beginner',
              'intermediate',
              'advanced',
            ].indexOf(difficulty.trim().toLowerCase())
          : -1;
      if (level < 0) {
        valid = false;
      } else {
        minimumExperience = level;
      }
    }
    // Optional future library fields. No inference from names or secondary muscles.
    for (final key in [
      'required_equipment',
      'movement_patterns',
      'allowed_locations',
    ]) {
      if (!row.containsKey(key)) continue;
      final raw = row[key];
      if (raw is! List ||
          raw.isEmpty ||
          raw.any((x) => x is! String || x.trim().isEmpty)) {
        valid = false;
        continue;
      }
      final values = raw
          .cast<String>()
          .map(
            key == 'required_equipment'
                ? canonicalEquipment
                : (s) => s.trim().toLowerCase(),
          )
          .toSet();
      if (!values.every(_id)) valid = false;
      if (key == 'required_equipment') {
        requiredEquipment = Set.unmodifiable({...requiredEquipment, ...values});
      }
      if (key == 'movement_patterns') patterns = Set.unmodifiable(values);
      if (key == 'allowed_locations') {
        locations = Set.unmodifiable(values);
        if (!values.every({'gym', 'home'}.contains)) valid = false;
      }
    }
    return ExerciseMetadata._(
      primaryMuscle,
      requiredEquipment,
      patterns,
      locations,
      minimumExperience,
      valid,
    );
  }
  const ExerciseMetadata._(
    this.primaryMuscle,
    this.requiredEquipment,
    this.patterns,
    this.locations,
    this.minimumExperience,
    this.valid,
  );
  static bool _id(String s) => RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(s);
  final String primaryMuscle;
  final Set<String> requiredEquipment, patterns, locations;
  final int minimumExperience;
  final bool valid;
  // Conservative generic estimate, not an exercise-specific measured duration.
  int get workSecondsPerSet => 60;
}
