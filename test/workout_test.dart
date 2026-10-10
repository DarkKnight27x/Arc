import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/data/workout_session_service.dart';

import 'profile_test.dart' show testClient, testSession, testUserId;

Map<String, dynamic> exercise(
  int order, {
  int? sets = 3,
  int? rest = 60,
  bool available = true,
}) => {
  'id': 'prescription-$order',
  'exercise_id': 'library-$order',
  'sort_order': order,
  'sets': sets,
  'reps': '8–12',
  'rest_seconds': rest,
  'notes': 'Controlled tempo',
  'exercise_library': available
      ? {
          'name': 'Move $order',
          'equipment': 'Cable',
          'instructions': ['Control the return'],
          'target_muscle': order == 1 ? 'Back' : 'Chest',
          'is_published': true,
        }
      : null,
};
Map<String, dynamic> dayRow(List<dynamic> moves, {int weekday = 1}) => {
  'id': 'day-1',
  'workout_plan_id': 'plan-1',
  'weekday': weekday,
  'title': 'Saved workout',
  'notes': 'Saved day notes',
  'estimated_minutes': 35,
  'workout_day_exercises': moves,
};
WorkoutDay sampleDay() => WorkoutService.parseDays([
  dayRow([exercise(0, sets: 2, rest: 30), exercise(1, sets: 4, rest: 90)]),
]).single;
http.Response jsonResponse(Object? data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'selects only own active training plan with version and timestamp order',
    () async {
      final requests = <Uri>[];
      final client = testClient((request) async {
        requests.add(request.url);
        return jsonResponse(
          request.url.path.endsWith('workout_plans')
              ? [
                  {'id': 'selected-plan'},
                ]
              : <dynamic>[],
        );
      });
      addTearDown(client.dispose);
      await testSession(client);
      final days = await WorkoutService(client).fetchWorkoutPlan();
      expect(
        requests[0].queryParameters,
        containsPair('user_id', 'eq.$testUserId'),
      );
      expect(
        requests[0].queryParameters,
        containsPair('plan_type', 'eq.training'),
      );
      expect(requests[0].queryParameters, containsPair('status', 'eq.active'));
      expect(
        requests[0].queryParameters['order'],
        'version.desc.nullslast,updated_at.desc.nullslast,id.asc.nullslast',
      );
      expect(requests[0].queryParameters['limit'], '1');
      expect(
        requests[1].queryParameters['workout_plan_id'],
        'eq.selected-plan',
      );
      expect(days, hasLength(7));
      expect(days.every((d) => d.isRestDay), true);
    },
  );
  test(
    'no plan does not browse or fabricate exercises; failures propagate',
    () async {
      var calls = 0;
      final client = testClient((request) async {
        calls++;
        return jsonResponse([]);
      });
      addTearDown(client.dispose);
      await testSession(client);
      expect(await WorkoutService(client).fetchWorkoutPlan(), isEmpty);
      expect(calls, 1);
      final broken = testClient(
        (request) async =>
            jsonResponse({'code': '42501', 'message': 'denied'}, 403),
      );
      addTearDown(broken.dispose);
      await testSession(broken);
      await expectLater(
        WorkoutService(broken).fetchWorkoutPlan(),
        throwsA(isA<Exception>()),
      );
    },
  );
  test('Monday to Sunday mapping preserves absent weekdays as rest', () {
    final saved = WorkoutService.parseDays([
      dayRow([exercise(0)], weekday: 7),
    ]);
    final week = workoutWeek('plan-1', saved);
    expect(week.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(week.first.isRestDay, true);
    expect(week.last.isRestDay, false);
    expect(week.last.moves.single.id, 'prescription-0');
    expect(
      () => workoutWeek('plan-1', [saved.single, saved.single]),
      throwsFormatException,
    );
  });
  test('sort order survives interleaved muscles, prescriptions and notes', () {
    final day = WorkoutService.parseDays([
      dayRow([exercise(2), exercise(0, sets: 2, rest: 15), exercise(1)]),
    ]).single;
    expect(day.moves.map((m) => m.sortOrder), [0, 1, 2]);
    expect(day.moves.first.trackingSets, 2);
    expect(day.moves.first.timerSeconds, 15);
    expect(day.moves.first.reps, '8–12');
    expect(day.moves.first.notes, 'Controlled tempo');
    expect(day.estimatedMinutes, 35);
    expect(day.muscles, 'Saved day notes');
  });
  test('optional values stay unspecified; zero rest never starts timer', () {
    final move = WorkoutMove.fromMap(exercise(0, sets: null, rest: null));
    expect(move.sets, isNull);
    expect(move.trackingSets, 1);
    expect(move.restSeconds, isNull);
    expect(move.timerSeconds, 0);
    expect(move.scheme, contains('unspecified'));
    expect(move.restLabel, contains('unspecified'));
    expect(WorkoutMove.fromMap(exercise(1, rest: 0)).timerSeconds, 0);
    expect(
      () => WorkoutMove.fromMap(exercise(1, sets: 0)),
      throwsFormatException,
    );
  });
  test('unavailable exercises block session without becoming rest days', () {
    final day = WorkoutService.parseDays([
      dayRow([exercise(0, available: false)]),
    ]).single;
    expect(day.isRestDay, false);
    expect(day.canStart, false);
    expect(day.moves.single.available, false);
    expect(() => WorkoutSession.start(testUserId, day), throwsStateError);
    expect(
      () => WorkoutMove.fromMap({...exercise(0), 'exercise_library': []}),
      throwsFormatException,
    );
  });
  test('unchecked sets remain incomplete when ending partial session', () {
    final session = WorkoutSession.start(testUserId, sampleDay());
    expect(session.completion.map((r) => r.length), [2, 4]);
    session.toggle(0, 0);
    session.currentIndex = 1;
    session.currentIndex = 0;
    expect(session.completion[0], [true, false]);
    session.finish();
    expect(session.status, WorkoutSessionStatus.abandoned);
    expect(session.outcome, 'partial');
    expect(session.doneSets, 1);
    expect(session.completedAt, isNotNull);
    expect(() => session.toggle(0, 1), throwsStateError);
  });
  test('complete and discarded states never fabricate progress', () {
    final session = WorkoutSession.start(testUserId, sampleDay());
    for (var i = 0; i < session.completion.length; i++) {
      for (var j = 0; j < session.completion[i].length; j++) {
        session.toggle(i, j);
      }
    }
    session.finish();
    expect(session.status, WorkoutSessionStatus.completed);
    expect(session.outcome, 'completed');
    final discarded = WorkoutSession.start(testUserId, sampleDay());
    discarded.finish(discard: true);
    expect(discarded.outcome, 'discarded');
    expect(discarded.doneSets, 0);
  });
  test(
    'session JSON roundtrip retains UUID, variable sets, rest and index',
    () {
      final session = WorkoutSession.start(testUserId, sampleDay());
      session.toggle(1, 2);
      session.currentIndex = 1;
      final restored = WorkoutSession.fromMap(
        jsonDecode(jsonEncode(session.toMap())) as Map<String, dynamic>,
      );
      expect(restored.toMap(), session.toMap());
      expect(restored.exercises[1].timerSeconds, 90);
      expect(restored.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(
        () => WorkoutSession.fromMap({...session.toMap(), 'completion': []}),
        throwsFormatException,
      );
    },
  );
  test(
    'failed save retains a local draft and retry uses the same session UUID',
    () async {
      var fail = true;
      final sent = <Map<String, dynamic>>[];
      final client = testClient((request) async {
        final payload =
            (jsonDecode(request.body) as Map)['payload']
                as Map<String, dynamic>;
        sent.add(payload);
        return fail
            ? jsonResponse({
                'code': 'PGRST202',
                'message': 'missing function',
              }, 404)
            : jsonResponse(payload['id']);
      });
      addTearDown(client.dispose);
      await testSession(client);
      final service = WorkoutSessionService(client);
      final session = WorkoutSession.start(testUserId, sampleDay());
      session.toggle(0, 0);
      final before = WorkoutSessionService.changes.value;
      await expectLater(
        service.save(session),
        throwsA(isA<SessionPersistenceException>()),
      );
      expect(WorkoutSessionService.changes.value, before);
      expect((await service.resume(session.dayId))!.completion[0], [
        true,
        false,
      ]);
      fail = false;
      await service.save(session);
      expect(WorkoutSessionService.changes.value?.owner, testUserId);
      expect(WorkoutSessionService.changes.value?.revision, (before?.revision ?? 0) + 1);
      expect(sent.map((p) => p['id']).toSet(), {session.id});
      session.finish();
      await service.save(session);
      expect(WorkoutSessionService.changes.value?.revision, (before?.revision ?? 0) + 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(service.key(testUserId, session.dayId)), isNull);
    },
  );
  test('mismatched ownership prevents local and remote writes', () async {
    var writes = 0;
    final client = testClient((request) async {
      writes++;
      return jsonResponse(null);
    });
    addTearDown(client.dispose);
    await testSession(client);
    final service = WorkoutSessionService(client);
    final session = WorkoutSession.start('another-user', sampleDay());
    await expectLater(
      service.save(session),
      throwsA(isA<SessionPersistenceException>()),
    );
    expect(writes, 0);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
  test(
    'missing tables permit local development; other resume errors propagate',
    () async {
      var missing = true;
      final client = testClient(
        (request) async => jsonResponse({
          'code': missing ? 'PGRST205' : '42501',
          'message': 'unavailable',
        }, missing ? 404 : 403),
      );
      addTearDown(client.dispose);
      await testSession(client);
      final service = WorkoutSessionService(client);
      expect(await service.resume('day-1'), isNull);
      missing = false;
      await expectLater(service.resume('day-1'), throwsA(isA<Exception>()));
    },
  );

  test(
    'cloud resume reconstructs exact flags and refuses missing set rows',
    () async {
      final original = WorkoutSession.start(testUserId, sampleDay());
      original.toggle(1, 2);
      original.currentIndex = 1;
      var completeRows = true;
      final client = testClient((request) async {
        if (request.url.path.endsWith('workout_sessions')) {
          return jsonResponse([original.toMap()..remove('completion')]);
        }
        return jsonResponse([
          for (var i = 0; i < original.completion.length; i++)
            for (var j = 0; j < original.completion[i].length; j++)
              if (completeRows || !(i == 1 && j == 2))
                {
                  'exercise_position': i,
                  'set_number': j + 1,
                  'completed': original.completion[i][j],
                },
        ]);
      });
      addTearDown(client.dispose);
      await testSession(client);
      final service = WorkoutSessionService(client);
      final resumed = await service.resume(original.dayId);
      expect(resumed!.toMap(), original.toMap());
      completeRows = false;
      await expectLater(
        service.resume(original.dayId),
        throwsA(isA<SessionPersistenceException>()),
      );
    },
  );
  test(
    'a missing child table never starts a duplicate of an existing session',
    () async {
      final original = WorkoutSession.start(testUserId, sampleDay());
      final client = testClient(
        (request) async => request.url.path.endsWith('workout_sessions')
            ? jsonResponse([original.toMap()..remove('completion')])
            : jsonResponse({
                'code': 'PGRST205',
                'message': 'Missing set table',
              }, 404),
      );
      addTearDown(client.dispose);
      await testSession(client);
      await expectLater(
        WorkoutSessionService(client).resume(original.dayId),
        throwsA(isA<Exception>()),
      );
    },
  );
  test('invalid completed snapshots cannot claim unchecked progress', () {
    final original = WorkoutSession.start(testUserId, sampleDay());
    expect(
      () => WorkoutSession.fromMap({
        ...original.toMap(),
        'status': 'completed',
        'outcome': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }),
      throwsFormatException,
    );
  });
}
