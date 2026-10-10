// Pure, read-only generator verification over an exported real catalog.
// Does not initialize Supabase, activate plans or write user records.
import 'dart:convert';
import 'dart:io';

import 'package:arc/data/training_plan_generator.dart';
import 'package:arc/data/training_plan_models.dart';

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError('Input catalog JSON and output report JSON required');
  }
  final rows = (jsonDecode(File(args[0]).readAsStringSync()) as List)
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();
  final catalog = TrainingCatalog(rows.map(TrainingCatalogExercise.fromMap));
  final allEquipment = catalog.exercises
      .expand((e) => e.metadata.requiredEquipment)
      .toSet();
  final cases =
      <
        ({
          String name,
          List<int> days,
          Set<String> priorities,
          Set<String> equipment,
          int minutes,
        })
      >[
        (
          name: '2_day_balanced',
          days: [1, 4],
          priorities: {},
          equipment: allEquipment,
          minutes: 60,
        ),
        (
          name: '3_day_balanced',
          days: [1, 3, 5],
          priorities: {},
          equipment: allEquipment,
          minutes: 60,
        ),
        (
          name: '4_day_balanced',
          days: [1, 2, 4, 5],
          priorities: {},
          equipment: allEquipment,
          minutes: 60,
        ),
        for (final priority in ['chest', 'biceps', 'quadriceps', 'hamstrings'])
          (
            name: '${priority}_priority',
            days: [1, 4],
            priorities: {priority},
            equipment: allEquipment,
            minutes: 60,
          ),
        (
          name: 'multiple_priorities',
          days: [1, 4],
          priorities: {'chest', 'quadriceps', 'hamstrings'},
          equipment: allEquipment,
          minutes: 60,
        ),
        (
          name: 'dumbbells_bodyweight',
          days: [1, 4],
          priorities: {},
          equipment: {'dumbbells', 'bodyweight'},
          minutes: 60,
        ),
        (
          name: 'bodyweight_only',
          days: [1, 4],
          priorities: {},
          equipment: {'bodyweight'},
          minutes: 60,
        ),
        (
          name: '20_minutes',
          days: [1, 4],
          priorities: {},
          equipment: allEquipment,
          minutes: 20,
        ),
        (
          name: 'adjacent_full_body_days',
          days: [1, 2],
          priorities: {},
          equipment: allEquipment,
          minutes: 60,
        ),
        (
          name: 'adductors_priority',
          days: [1, 4],
          priorities: {'adductors'},
          equipment: allEquipment,
          minutes: 60,
        ),
      ];
  final results = <Map<String, Object?>>[];
  for (final c in cases) {
    final result = TrainingPlanGenerator().generate(
      TrainingPlanConfig(
        goal: TrainingGoal.buildMuscle,
        experience: TrainingExperience.beginner,
        age: 25,
        location: 'gym',
        journeyDays: 30,
        weekdays: c.days,
        priorities: c.priorities,
        equipment: c.equipment,
        sessionMinutes: c.minutes,
      ),
      catalog,
    );
    final record = <String, Object?>{
      'case': c.name,
      'weekdays': c.days,
      'priorities': c.priorities.toList(),
      'equipment': c.equipment.toList()..sort(),
      'session_minutes': c.minutes,
      'available': result.available,
      'can_activate': result.canActivate,
      'catalog_count': result.catalogCount,
      'eligible_count': result.eligibleCount,
      'issues': result.issues.map((i) => i.toMap()).toList(),
      if (result.preview != null) 'preview': result.preview!.toMap(),
    };
    results.add(record);
    stdout.writeln(
      '${c.name}: ${result.available ? "PASS" : "UNAVAILABLE"} ${result.issues.map((i) => "${i.code.name}:${i.details.join(',')}").join('; ')}',
    );
  }
  File(args[1]).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'verified_at_utc': DateTime.now().toUtc().toIso8601String(), 'source_catalog': args[0], 'no_activation_or_persistence': true, 'cases': results})}\n',
  );
  // Required eight scenarios and useful dumbbells/bodyweight must succeed.
  if (results.take(9).any((r) => r['available'] != true)) exitCode = 1;
}
