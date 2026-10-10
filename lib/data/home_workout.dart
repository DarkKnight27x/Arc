import 'exercise_media.dart';
import 'workout_models.dart';

const homeCapabilities = {'bodyweight', 'dumbbells', 'bands'};
Set<String>? equipmentCapabilities(String raw) =>
    switch (raw.trim().toLowerCase()) {
      'bodyweight' || 'body weight' => {'bodyweight'},
      'dumbbell' || 'dumbbells' => {'dumbbells'},
      'band' || 'resistance band' || 'resistance bands' => {'bands'},
      _ => null,
    };
String muscleGroup(String raw) => switch (raw.trim().toLowerCase()) {
  'pectorals' || 'chest' => 'Chest',
  'delts' || 'shoulders' => 'Shoulders',
  'upper back' || 'lats' || 'spine' => 'Back',
  'biceps' => 'Biceps',
  'triceps' => 'Triceps',
  'glutes' || 'quadriceps' || 'hamstrings' || 'calves' => 'Legs',
  'abs' || 'obliques' => 'Core',
  _ => raw,
};

class HomeMapping {
  HomeMapping.fromMap(Map<String, dynamic> m)
    : id = m['id'] as String,
      sourceId = m['source_exercise_id'] as String,
      alternativeId = m['alternative_exercise_id'] as String,
      version = m['version'] as int,
      primaryTarget = m['primary_target'] as String,
      pattern = m['movement_pattern'] as String,
      requiredEquipment = Set<String>.unmodifiable(
        (m['required_equipment'] as List).cast<String>(),
      ),
      sets = m['sets'] as int,
      minSets = m['min_sets'] as int,
      reps = m['reps'] as String,
      rest = m['rest_seconds'] as int,
      workSeconds = m['work_seconds_per_set'] as int,
      priority = m['priority'] as int,
      limitations = m['limitations'] as String,
      approved = m['review_status'] == 'approved' && m['enabled'] == true;
  final String id,
      sourceId,
      alternativeId,
      primaryTarget,
      pattern,
      reps,
      limitations;
  final Set<String> requiredEquipment;
  final int version, sets, minSets, rest, workSeconds, priority;
  final bool approved;
}

class HomeProposal {
  HomeProposal({
    required this.source,
    required List<WorkoutMove> moves,
    required Set<String> equipment,
    required this.requestedMinutes,
    required this.estimatedSeconds,
    required List<String> limitations,
  }) : moves = List.unmodifiable(moves),
       equipment = Set.unmodifiable(equipment),
       limitations = List.unmodifiable(limitations);
  final WorkoutDay source;
  final List<WorkoutMove> moves;
  final Set<String> equipment;
  final int? requestedMinutes;
  final int estimatedSeconds;
  final List<String> limitations;
  List<String> get originalTargets =>
      source.moves
          .map((m) => m.primaryTarget)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
  Set<String> get coveredTargets =>
      moves.map((m) => m.primaryTarget).whereType<String>().toSet();
  Set<String> get missingTargets =>
      originalTargets.toSet().difference(coveredTargets);
  bool get available => source.canStart && moves.isNotEmpty;
}

class HomeWorkoutEngine {
  static HomeProposal build(
    WorkoutDay day,
    List<HomeMapping> mappings,
    Map<String, Map<String, dynamic>> catalog,
    Set<String> equipment,
    int? minutes, {
    String Function(String)? gifUrl,
  }) {
    if (!equipment.contains('bodyweight') ||
        !homeCapabilities.containsAll(equipment) ||
        (minutes != null && minutes <= 0)) {
      throw ArgumentError('Invalid home options');
    }
    final limitations = <String>[];
    final picked =
        <
          ({
            WorkoutMove source,
            HomeMapping mapping,
            Map<String, dynamic> exercise,
          })
        >[];
    final used = <String>{};
    if (day.isRestDay || !day.canStart) {
      return HomeProposal(
        source: day,
        moves: [],
        equipment: equipment,
        requestedMinutes: minutes,
        estimatedSeconds: 0,
        limitations: [
          day.isRestDay
              ? 'This is a rest day.'
              : 'The original prescription is unavailable or empty.',
        ],
      );
    }
    for (final source in day.moves) {
      final candidates =
          mappings.where((m) {
            final ex = catalog[m.alternativeId];
            final capabilities = ex == null
                ? null
                : equipmentCapabilities(ex['equipment'] as String);
            return m.approved &&
                m.sourceId == source.exerciseId &&
                m.primaryTarget == source.primaryTarget &&
                m.sets >= m.minSets &&
                m.minSets > 0 &&
                m.rest >= 0 &&
                m.workSeconds > 0 &&
                capabilities != null &&
                m.requiredEquipment.containsAll(capabilities) &&
                equipment.containsAll(m.requiredEquipment) &&
                ex!['is_published'] == true &&
                ex['target_muscle'] == m.primaryTarget &&
                (ex['instructions'] as List).isNotEmpty;
          }).toList()..sort((a, b) {
            final version = b.version.compareTo(a.version);
            if (version != 0) return version;
            final priority = a.priority.compareTo(b.priority);
            return priority != 0 ? priority : a.id.compareTo(b.id);
          });
      if (candidates.isEmpty) {
        limitations.add(
          'No reviewed compatible replacement for ${source.name}.',
        );
        continue;
      }
      final choice = candidates.first;
      if (!used.add(choice.alternativeId)) {
        limitations.add(
          '${source.name} shares a selected alternative; its extra gym volume is not reproduced.',
        );
        continue;
      }
      picked.add((
        source: source,
        mapping: choice,
        exercise: catalog[choice.alternativeId]!,
      ));
    }
    // Budget includes setup/warm-up allowance, both-side work where curated,
    // between-set rests and transitions. It is an estimate, never a guarantee.
    int cost(HomeMapping m, int sets) =>
        sets * m.workSeconds + (sets - 1) * m.rest + 30;
    final selected = <int>[];
    final volumes = <int, int>{};
    final covered = <String>{};
    var seconds = 180;
    final remaining = List.generate(picked.length, (i) => i);
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final av = covered.contains(picked[a].mapping.primaryTarget) ? 1 : 0;
        final bv = covered.contains(picked[b].mapping.primaryTarget) ? 1 : 0;
        return av != bv
            ? av.compareTo(bv)
            : picked[a].source.sortOrder.compareTo(picked[b].source.sortOrder);
      });
      final index = remaining.removeAt(0);
      final m = picked[index].mapping;
      final volume = minutes == null ? m.sets : m.minSets;
      final duration = cost(m, volume);
      if (minutes != null && seconds + duration > minutes * 60) {
        limitations.add(
          '${picked[index].source.name} omitted to respect the estimated time budget.',
        );
        continue;
      }
      selected.add(index);
      volumes[index] = volume;
      seconds += duration;
      covered.add(m.primaryTarget);
    }
    if (minutes != null) {
      var changed = true;
      while (changed) {
        changed = false;
        for (final i in selected) {
          final m = picked[i].mapping;
          if (volumes[i]! < m.sets &&
              seconds + m.workSeconds + m.rest <= minutes * 60) {
            volumes[i] = volumes[i]! + 1;
            seconds += m.workSeconds + m.rest;
            changed = true;
          }
        }
      }
      limitations.add(
        'Shorter alternative: training volume and results are not equivalent to the gym session.',
      );
    }
    selected.sort(
      (a, b) =>
          picked[a].source.sortOrder.compareTo(picked[b].source.sortOrder),
    );
    final moves = selected.map((i) {
      final item = picked[i];
      final m = item.mapping;
      final ex = item.exercise;
      final path = ExerciseMediaPath.storedPath(ex['gif_path']);
      return WorkoutMove(
        id: item.source.id,
        exerciseId: m.alternativeId,
        sortOrder: item.source.sortOrder,
        name: ex['name'] as String,
        machine: ex['equipment'] as String,
        sets: volumes[i],
        reps: m.reps,
        restSeconds: m.rest,
        notes: m.limitations,
        primaryTarget: m.primaryTarget,
        secondaryTargets: List<String>.unmodifiable(
          ex['secondary_muscles'] as List,
        ),
        bodyPart: ex['body_part'] as String,
        mappingId: m.id,
        mappingVersion: m.version,
        movementPattern: m.pattern,
        gifPath: path,
        gifUrl: ExerciseMediaPath.resolve(path, storageUrl: gifUrl),
        instructions: List<String>.unmodifiable(ex['instructions'] as List),
      );
    }).toList();
    final targets = day.moves
        .map((m) => m.primaryTarget)
        .whereType<String>()
        .toSet();
    final missing = targets.difference(covered);
    if (missing.isNotEmpty) {
      limitations.add('Not covered: ${missing.map(muscleGroup).join(', ')}.');
    }
    if (day.moves.any((m) => m.primaryTarget == null)) {
      limitations.add('Some original muscle targets are unspecified.');
    }
    if (moves.isEmpty) {
      limitations.add(
        'No valid home workout for these equipment and time choices. Try Gym or another equipment choice.',
      );
    }
    return HomeProposal(
      source: day,
      moves: moves,
      equipment: equipment,
      requestedMinutes: minutes,
      estimatedSeconds: moves.isEmpty ? 0 : seconds,
      limitations: limitations,
    );
  }
}
