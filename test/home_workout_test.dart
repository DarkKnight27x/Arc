import 'dart:convert';
import 'dart:io';

import 'package:arc/data/home_workout.dart';
import 'package:arc/data/home_workout_service.dart';
import 'package:arc/data/training_context_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/data/workout_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_test.dart' show testClient, testSession, testUserId;
import 'workout_test.dart' show jsonResponse;

const curlSource = '12fd053b-c9d7-4de4-b9f5-61c0f6d8afdf';
const raiseSource = '39839277-9273-4e7d-bfbc-200f2c1b737a';
const homeCurl = '0b68e9b2-7519-42ff-b45a-38ab2e7f8d5c';
Map<String, Map<String, dynamic>> actualCatalog() => {
  for (final ex in jsonDecode(
    File('docs/exercise_catalog_phase2b.json').readAsStringSync(),
  ) as List)
    ex['id'] as String: Map<String, dynamic>.from(ex as Map),
};
List<Map<String, dynamic>> proposedRows() => (jsonDecode(
  File('docs/home_mapping_proposal.json').readAsStringSync(),
) as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
List<HomeMapping> reviewedFixtures() => proposedRows()
    .map(
      (m) => HomeMapping.fromMap({
        ...m,
        'review_status': 'approved',
        'enabled': true,
      }),
    )
    .toList();
WorkoutDay homeDay({
  List<String> ids = const [curlSource, raiseSource],
  int weekday = 1,
  bool missing = false,
  bool absentTargets = false,
}) {
  final catalog = actualCatalog();
  return WorkoutService.parseDays([
    {
      'id': 'day-$weekday',
      'workout_plan_id': 'plan-1',
      'weekday': weekday,
      'title': 'Saved day',
      'workout_day_exercises': [
        for (var i = 0; i < ids.length; i++)
          {
            'id': 'source-$i',
            'exercise_id': ids[i],
            'sort_order': i,
            'sets': null,
            'reps': null,
            'rest_seconds': null,
            'exercise_library': missing
                ? null
                : {
                    ...catalog[ids[i]]!,
                    if (absentTargets) 'target_muscle': null,
                  },
          },
      ],
    },
  ]).single;
}

HomeProposal buildHome(
  WorkoutDay day, {
  List<HomeMapping>? mappings,
  Map<String, Map<String, dynamic>>? catalog,
  Set<String> equipment = const {'bodyweight', 'dumbbells'},
  int? minutes,
}) => HomeWorkoutEngine.build(
  day,
  mappings ?? reviewedFixtures(),
  catalog ?? actualCatalog(),
  equipment,
  minutes,
);
List<Map<String, dynamic>> remoteSets(WorkoutSession s) => [
  for (var i = 0; i < s.completion.length; i++)
    for (var j = 0; j < s.completion[i].length; j++)
      {
        'exercise_position': i,
        'set_number': j + 1,
        'completed': s.completion[i][j],
      },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('training context reads only current account reports and preserves active status', () async {
    final requests = <Uri>[];
    final client = testClient((r) async {
      requests.add(r.url);
      return jsonResponse(
        r.url.path.endsWith('profiles')
            ? {
                'user_id': testUserId,
                'workout_location': 'home',
                'session_duration_minutes': 30,
              }
            : [
                {'body_region': 'shoulder', 'status': 'needs_review'},
              ],
      );
    });
    addTearDown(client.dispose);
    await testSession(client);
    final context = await TrainingContextService(client).load();
    expect(context.location, 'home');
    expect(context.minutes, 30);
    expect(context.injuryWarning, isTrue);
    expect(context.reportStatus, 'needs_review');
    expect(
      requests.every((r) => r.queryParameters['user_id'] == 'eq.$testUserId'),
      isTrue,
    );
    expect(requests.last.queryParameters['status'], contains('needs_review'));
  });
  test('proposal rows reference real catalog records and remain disabled', () {
    final cat = actualCatalog();
    for (final row in proposedRows()) {
      expect(cat.containsKey(row['source_exercise_id']), isTrue);
      expect(cat.containsKey(row['alternative_exercise_id']), isTrue);
      expect(HomeMapping.fromMap(row).approved, isFalse);
    }
    expect(
      buildHome(
        homeDay(),
        mappings: proposedRows().map(HomeMapping.fromMap).toList(),
      ).available,
      isFalse,
    );
  });
  test('deterministic mappings preserve Gym source and explicit IDs', () {
    final day = homeDay();
    final original = day.moves
        .map((m) => sessionMoveToMap(m, m.sortOrder))
        .toList();
    final a = buildHome(day);
    final b = buildHome(day, mappings: reviewedFixtures().reversed.toList());
    expect(
      a.moves.map((m) => sessionMoveToMap(m, m.sortOrder)),
      b.moves.map((m) => sessionMoveToMap(m, m.sortOrder)),
    );
    expect(a.moves.first.exerciseId, homeCurl);
    expect(a.moves.first.id, 'source-0');
    expect(a.moves.first.sets, 2);
    expect(a.moves.first.restSeconds, 60);
    expect(day.moves.map((m) => sessionMoveToMap(m, m.sortOrder)), original);
    expect(day.moves.first.sets, isNull);
    expect(day.moves.first.restSeconds, isNull);
    expect(a.missingTargets, isEmpty);
  });
  test('exact capability matching, conservative defaults and combinations', () {
    expect(equipmentCapabilities(' dumbbell '), {'dumbbells'});
    expect(equipmentCapabilities('body weight'), {'bodyweight'});
    expect(equipmentCapabilities('resistance bands'), {'bands'});
    for (final unsupported in [
      'assisted',
      'weighted',
      'dumbbell and bench',
      'cable',
      'barbell',
    ]) {
      expect(equipmentCapabilities(unsupported), isNull);
    }
    expect(buildHome(homeDay(), equipment: {'bodyweight'}).available, isFalse);
    expect(
      buildHome(homeDay(), equipment: {'bodyweight', 'bands'}).available,
      isFalse,
    );
    expect(
      buildHome(
        homeDay(),
        equipment: {'bodyweight', 'bands', 'dumbbells'},
      ).moves.length,
      2,
    );
    expect(
      () => buildHome(homeDay(), equipment: {'dumbbells'}),
      throwsArgumentError,
    );
  });
  test('missing, unpublished, empty and rest prescriptions cannot adapt', () {
    expect(buildHome(homeDay(missing: true)).available, isFalse);
    expect(buildHome(homeDay(ids: [])).available, isFalse);
    expect(
      buildHome(
        const WorkoutDay(id: '', weekday: 2, title: 'Rest', isRestDay: true),
      ).available,
      isFalse,
    );
    final cat = actualCatalog();
    cat[homeCurl]!['is_published'] = false;
    cat.remove(raiseSource);
    expect(buildHome(homeDay(), catalog: cat).available, isFalse);
    expect(buildHome(homeDay(absentTargets: true)).available, isFalse);
    expect(buildHome(homeDay(), mappings: []).available, isFalse);
  });
  test(
    'partial coverage never fabricates chest and duplicate volume is disclosed',
    () {
      final chest =
          actualCatalog().values.firstWhere(
                (e) => e['target_muscle'] == 'pectorals',
              )['id']
              as String;
      final p = buildHome(homeDay(ids: [curlSource, curlSource, chest]));
      expect(p.moves.length, 1);
      expect(p.coveredTargets, {'biceps'});
      expect(p.missingTargets, {'pectorals'});
      expect(
        p.limitations.join(' '),
        contains('extra gym volume is not reproduced'),
      );
      expect(p.limitations.join(' '), contains('Not covered: Chest'));
    },
  );
  test('version and priority selection are stable; budget preserves distinct targets first', () {
    final rows = proposedRows()
        .where(
          (m) => [curlSource, raiseSource].contains(m['source_exercise_id']),
        )
        .toList();
    final mappings = rows
        .map(
          (m) => HomeMapping.fromMap({
            ...m,
            'review_status': 'approved',
            'enabled': true,
            'sets': 4,
            'work_seconds_per_set': 240,
          }),
        )
        .toList();
    final p = buildHome(homeDay(), mappings: mappings, minutes: 15);
    expect(p.moves.length, 2);
    expect(p.moves.map((m) => m.sets), [1, 1]);
    expect(p.estimatedSeconds, lessThanOrEqualTo(900));
    expect(p.missingTargets, isEmpty);
    expect(p.limitations.join(' '), contains('not equivalent'));
    expect(buildHome(homeDay(), mappings: mappings).moves.map((m) => m.sets), [
      4,
      4,
    ]);
    expect(buildHome(homeDay(), minutes: 1).available, isFalse);
    final newer = HomeMapping.fromMap({
      ...rows.first,
      'id': 'new-version',
      'version': 2,
      'review_status': 'approved',
      'enabled': true,
    });
    final versioned = buildHome(
      homeDay(),
      mappings: [...reviewedFixtures(), newer],
    );
    expect(versioned.moves.first.mappingVersion, 2);
  });
  test('Home snapshot is exact, isolated, immutable and round trips checked progress', () {
    final day = homeDay();
    final session = WorkoutSession.start(
      testUserId,
      day,
      home: buildHome(day, minutes: 15),
    );
    session.toggle(0, 1);
    final copy = WorkoutSession.fromMap(
      jsonDecode(jsonEncode(session.toMap())) as Map<String, dynamic>,
    );
    expect(copy.toMap(), session.toMap());
    expect(copy.trainingLocation, 'home');
    expect(copy.requestedMinutes, 15);
    expect(copy.exercises.first.exerciseId, homeCurl);
    expect(copy.sourcePrescription.first.exerciseId, curlSource);
    expect(copy.completion.first, [false, true]);
    expect(day.moves.first.sets, isNull);
    expect(
      () => copy.exercises.first.instructions.add('mutate'),
      throwsUnsupportedError,
    );
    final map = copy.toMap();
    (map['completion'] as List).first[0] = true;
    expect(copy.completion.first.first, isFalse);
    final gym = WorkoutSession.start(testUserId, day);
    expect(gym.trainingLocation, 'gym');
    expect(gym.exercises.first.exerciseId, curlSource);
    expect(
      () => WorkoutSession.start(
        testUserId,
        homeDay(weekday: 3),
        home: buildHome(day),
      ),
      throwsStateError,
    );
  });
  test('database service scopes approved mappings and published alternatives; missing migration is honest', () async {
    var missing = false;
    final requests = <Uri>[];
    final client = testClient((r) async {
      requests.add(r.url);
      if (missing) {
        return jsonResponse({'code': 'PGRST205', 'message': 'missing'}, 404);
      }
      return jsonResponse(
        r.url.path.endsWith('workout_alternative_mappings')
            ? proposedRows()
                  .map(
                    (m) => {...m, 'enabled': true, 'review_status': 'approved'},
                  )
                  .toList()
            : actualCatalog().values.toList(),
      );
    });
    addTearDown(client.dispose);
    await testSession(client);
    final service = HomeWorkoutService(client);
    expect(
      (await service.propose(homeDay(), {
        'bodyweight',
        'dumbbells',
      }, 30)).available,
      isTrue,
    );
    expect(requests.first.queryParameters['review_status'], 'eq.approved');
    expect(requests.first.queryParameters['enabled'], 'eq.true');
    expect(requests.last.queryParameters['is_published'], 'eq.true');
    missing = true;
    await expectLater(
      service.propose(homeDay(), {'bodyweight'}, null),
      throwsStateError,
    );
  });
  test('reconcile distinguishes divergent flags and keeps explicit conflict backup', () async {
    final remote = WorkoutSession.start(
      testUserId,
      homeDay(),
      home: buildHome(homeDay()),
    );
    remote.toggle(0, 0);
    final local = WorkoutSession.fromMap(remote.toMap());
    local.completion[0] = [false, true];
    local.baseRevision = 0;
    final client = testClient(
      (r) async => jsonResponse(
        r.url.path.endsWith('workout_sessions')
            ? [remote.toMap()..remove('completion')]
            : remoteSets(remote),
      ),
    );
    addTearDown(client.dispose);
    await testSession(client);
    final service = WorkoutSessionService(client);
    await service.saveDraft(local);
    await expectLater(
      service.resume(local.dayId, reconcile: true),
      throwsA(isA<SessionConflictException>()),
    );
    await service.resolveConflict(local, remote);
    expect(local.revision, remote.revision + 1);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs
          .getKeys()
          .where((k) => k.startsWith('arc.session.conflict.'))
          .length,
      1,
    );
    expect((await service.resume(local.dayId))!.completion.first, [
      false,
      true,
    ]);
  });
  test(
    'reconcile preserves unsynced same-session flags and offline draft',
    () async {
      final remote = WorkoutSession.start(
        testUserId,
        homeDay(),
        home: buildHome(homeDay()),
      );
      final local = WorkoutSession.fromMap(remote.toMap());
      local.baseRevision = 0;
      local.toggle(0, 1);
      var offline = false;
      final client = testClient((r) async {
        if (offline) throw const SocketException('offline');
        return jsonResponse(
          r.url.path.endsWith('workout_sessions')
              ? [remote.toMap()..remove('completion')]
              : remoteSets(remote),
        );
      });
      addTearDown(client.dispose);
      await testSession(client);
      final service = WorkoutSessionService(client);
      await service.saveDraft(local);
      expect(
        (await service.resume(local.dayId, reconcile: true))!.completion,
        local.completion,
      );
      offline = true;
      expect(
        (await service.resume(local.dayId, reconcile: true))!.toMap(),
        local.toMap(),
      );
    },
  );
  test(
    'different variant UUIDs conflict without replacing local snapshot',
    () async {
      final day = homeDay();
      final local = WorkoutSession.start(testUserId, day, home: buildHome(day));
      final remote = WorkoutSession.start(testUserId, day);
      final client = testClient(
        (r) async => jsonResponse(
          r.url.path.endsWith('workout_sessions')
              ? [remote.toMap()..remove('completion')]
              : remoteSets(remote),
        ),
      );
      addTearDown(client.dispose);
      await testSession(client);
      final service = WorkoutSessionService(client);
      await service.saveDraft(local);
      await expectLater(
        service.resume(day.id, reconcile: true),
        throwsA(isA<SessionConflictException>()),
      );
      expect((await service.resume(day.id))!.trainingLocation, 'home');
    },
  );
}
