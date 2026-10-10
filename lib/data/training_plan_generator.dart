import 'training_plan_models.dart';
import 'training_programming_rules.dart';
import 'training_coverage_validator.dart';

/// Pure, deterministic proposal generation. No network, IDs invented, or writes.
/// Programming rules and catalog retrieval are independent inputs.
class TrainingPlanGenerator {
  TrainingGenerationResult generate(
    TrainingPlanConfig config,
    TrainingCatalog catalog, {
    TrainingProgrammingRules? rules,
  }) {
    final policy = rules ?? TrainingProgrammingRules.defaults();
    final eligible = catalog.exercises.where((e) => e.usable).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final issues = <TrainingIssue>[...catalog.issues];
    void issue(
      TrainingIssueCode code,
      String message, [
      Iterable<String> details = const [],
    ]) {
      issues.add(TrainingIssue(code, message, details: details));
    }

    if (config.weekdays.toSet().length != config.weekdays.length ||
        config.weekdays.any((d) => d < 1 || d > 7) ||
        config.sessionMinutes < 10 ||
        config.sessionMinutes > 120 ||
        !{30, 60, 90}.contains(config.journeyDays) ||
        config.priorities.length > policy.maximumPriorities ||
        config.equipment.isEmpty ||
        config.equipment.any(
          (s) => !RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(s),
        )) {
      issue(
        TrainingIssueCode.invalidConfiguration,
        'Choose valid days, duration, equipment and bounded priorities.',
      );
    }
    if (config.age < 18 || config.age > 120 || config.hasReportedLimitations) {
      issue(
        TrainingIssueCode.safetyReviewRequired,
        'This proposed healthy-adult programming scope requires a suitability review for your configuration.',
      );
    }
    // Location constrains previews only; activation is not implemented.
    if (!{'gym', 'home'}.contains(config.location)) {
      issue(
        TrainingIssueCode.unsupportedLocation,
        'Choose Gym or Home for this training block.',
      );
    }
    final split = policy.splits[config.weekdays.length];
    if (split == null) {
      issue(
        TrainingIssueCode.unsupportedFrequency,
        'This rule manifest does not support the requested training frequency.',
      );
    }
    final supportedPriorities = policy.groups.values
        .expand((g) => {...g.requiredMuscles, ...g.optionalPriorityMuscles})
        .toSet();
    final unsupported =
        config.priorities.difference(supportedPriorities).toList()..sort();
    if (unsupported.isNotEmpty) {
      issue(
        TrainingIssueCode.unsupportedPriority,
        'These priorities are not supported by the current rule scope.',
        unsupported,
      );
    }
    if (catalog.exercises.map((e) => e.id).toSet().length !=
        catalog.exercises.length) {
      issue(
        TrainingIssueCode.invalidCatalog,
        'The catalog contains duplicate stable exercise IDs.',
      );
    }
    final configCodes = {
      TrainingIssueCode.invalidConfiguration,
      TrainingIssueCode.safetyReviewRequired,
      TrainingIssueCode.unsupportedLocation,
      TrainingIssueCode.unsupportedFrequency,
      TrainingIssueCode.unsupportedPriority,
      TrainingIssueCode.invalidCatalog,
    };
    if (issues.any((i) => configCodes.contains(i.code))) {
      return TrainingGenerationResult(
        catalogCount: catalog.exercises.length,
        eligibleCount: eligible.length,
        issues: issues,
      );
    }
    if (eligible.isEmpty) {
      issue(
        TrainingIssueCode.noEligibleExercises,
        'No published exercises have usable catalog metadata.',
      );
    }

    final days = <PlannedTrainingDay>[];
    final prescription = policy.prescriptions[config.goal]!;
    final baseSets = prescription.setsByExperience[config.experience]!;
    for (var i = 0; i < split!.length; i++) {
      final group = policy.groups[split[i]]!;
      final targets = {
        ...group.requiredMuscles,
        ...group.optionalPriorityMuscles.intersection(config.priorities),
      }.toList()..sort();
      final selected = <TrainingCatalogExercise>[];
      final coveredPatterns = <String>{};
      List<TrainingCatalogExercise> compatible(String target) {
        final all = eligible
            .where((e) => e.metadata.primaryMuscle == target)
            .toList();
        final level = all
            .where(
              (e) => e.metadata.minimumExperience <= config.experience.index,
            )
            .toList();
        if (all.isNotEmpty && level.isEmpty) {
          issue(
            TrainingIssueCode.experienceUnavailable,
            'No eligible exercise for this target fits the experience level.',
            [target],
          );
        }
        final matching = level
            .where(
              (e) =>
                  e.metadata.locations.contains(config.location) &&
                  config.equipment.containsAll(e.metadata.requiredEquipment),
            )
            .toList();
        if (level.isNotEmpty && matching.isEmpty) {
          issue(
            TrainingIssueCode.equipmentUnavailable,
            'No eligible exercise for this target fits the available equipment/location.',
            [target],
          );
        }
        return matching;
      }

      // Prefer explicit unmet patterns, then estimated time cost, then UUID.
      void rank(List<TrainingCatalogExercise> candidates) {
        final needed = group.requiredPatterns.difference(coveredPatterns);
        candidates.sort((a, b) {
          final ac = a.metadata, bc = b.metadata;
          final patterns = bc.patterns
              .intersection(needed)
              .length
              .compareTo(ac.patterns.intersection(needed).length);
          if (patterns != 0) return patterns;
          final time = ac.workSecondsPerSet.compareTo(bc.workSecondsPerSet);
          return time != 0 ? time : a.id.compareTo(b.id);
        });
      }

      for (final target in targets) {
        final candidates = compatible(target);
        if (candidates.isEmpty) continue;
        rank(candidates);
        selected.add(candidates.first);
        coveredPatterns.addAll(candidates.first.metadata.patterns);
      }
      // A pattern gap can only be filled by a direct target belonging to this split.
      for (final pattern in group.requiredPatterns.toList()..sort()) {
        if (coveredPatterns.contains(pattern)) continue;
        final candidates = eligible.where((e) {
          final c = e.metadata;
          return targets.contains(c.primaryMuscle) &&
              c.patterns.contains(pattern) &&
              !selected.contains(e) &&
              c.minimumExperience <= config.experience.index &&
              c.locations.contains(config.location) &&
              config.equipment.containsAll(c.requiredEquipment);
        }).toList();
        rank(candidates);
        if (candidates.isNotEmpty) {
          selected.add(candidates.first);
          coveredPatterns.addAll(candidates.first.metadata.patterns);
        }
      }
      int patternOrder(TrainingCatalogExercise exercise) {
        final indexes = exercise.metadata.patterns
            .map(policy.exercisePatternOrder.indexOf)
            .where((n) => n >= 0);
        return indexes.isEmpty
            ? policy.exercisePatternOrder.length
            : indexes.reduce((a, b) => a < b ? a : b);
      }

      selected.sort((a, b) {
        final order = patternOrder(a).compareTo(patternOrder(b));
        return order != 0 ? order : a.id.compareTo(b.id);
      });
      days.add(
        PlannedTrainingDay(
          weekday: config.weekdays[i],
          split: split[i],
          warmupSeconds: policy.warmupSeconds,
          exercises: selected.map(
            (e) => PlannedTrainingExercise(
              exercise: e,
              sets:
                  baseSets +
                  (config.priorities.contains(e.metadata.primaryMuscle)
                      ? policy.priorityExtraSets
                      : 0),
              reps: prescription.reps,
              restSeconds: prescription.restSeconds,
              transitionSeconds: policy.transitionSeconds,
            ),
          ),
        ),
      );
    }
    issues.addAll(
      TrainingCoverageValidator.validate(config, days, catalog, policy),
    );
    final unique = <String, TrainingIssue>{};
    for (final item in issues) {
      unique['${item.code.name}:${item.details.join('|')}'] = item;
    }
    final problems = unique.values.toList();
    final preview = problems.isEmpty
        ? TrainingPlanPreview(
            config: config,
            ruleVersion: policy.version,
            blockWeeks: policy.blockWeeks,
            days: days,
          )
        : null;
    return TrainingGenerationResult(
      catalogCount: catalog.exercises.length,
      eligibleCount: eligible.length,
      issues: problems,
      preview: preview,
    );
  }
}
