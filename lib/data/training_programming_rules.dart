import 'training_plan_models.dart';

class TrainingSplitRules {
  TrainingSplitRules({
    required Iterable<String> requiredMuscles,
    required Iterable<String> requiredPatterns,
    Iterable<String> optionalPriorityMuscles = const [],
  }) : requiredMuscles = Set.unmodifiable(requiredMuscles),
       requiredPatterns = Set.unmodifiable(requiredPatterns),
       optionalPriorityMuscles = Set.unmodifiable(optionalPriorityMuscles);
  final Set<String> requiredMuscles, requiredPatterns, optionalPriorityMuscles;
}

class TrainingPrescriptionRules {
  const TrainingPrescriptionRules({
    required this.setsByExperience,
    required this.reps,
    required this.restSeconds,
  });
  final Map<TrainingExperience, int> setsByExperience;
  final String reps;
  final int restSeconds;
}

/// Conservative product defaults; no claim of professional programming approval.
/// Inject another immutable rule manifest without changing exercise selection.
class TrainingProgrammingRules {
  TrainingProgrammingRules({
    required this.version,
    required Map<String, TrainingSplitRules> groups,
    required Map<int, List<String>> splits,
    required Map<TrainingGoal, TrainingPrescriptionRules> prescriptions,
    this.blockWeeks = 4,
    this.maximumPriorities = 3,
    this.priorityExtraSets = 1,
    this.minimumWeeklyExposures = 2,
    this.minimumRecoveryDays = 2,
    this.maximumWeeklySetsPerMuscle = 12,
    this.warmupSeconds = 300,
    this.transitionSeconds = 30,
    Iterable<String> exercisePatternOrder = const [
      'knee_dominant',
      'hip_hinge',
      'horizontal_push',
      'horizontal_pull',
      'vertical_push',
      'vertical_pull',
      'hip_extension',
      'core',
    ],
  }) : exercisePatternOrder = List.unmodifiable(exercisePatternOrder),
       groups = Map.unmodifiable(groups),
       splits = Map.unmodifiable(
         splits.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       ),
       prescriptions = Map.unmodifiable(
         prescriptions.map(
           (key, value) => MapEntry(
             key,
             TrainingPrescriptionRules(
               setsByExperience: Map.unmodifiable(value.setsByExperience),
               reps: value.reps,
               restSeconds: value.restSeconds,
             ),
           ),
         ),
       ) {
    if (version.isEmpty ||
        blockWeeks < 1 ||
        maximumPriorities < 0 ||
        priorityExtraSets < 0 ||
        minimumWeeklyExposures < 1 ||
        minimumRecoveryDays < 1 ||
        minimumRecoveryDays > 7 ||
        maximumWeeklySetsPerMuscle < 1 ||
        warmupSeconds < 0 ||
        transitionSeconds < 0 ||
        groups.isEmpty ||
        splits.isEmpty ||
        splits.entries.any(
          (e) =>
              e.key < 2 ||
              e.key > 6 ||
              e.value.length != e.key ||
              e.value.any((s) => !groups.containsKey(s)),
        ) ||
        groups.values.any(
          (g) => g.requiredMuscles.isEmpty || g.requiredPatterns.isEmpty,
        ) ||
        TrainingGoal.values.any((g) => !prescriptions.containsKey(g)) ||
        prescriptions.values.any(
          (p) =>
              p.reps.trim().isEmpty ||
              p.restSeconds < 0 ||
              TrainingExperience.values.any(
                (e) =>
                    (p.setsByExperience[e] ?? 0) < 1 ||
                    p.setsByExperience[e]! > 10,
              ),
        )) {
      throw ArgumentError('Invalid programming rule manifest');
    }
  }
  final String version;
  final List<String> exercisePatternOrder;
  final Map<String, TrainingSplitRules> groups;
  final Map<int, List<String>> splits;
  final Map<TrainingGoal, TrainingPrescriptionRules> prescriptions;
  final int blockWeeks, maximumPriorities, priorityExtraSets;
  final int minimumWeeklyExposures,
      minimumRecoveryDays,
      maximumWeeklySetsPerMuscle;
  final int warmupSeconds, transitionSeconds;

  static TrainingProgrammingRules defaults() {
    const push = {'chest', 'shoulders', 'triceps'};
    const pull = {'upper_back', 'lats', 'biceps'};
    const legs = {'quadriceps', 'hamstrings', 'glutes', 'calves', 'abs'};
    const pushPatterns = {'horizontal_push', 'vertical_push'};
    const pullPatterns = {'horizontal_pull', 'vertical_pull'};
    const legPatterns = {'knee_dominant', 'hip_hinge', 'core'};
    TrainingSplitRules group(
      Set<String> muscles,
      Set<String> patterns,
      Set<String> optional,
    ) => TrainingSplitRules(
      requiredMuscles: muscles,
      requiredPatterns: patterns,
      optionalPriorityMuscles: optional,
    );
    const sets = {
      TrainingExperience.beginner: 2,
      TrainingExperience.intermediate: 2,
      TrainingExperience.advanced: 3,
    };
    return TrainingProgrammingRules(
      version: 'arc-2c-direct-coverage-v2',
      groups: {
        'Full body': group(
          {...push, ...pull, ...legs},
          {...pushPatterns, ...pullPatterns, ...legPatterns},
          {
            'forearms',
            'trapezius',
            'spinal_extensors',
            'obliques',
            'adductors',
            'tibialis',
          },
        ),
        'Upper': group({...push, ...pull}, {...pushPatterns, ...pullPatterns}, {
          'forearms',
          'trapezius',
        }),
        'Lower': group(legs, legPatterns, {
          'spinal_extensors',
          'obliques',
          'adductors',
          'tibialis',
        }),
        'Push': group(push, pushPatterns, {}),
        'Pull': group(pull, pullPatterns, {'forearms', 'trapezius'}),
        'Legs': group(legs, legPatterns, {
          'spinal_extensors',
          'obliques',
          'adductors',
          'tibialis',
        }),
      },
      splits: {
        2: ['Full body', 'Full body'],
        3: ['Full body', 'Full body', 'Full body'],
        4: ['Upper', 'Lower', 'Upper', 'Lower'],
        5: ['Upper', 'Lower', 'Push', 'Pull', 'Legs'],
        6: ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs'],
      },
      prescriptions: {
        TrainingGoal.buildMuscle: TrainingPrescriptionRules(
          setsByExperience: sets,
          reps: '8-12',
          restSeconds: 75,
        ),
        TrainingGoal.loseFat: TrainingPrescriptionRules(
          setsByExperience: sets,
          reps: '10-15',
          restSeconds: 60,
        ),
        TrainingGoal.consistency: TrainingPrescriptionRules(
          setsByExperience: sets,
          reps: '8-12',
          restSeconds: 60,
        ),
      },
    );
  }
}
