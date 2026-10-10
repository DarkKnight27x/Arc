import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:arc/data/training_programming_rules.dart';
import 'package:arc/data/training_plan_generator.dart';
import 'package:arc/data/training_coverage_validator.dart';
import 'package:arc/data/training_catalog_source.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_session.dart';

import 'profile_test.dart' show testClient, testSession, testUserId;
import 'workout_test.dart' show jsonResponse;

String fixtureId(int n) =>
    '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

Map<String, dynamic> catalogRow(
  int n,
  String target, {
  bool published = true,
}) => {
  'id': fixtureId(n),
  'name': 'Synthetic exercise $n',
  'body_part': target,
  'target_muscle': target,
  'secondary_muscles': ['quadriceps', 'hamstrings'],
  'equipment': 'dumbbell',
  'difficulty': null,
  'instructions': ['Synthetic instruction'],
  'gif_path': null,
  'tags': <String>[],
  'is_published': published,
};

TrainingCatalogExercise classified(
  int n,
  String target,
  String pattern, {
  bool published = true,
  int level = 0,
  List<String> equipment = const ['dumbbells'],
}) => TrainingCatalogExercise.fromMap({
  ...catalogRow(n, target, published: published),
  'movement_patterns': [pattern],
  'required_equipment': equipment,
  'allowed_locations': ['gym'],
  'difficulty': ['beginner', 'intermediate', 'advanced'][level],
});

final fixturePatterns = <String, String>{
  'abs': 'core',
  'biceps': 'elbow_flexion',
  'calves': 'plantar_flexion',
  'chest': 'horizontal_push',
  'glutes': 'hip_extension',
  'hamstrings': 'hip_hinge',
  'lats': 'vertical_pull',
  'quadriceps': 'knee_dominant',
  'shoulders': 'vertical_push',
  'triceps': 'elbow_extension',
  'upper_back': 'horizontal_pull',
};
List<TrainingCatalogExercise> completeFixture() => fixturePatterns
    .entries
    .indexed
    .map((e) => classified(e.$1 + 1, e.$2.key, e.$2.value))
    .toList();

TrainingPlanConfig config({
  TrainingGoal goal = TrainingGoal.buildMuscle,
  TrainingExperience experience = TrainingExperience.beginner,
  List<int> days = const [1, 4],
  Set<String> equipment = const {'dumbbells', 'bodyweight'},
  Set<String> priorities = const {},
  int minutes = 90,
  int journeyDays = 30,
  int age = 25,
  bool limitations = false,
  String location = 'gym',
}) => TrainingPlanConfig(
  goal: goal,
  experience: experience,
  weekdays: days,
  equipment: equipment,
  priorities: priorities,
  sessionMinutes: minutes,
  journeyDays: journeyDays,
  age: age,
  hasReportedLimitations: limitations,
  location: location,
);

TrainingProgrammingRules fixtureRules({
  int maximumSets = 12,
  int recovery = 2,
  int extra = 1,
}) {
  final p = TrainingProgrammingRules.defaults();
  return TrainingProgrammingRules(
    version: 'synthetic-rule-fixture-v1',
    groups: p.groups,
    splits: p.splits,
    prescriptions: p.prescriptions,
    maximumWeeklySetsPerMuscle: maximumSets,
    minimumRecoveryDays: recovery,
    priorityExtraSets: extra,
  );
}

TrainingGenerationResult generate(
  TrainingPlanConfig c, {
  List<TrainingCatalogExercise>? exercises,
  TrainingProgrammingRules? rules,
}) => TrainingPlanGenerator().generate(
  c,
  TrainingCatalog(exercises ?? completeFixture()),
  rules: rules ?? fixtureRules(),
);

void main() {
  test('journey choices are separate from the initial four-week block', () {
    for (final days in [30, 60, 90]) {
      final result = generate(config(journeyDays: days));
      expect(result.available, true);
      expect(result.preview!.blockWeeks, 4);
      expect(result.preview!.toMap()['journey_days'], days);
    }
  });
  test('missing direct back coverage is unavailable', () {
    final result = generate(
      config(),
      exercises: completeFixture()
          .where(
            (e) => !{'upper_back', 'lats'}.contains(e.metadata.primaryMuscle),
          )
          .toList(),
    );
    expect(result.available, false);
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.missingMuscles &&
            i.details.contains('upper_back') &&
            i.details.contains('lats'),
      ),
      true,
    );
  });
  test('Home preview respects explicit library location restrictions', () {
    final rows = fixturePatterns.keys.indexed
        .map(
          (e) => TrainingCatalogExercise.fromMap({
            ...catalogRow(e.$1 + 1, e.$2),
            'allowed_locations': ['home'],
          }),
        )
        .toList();
    expect(generate(config(location: 'home'), exercises: rows).available, true);
    expect(generate(config(location: 'gym'), exercises: rows).available, false);
  });
  test(
    'preview includes every weekday/rest day and a shorter journey block',
    () {
      final result = generate(config(journeyDays: 30));
      expect(result.preview!.blockWeeks, 4);
      expect(result.preview!.week.length, 7);
      expect(
        result.preview!.week.where((day) => day['rest_day'] == true).length,
        5,
      );
      expect(result.toMap()['status'], 'available_for_review');
      expect(result.toMap()['can_activate'], false);
      expect(
        result.preview!.days.first.exercises.first.patterns,
        contains('knee_dominant'),
      );
    },
  );
  for (final goal in TrainingGoal.values) {
    for (final level in TrainingExperience.values) {
      test('complete synthetic program for ${goal.name}/${level.name}', () {
        final result = generate(config(goal: goal, experience: level));
        expect(
          result.available,
          true,
          reason: result.issues.map((e) => e.toMap()).toString(),
        );
        final policy = fixtureRules().prescriptions[goal]!;
        for (final day in result.preview!.days) {
          expect(
            day.exercises.every(
              (e) =>
                  e.sets == policy.setsByExperience[level] &&
                  e.reps == policy.reps &&
                  e.restSeconds == policy.restSeconds,
            ),
            true,
          );
        }
        expect(result.canActivate, false);
        expect(result.preview!.canActivate, false);
      });
    }
  }
  final weekdays = {
    2: [1, 4],
    3: [1, 3, 5],
    4: [1, 2, 4, 5],
    5: [1, 2, 3, 4, 5],
    6: [1, 2, 3, 4, 5, 6],
  };
  for (final entry in weekdays.entries) {
    test('selects appropriate split for ${entry.key} training days', () {
      final result = generate(config(days: entry.value));
      expect(
        result.available,
        true,
        reason: result.issues.map((e) => e.toMap()).toString(),
      );
      expect(
        result.preview!.days.map((d) => d.split),
        fixtureRules().splits[entry.key],
      );
      expect(result.preview!.days.map((d) => d.weekday), entry.value);
    });
  }
  test(
    'single/multiple priorities add bounded emphasis and retain balance',
    () {
      for (final priorities in [
        {'chest'},
        {'chest', 'hamstrings', 'biceps'},
      ]) {
        final result = generate(config(priorities: priorities));
        expect(result.available, true);
        for (final day in result.preview!.days) {
          expect(
            day.exercises.map((e) => e.primaryMuscle).toSet(),
            fixturePatterns.keys.toSet(),
          );
          for (final move in day.exercises) {
            expect(move.sets, priorities.contains(move.primaryMuscle) ? 3 : 2);
          }
        }
      }
    },
  );
  test(
    'optional muscle priority requires genuine direct exercise coverage',
    () {
      final missing = generate(config(priorities: {'forearms'}));
      expect(missing.available, false);
      expect(
        missing.issues.any(
          (i) =>
              i.code == TrainingIssueCode.missingMuscles &&
              i.details.contains('forearms'),
        ),
        true,
      );
      final expanded = generate(
        config(priorities: {'forearms'}),
        exercises: [
          ...completeFixture(),
          classified(99, 'forearms', 'wrist_flexion'),
        ],
      );
      expect(expanded.available, true);
    },
  );
  test('secondary targets cannot replace missing direct leg coverage', () {
    final result = generate(
      config(),
      exercises: completeFixture()
          .where((e) => e.metadata.primaryMuscle != 'quadriceps')
          .toList(),
    );
    expect(result.available, false);
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.missingMuscles &&
            i.details.contains('quadriceps'),
      ),
      true,
    );
  });
  test('coverage reports missing movement patterns separately', () {
    final ex = completeFixture();
    ex[fixturePatterns.keys.toList().indexOf('hamstrings')] = classified(
      88,
      'hamstrings',
      'knee_flexion',
    );
    final result = generate(config(), exercises: ex);
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.missingPatterns &&
            i.details.contains('hip_hinge'),
      ),
      true,
    );
    expect(result.preview, isNull);
  });
  test('equipment and required support surfaces are all mandatory', () {
    final ex = completeFixture();
    ex[fixturePatterns.keys.toList().indexOf('chest')] = classified(
      88,
      'chest',
      'horizontal_push',
      equipment: ['dumbbells', 'bench'],
    );
    final missing = generate(config(), exercises: ex);
    expect(
      missing.issues.any(
        (i) => i.code == TrainingIssueCode.equipmentUnavailable,
      ),
      true,
    );
    expect(
      generate(
        config(equipment: {'dumbbells', 'bench'}),
        exercises: ex,
      ).available,
      true,
    );
  });
  test('beginner cannot use advanced-only classified exercise', () {
    final ex = completeFixture();
    ex[0] = classified(88, 'abs', 'core', level: 2);
    expect(
      generate(
        config(),
        exercises: ex,
      ).issues.any((i) => i.code == TrainingIssueCode.experienceUnavailable),
      true,
    );
    expect(
      generate(
        config(experience: TrainingExperience.advanced),
        exercises: ex,
      ).available,
      true,
    );
  });
  test('short time budget never silently omits essential work', () {
    final result = generate(config(minutes: 10));
    expect(result.available, false);
    expect(
      result.issues.any((i) => i.code == TrainingIssueCode.durationExceeded),
      true,
    );
    expect(result.preview, isNull);
  });
  test('recovery includes the Sunday-to-Monday boundary', () {
    final result = generate(config(days: [1, 7]));
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.recoveryConflict &&
            i.details.contains('from:7') &&
            i.details.contains('to:1'),
      ),
      true,
    );
    expect(result.preview, isNull);
  });
  test('volume ceiling rejects excessive priority additions', () {
    final result = generate(
      config(days: [1, 3, 5], priorities: {'chest'}),
      rules: fixtureRules(maximumSets: 8),
    );
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.volumeExceeded &&
            i.details.contains('chest'),
      ),
      true,
    );
  });
  test('published library metadata controls eligibility without approvals', () {
    final row = catalogRow(1, 'chest');
    expect(TrainingCatalogExercise.fromMap(row).usable, true);
    for (final patch in [
      {'is_published': false},
      {'id': 'bad'},
      {'name': ''},
      {'target_muscle': null},
      {'target_muscle': ''},
      {'equipment': ''},
      {'equipment': 42},
      {'instructions': null},
      {'instructions': []},
      {
        'instructions': ['ok', null],
      },
      {
        'instructions': [' '],
      },
      {'difficulty': 'unknown'},
      {
        'movement_patterns': ['bad pattern'],
      },
    ]) {
      expect(
        TrainingCatalogExercise.fromMap({...row, ...patch}).usable,
        false,
        reason: patch.toString(),
      );
    }
  });
  test('default rules use direct coverage when patterns are absent', () {
    final data = TrainingCatalog(
      fixturePatterns.keys.indexed.map(
        (e) => TrainingCatalogExercise.fromMap(catalogRow(e.$1 + 1, e.$2)),
      ),
    );
    expect(TrainingPlanGenerator().generate(config(), data).available, true);
  });
  test('actual catalog is eligible but cannot cover missing legs', () {
    final audit = jsonDecode(
      File('docs/phase2c_readonly_database_audit.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ex = (audit['catalog_rows'] as List)
        .map(
          (r) => TrainingCatalogExercise.fromMap(Map<String, dynamic>.from(r)),
        )
        .toList();
    final result = generate(
      config(equipment: ex.expand((e) => e.metadata.requiredEquipment).toSet()),
      exercises: ex,
    );
    expect(result.eligibleCount, ex.length);
    expect(result.available, false);
    expect(result.preview, isNull);
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.missingMuscles &&
            i.details.contains('hamstrings'),
      ),
      true,
    );
    expect(
      result.issues.any(
        (i) =>
            i.code == TrainingIssueCode.missingMuscles &&
            i.details.contains('quadriceps'),
      ),
      true,
    );
  });
  test(
    'catalog expansion and permutation need no generator source changes',
    () {
      final ex = completeFixture();
      final added = classified(0, 'chest', 'horizontal_push');
      final baseline = generate(config(), exercises: ex).preview!.toMap();
      final expanded = generate(config(), exercises: [...ex, added]);
      expect(expanded.available, true);
      expect(
        expanded.preview!.days.first.exercises.any(
          (e) => e.exercise.id == added.id,
        ),
        true,
      );
      expect(expanded.preview!.toMap(), isNot(baseline));
      expect(
        generate(config(), exercises: [added, ...ex.reversed]).preview!.toMap(),
        expanded.preview!.toMap(),
      );
    },
  );
  test(
    'malformed preferences, unsupported scope and duplicate IDs fail closed',
    () {
      final cases = [
        config(days: [1]),
        config(days: [1, 2, 3, 4, 5, 6, 7]),
        config(days: [1, 1]),
        config(days: [0, 4]),
        config(minutes: 0),
        config(journeyDays: 0),
        config(age: 17),
        config(limitations: true),
        config(location: 'home'),
        config(priorities: {'hair'}),
        config(priorities: {'chest', 'biceps', 'triceps', 'calves'}),
      ];
      for (final c in cases) {
        expect(generate(c).available, false);
        expect(generate(c).preview, isNull);
      }
      expect(
        generate(
          config(),
          exercises: [...completeFixture(), completeFixture().first],
        ).issues.any((i) => i.code == TrainingIssueCode.invalidCatalog),
        true,
      );
    },
  );
  test('rules, catalog snapshots and output are immutable', () {
    final row = catalogRow(1, 'chest');
    final ex = TrainingCatalogExercise.fromMap(row);
    (row['instructions'] as List).add('Caller mutation');
    expect(ex.usable, true);
    expect(
      () => (ex.sourceSnapshot['instructions'] as List).add('Bad'),
      throwsUnsupportedError,
    );
    expect(() => fixtureRules().splits[2]!.add('Bad'), throwsUnsupportedError);
  });
  test('validator rejects tampered prescription and non-catalog objects', () {
    final catalog = TrainingCatalog(completeFixture());
    final c = config();
    final result = TrainingPlanGenerator().generate(
      c,
      catalog,
      rules: fixtureRules(),
    );
    final days = result.preview!.days;
    final original = days.first.exercises.first;
    final bad = PlannedTrainingDay(
      weekday: days.first.weekday,
      split: days.first.split,
      warmupSeconds: days.first.warmupSeconds,
      exercises: [
        PlannedTrainingExercise(
          exercise: original.exercise,
          sets: 99,
          reps: original.reps,
          restSeconds: original.restSeconds,
          transitionSeconds: 30,
        ),
        ...days.first.exercises.skip(1),
      ],
    );
    expect(
      TrainingCoverageValidator.validate(
        c,
        [bad, ...days.skip(1)],
        catalog,
        fixtureRules(),
      ).any((i) => i.code == TrainingIssueCode.invalidConfiguration),
      true,
    );
  });
  test(
    'generated prescription values fit existing Train/parser/session contracts',
    () {
      final result = generate(config());
      final planned = result.preview!.days.first;
      // Persisted source IDs are deliberately supplied by a disposable fixture,
      // never invented by the generator or passed to live activation.
      final rows = planned.exercises.indexed
          .map(
            (e) => {
              'id': fixtureId(100 + e.$1),
              'exercise_id': e.$2.exercise.id,
              'sort_order': e.$1,
              'sets': e.$2.sets,
              'reps': e.$2.reps,
              'rest_seconds': e.$2.restSeconds,
              'notes': null,
              'exercise_library': {
                'name': e.$2.exercise.name,
                ...e.$2.exercise.sourceSnapshot,
                'is_published': true,
              },
            },
          )
          .toList();
      final day = WorkoutService.parseDays([
        {
          'id': fixtureId(300),
          'workout_plan_id': fixtureId(400),
          'weekday': planned.weekday,
          'title': planned.split,
          'estimated_minutes': (planned.estimatedSeconds / 60).ceil(),
          'notes': null,
          'workout_day_exercises': rows,
        },
      ]).single;
      expect(day.canStart, true);
      expect(workoutWeek(fixtureId(400), [day]).length, 7);
      final session = WorkoutSession.start(testUserId, day);
      expect(session.sessionVariant, 'gym_original');
      expect(
        session.exercises.map((m) => m.exerciseId),
        planned.exercises.map((m) => m.exercise.id),
      );
      expect(
        session.sourcePrescription.map((m) => m.id),
        rows.map((m) => m['id']),
      );
      expect(
        session.totalSets,
        planned.exercises.fold<int>(0, (n, m) => n + m.sets),
      );
    },
  );
  test(
    'catalog loader paginates actual rows without querying approval schema',
    () async {
      final requests = <Uri>[];
      final client = testClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('exercise_generation_profiles')) {
          return jsonResponse({'message': 'missing', 'code': 'PGRST205'}, 404);
        }
        final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
        return jsonResponse(
          offset == 0
              ? [catalogRow(1, 'chest'), catalogRow(2, 'biceps')]
              : offset == 2
              ? [catalogRow(3, 'abs')]
              : [],
        );
      });
      addTearDown(client.dispose);
      await testSession(client);
      final data = await SupabaseTrainingCatalogSource(
        client,
        pageSize: 500,
      ).load();
      expect(data.exercises.length, 3);
      expect(data.exercises.every((e) => e.usable), true);
      expect(data.issues, isEmpty);
      expect(
        requests.any((u) => u.path.endsWith('exercise_generation_profiles')),
        false,
      );
      expect(
        requests.where((u) => u.path.endsWith('exercise_library')).length,
        3,
      );
    },
  );
}
