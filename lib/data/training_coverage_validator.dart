import 'training_plan_models.dart';
import 'training_programming_rules.dart';

/// Counts direct primary targets only. Secondary labels never fill a gap.
class TrainingCoverageValidator {
  static List<TrainingIssue> validate(
    TrainingPlanConfig config,
    List<PlannedTrainingDay> days,
    TrainingCatalog catalog,
    TrainingProgrammingRules rules,
  ) {
    final issues = <TrainingIssue>[];
    void issue(
      TrainingIssueCode code,
      String message,
      Iterable<String> details,
    ) {
      issues.add(TrainingIssue(code, message, details: details));
    }

    final split = rules.splits[config.weekdays.length];
    if (split == null || days.length != config.weekdays.length) {
      return [
        TrainingIssue(
          TrainingIssueCode.invalidConfiguration,
          'The proposed schedule does not match the requested training days.',
        ),
      ];
    }
    final inventory = {for (final e in catalog.exercises) e.id: e};
    final required = <String>{...config.priorities};
    final exposures = <String, Set<int>>{};
    final volume = <String, int>{};
    final prescription = rules.prescriptions[config.goal]!;
    final baseSets = prescription.setsByExperience[config.experience]!;
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final group = rules.groups[split[i]]!;
      required.addAll(group.requiredMuscles);
      if (day.weekday != config.weekdays[i] || day.split != split[i]) {
        issue(
          TrainingIssueCode.invalidConfiguration,
          'The proposed weekday or split is inconsistent.',
          ['day:${day.weekday}'],
        );
      }
      final primary = <String>{}, patterns = <String>{}, used = <String>{};
      for (final move in day.exercises) {
        final registered = inventory[move.exercise.id];
        final c = move.exercise.metadata;
        // Only immutable catalog objects loaded for this request are admissible.
        if (registered == null ||
            !identical(registered, move.exercise) ||
            !registered.usable ||
            !used.add(registered.id)) {
          issue(
            TrainingIssueCode.invalidCatalog,
            'A proposed exercise is unavailable or duplicated.',
            [move.exercise.id],
          );
          continue;
        }
        if (!c.locations.contains(config.location) ||
            !config.equipment.containsAll(c.requiredEquipment) ||
            c.minimumExperience > config.experience.index) {
          issue(
            TrainingIssueCode.invalidCatalog,
            'An exercise does not meet the configured location, equipment or experience.',
            [registered.id],
          );
          continue;
        }
        final allowedTargets = {
          ...group.requiredMuscles,
          ...group.optionalPriorityMuscles.intersection(config.priorities),
        };
        final expectedSets =
            baseSets +
            (config.priorities.contains(c.primaryMuscle)
                ? rules.priorityExtraSets
                : 0);
        if (!allowedTargets.contains(c.primaryMuscle) ||
            move.sets != expectedSets ||
            move.reps != prescription.reps ||
            move.restSeconds != prescription.restSeconds ||
            move.transitionSeconds != rules.transitionSeconds ||
            day.warmupSeconds != rules.warmupSeconds) {
          issue(
            TrainingIssueCode.invalidConfiguration,
            'An exercise prescription does not match the programming rules.',
            [registered.id],
          );
          continue;
        }
        primary.add(c.primaryMuscle);
        patterns.addAll(c.patterns);
        exposures.putIfAbsent(c.primaryMuscle, () => <int>{}).add(day.weekday);
        volume.update(
          c.primaryMuscle,
          (n) => n + move.sets,
          ifAbsent: () => move.sets,
        );
      }
      final requiredToday = {
        ...group.requiredMuscles,
        ...group.optionalPriorityMuscles.intersection(config.priorities),
      };
      final missing = requiredToday.difference(primary).toList()..sort();
      if (missing.isNotEmpty) {
        issue(
          TrainingIssueCode.missingMuscles,
          'Direct muscle coverage is missing from a training day.',
          ['day:${day.weekday}', ...missing],
        );
      }
      final missingPatterns =
          group.requiredPatterns.difference(patterns).toList()..sort();
      if (day.exercises.isNotEmpty &&
          day.exercises.every((e) => e.patterns.isNotEmpty) &&
          missingPatterns.isNotEmpty) {
        issue(
          TrainingIssueCode.missingPatterns,
          'Required movement patterns are missing from a training day.',
          ['day:${day.weekday}', ...missingPatterns],
        );
      }
      if (day.estimatedSeconds > config.sessionMinutes * 60) {
        issue(
          TrainingIssueCode.durationExceeded,
          'The complete prescription exceeds the available session time.',
          [
            'day:${day.weekday}',
            'estimated_seconds:${day.estimatedSeconds}',
            'available_seconds:${config.sessionMinutes * 60}',
          ],
        );
      }
    }
    for (final muscle in required.toList()..sort()) {
      final weekdays = exposures[muscle]?.toList() ?? <int>[];
      weekdays.sort();
      if (weekdays.length < rules.minimumWeeklyExposures) {
        issue(
          TrainingIssueCode.insufficientFrequency,
          'A muscle has insufficient direct weekly training frequency.',
          [muscle],
        );
      }
      if ((volume[muscle] ?? 0) > rules.maximumWeeklySetsPerMuscle) {
        issue(
          TrainingIssueCode.volumeExceeded,
          'The weekly direct-set limit would be exceeded.',
          [muscle],
        );
      }
      if (weekdays.length > 1) {
        for (var i = 0; i < weekdays.length; i++) {
          final next = weekdays[(i + 1) % weekdays.length];
          final gap = (next - weekdays[i] + 7) % 7;
          if (gap < rules.minimumRecoveryDays) {
            issue(
              TrainingIssueCode.recoveryConflict,
              'The selected weekdays do not provide the configured recovery spacing.',
              [muscle, 'from:${weekdays[i]}', 'to:$next'],
            );
          }
        }
      }
    }
    return List.unmodifiable(issues);
  }
}
