import 'dart:convert';
import 'dart:io';

import 'package:arc/data/training_plan_generator.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

// Offline snapshot fetched through the hosted public API after the authorized
// insertion. These are real UUIDs; this test never contacts or writes Supabase.
List<Map<String, dynamic>> realRows() => (jsonDecode(
  File('docs/curated_catalog_v1_public_api_catalog.json').readAsStringSync(),
) as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();

TrainingPlanConfig configuration(
  List<int> days,
  Set<String> priorities,
  Set<String> equipment, {
  int minutes = 60,
}) => TrainingPlanConfig(
  goal: TrainingGoal.buildMuscle,
  experience: TrainingExperience.beginner,
  weekdays: days,
  priorities: priorities,
  equipment: equipment,
  age: 25,
  sessionMinutes: minutes,
  journeyDays: 30,
  location: 'gym',
);

void main() {
  test('real curated rows remain published and eligible without media or invented classifications', () {
    final rows = realRows();
    expect(rows, hasLength(78));
    final newRows = rows
        .where(
          (r) =>
              (r['source_external_id'] as String).startsWith('arc_curated_v1_'),
        )
        .toList();
    expect(newRows, hasLength(48));
    expect(rows.map((r) => r['source_external_id']).toSet(), hasLength(78));
    final expected = (jsonDecode(
      File('docs/curated_catalog_v1_insert_rows.json').readAsStringSync(),
    ) as List).cast<Map>();
    for (final row in newRows) {
      expect(row['gif_path'], isNull);
      expect(row['difficulty'], isNull);
      expect(row['tags'], isEmpty);
      expect(row['is_published'], true);
      expect(row['instructions'], hasLength(5));
      expect(TrainingCatalogExercise.fromMap(row).usable, true);
      final reviewed = expected.singleWhere(
        (r) => r['source_external_id'] == row['source_external_id'],
      );
      expect({for (final key in reviewed.keys) key: row[key]}, reviewed);
    }
  });
  test(
    'updated real catalog supports all required balanced and priority previews',
    () {
      final catalog = TrainingCatalog(
        realRows().map(TrainingCatalogExercise.fromMap),
      );
      final equipment = catalog.exercises
          .expand((e) => e.metadata.requiredEquipment)
          .toSet();
      final cases = [
        ([1, 4], <String>{}),
        ([1, 3, 5], <String>{}),
        ([1, 2, 4, 5], <String>{}),
        for (final p in ['chest', 'biceps', 'quadriceps', 'hamstrings'])
          ([1, 4], {p}),
        ([1, 4], {'chest', 'quadriceps', 'hamstrings'}),
      ];
      for (final (days, priorities) in cases) {
        final result = TrainingPlanGenerator().generate(
          configuration(days, priorities, equipment),
          catalog,
        );
        expect(
          result.available,
          true,
          reason: '$days $priorities ${result.issues.map((i) => i.toMap())}',
        );
        expect(result.canActivate, false);
        expect(result.preview!.days, hasLength(days.length));
        expect(
          result.preview!.days.every((d) => d.estimatedSeconds <= 60 * 60),
          true,
        );
        for (final day in result.preview!.days) {
          for (final move in day.exercises) {
            expect(move.sets, priorities.contains(move.primaryMuscle) ? 3 : 2);
            expect(realRows().any((r) => r['id'] == move.exercise.id), true);
          }
        }
      }
    },
  );
  test('catalog expansion keeps equipment, time, recovery and missing-priority constraints', () {
    final catalog = TrainingCatalog(
      realRows().map(TrainingCatalogExercise.fromMap),
    );
    final equipment = catalog.exercises
        .expand((e) => e.metadata.requiredEquipment)
        .toSet();
    final cases = [
      (
        configuration([1, 4], {}, {'bodyweight'}),
        TrainingIssueCode.missingMuscles,
      ),
      (
        configuration([1, 4], {}, equipment, minutes: 20),
        TrainingIssueCode.durationExceeded,
      ),
      (
        configuration([1, 2], {}, equipment),
        TrainingIssueCode.recoveryConflict,
      ),
      (
        configuration([1, 4], {'adductors'}, equipment),
        TrainingIssueCode.missingMuscles,
      ),
    ];
    for (final (config, code) in cases) {
      final result = TrainingPlanGenerator().generate(config, catalog);
      expect(result.available, false);
      expect(result.issues.any((i) => i.code == code), true);
      expect(result.canActivate, false);
    }
  });
}
