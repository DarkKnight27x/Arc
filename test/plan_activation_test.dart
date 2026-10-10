import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arc/data/plan_activation_service.dart';
import 'package:arc/data/training_plan_generator.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/start_arc_page.dart';
import 'package:arc/theme_ctrl.dart';
import 'package:arc/train_page.dart';
import 'package:arc/session_player.dart';
import 'package:arc/widgets/start_arc_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'profile_test.dart' show testClient, testSession, testUserId;
import 'profile_widget_test.dart' show widgetClient;
import 'start_arc_test.dart' show BuilderFixture;
import 'train_variant_test.dart' show SavedContext;

import 'package:arc/data/training_context_service.dart';

import 'workout_session_widget_test.dart' show MemorySessionService;
import 'workout_test.dart' show jsonResponse;

const activatedId = '10000000-0000-0000-0000-000000000001';

TrainingPlanPreview realPreview() {
  final rows = jsonDecode(
    File('docs/curated_catalog_v1_public_api_catalog.json').readAsStringSync(),
  ) as List;
  final catalog = TrainingCatalog(
    rows.map(
      (r) =>
          TrainingCatalogExercise.fromMap(Map<String, dynamic>.from(r as Map)),
    ),
  );
  final result = TrainingPlanGenerator().generate(
    TrainingPlanConfig(
      goal: TrainingGoal.buildMuscle,
      experience: TrainingExperience.beginner,
      weekdays: [1, 4],
      equipment: catalog.exercises
          .expand((e) => e.metadata.requiredEquipment)
          .toSet(),
      sessionMinutes: 60,
      journeyDays: 30,
      age: 25,
    ),
    catalog,
  );
  expect(result.available, true);
  return result.preview!;
}

class ActivationFixture implements PlanActivationSource {
  int calls = 0;
  final keys = <String>[];
  final pending = <Completer<ActivatedTrainingPlan>>[];
  @override
  Future<ActivatedTrainingPlan> activate(
    TrainingPlanPreview preview,
    String key, {
    ActivatedTrainingPlan? replace,
  }) {
    calls++;
    keys.add(key);
    final c = Completer<ActivatedTrainingPlan>();
    pending.add(c);
    return c.future;
  }
}

Future<void> makePreview(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select Priority Muscles'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Dumbbells'), 300);
  await tester.tap(find.text('Dumbbells'));
  await tester.scrollUntilVisible(find.text('Generate Plan'), 300);
  await tester.tap(find.text('Generate Plan'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('confirm-my-arc')),
    300,
  );
}

class RefreshWorkouts extends WorkoutService {
  RefreshWorkouts(super.client);
  int calls = 0;
  List<WorkoutDay> days = [];
  @override
  Future<List<WorkoutDay>> fetchWorkoutPlan() async {
    calls++;
    return days;
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    themeCtrl.value = ThemeMode.dark;
  });

  test('real generator payload matches locally activated rows and every Gym source', () {
    final local = jsonDecode(
      File('docs/phase2c_checkpoint3_local_e2e.json').readAsStringSync(),
    ) as Map;
    final p = Map<String, dynamic>.from(local['activation_payload'] as Map);
    expect(
      trainingActivationPayload(
        realPreview(),
        p['user_id'] as String,
        p['idempotency_key'] as String,
      ),
      p,
    );
    final days = WorkoutService.parseDays(local['relations'] as List);
    final week = workoutWeek(
      (local['result'] as Map)['plan_id'] as String,
      days,
    );
    expect(week.length, 7);
    expect(week.where((d) => d.isRestDay).length, 5);
    for (final day in days) {
      expect(day.canStart, true);
      final session = WorkoutSession.start(p['user_id'] as String, day);
      expect(session.sessionVariant, 'gym_original');
      expect(
        session.toMap()['source_prescription'],
        session.toMap()['prescription'],
      );
      final saved = (local['relations'] as List).singleWhere(
        (r) => (r as Map)['id'] == day.id,
      ) as Map;
      final rows = saved['workout_day_exercises'] as List;
      for (final (i, move) in session.sourcePrescription.indexed) {
        expect(move.id, (rows[i] as Map)['id']);
        expect(move.exerciseId, (rows[i] as Map)['exercise_id']);
        expect(move.sets, (rows[i] as Map)['sets']);
        expect(move.reps, (rows[i] as Map)['reps']);
        expect(move.restSeconds, (rows[i] as Map)['rest_seconds']);
      }
      if (day.id == (local['gym_session_payload'] as Map)['workout_day_id']) {
        expect(
          session.toMap()['source_prescription'],
          (local['gym_session_payload'] as Map)['source_prescription'],
        );
      }
    }
    expect(days.first.moves.any((m) => m.gifPath == null), true);
    expect(p['config'], isNot(contains('age')));
    expect(p, isNot(contains('can_activate')));
  });

  test(
    'RPC success posts owner-scoped projection and invalidates Train',
    () async {
      Map? posted;
      final client = testClient((r) async {
        posted = jsonDecode(r.body) as Map;
        expect(r.url.path, '/rest/v1/rpc/activate_generated_training_plan');
        return jsonResponse({
          'plan_id': activatedId,
          'version': 1,
          'status': 'active',
          'replayed': false,
        });
      });
      addTearDown(client.dispose);
      await testSession(client);
      final plan = await PlanActivationService(client)
          .activate(realPreview(), activatedId);
      expect(plan.id, activatedId);
      expect((posted!['payload'] as Map)['user_id'], testUserId);
      expect(WorkoutService.changes.value?.owner, testUserId);
    },
  );

  for (final (code, failure) in [
    ('PT409', PlanActivationFailure.conflict),
    ('22023', PlanActivationFailure.validation),
    ('PGRST202', PlanActivationFailure.unavailable),
    ('42501', PlanActivationFailure.account),
  ]) {
    test('RPC $code has sanitized $failure response', () async {
      final client = testClient(
        (r) async => http.Response(
          jsonEncode({
            'code': code,
            'message': code == '42501'
                ? 'ARC_AUTH_REQUIRED'
                : 'sensitive fixture SQL detail',
          }),
          code == 'PT409' ? 409 : 400,
        ),
      );
      addTearDown(client.dispose);
      await testSession(client);
      await expectLater(
        PlanActivationService(client).activate(realPreview(), activatedId),
        throwsA(
          isA<PlanActivationException>()
              .having((e) => e.failure, 'failure', failure)
              .having(
                (e) => e.message.contains('sensitive'),
                'sanitized',
                false,
              ),
        ),
      );
    });
  }

  test(
    'account switch while RPC pending discards result without invalidation',
    () async {
      final pending = Completer<http.Response>();
      final client = testClient((r) => pending.future);
      addTearDown(client.dispose);
      await testSession(client);
      final before = WorkoutService.changes.value;
      final result = PlanActivationService(client)
          .activate(realPreview(), activatedId);
      final expected = expectLater(
        result,
        throwsA(
          isA<PlanActivationException>().having(
            (e) => e.failure,
            'failure',
            PlanActivationFailure.account,
          ),
        ),
      );
      await testSession(client, id: '00000000-0000-0000-0000-000000000002');
      pending.complete(
        jsonResponse({
          'plan_id': activatedId,
          'version': 1,
          'status': 'active',
        }),
      );
      await expected;
      expect(WorkoutService.changes.value, before);
    },
  );

  testWidgets(
    'confirmation loading, duplicate taps, blocked navigation and same-key network retry retain preview',
    (tester) async {
      final activation = ActivationFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: arcDarkTheme(),
          home: StartArcPage(
            source: BuilderFixture(),
            activation: activation,
            priorityPicker: (_, _) async => [],
          ),
        ),
      );
      await makePreview(tester);
      expect(activation.calls, 0);
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      expect(activation.calls, 1);
      await tester.pump();
      expect(find.text('Activating your ARC…'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, false);
      activation.pending.single.completeError(
        const PlanActivationException(PlanActivationFailure.network),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Check your connection'), findsOneWidget);
      expect(find.text('Confirm My ARC'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Your first 4-week block'),
        -250,
      );
      expect(find.text('Your first 4-week block'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, true);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-my-arc')),
        250,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      expect(activation.keys.toSet().length, 1);
      expect(activation.calls, 2);
      activation.pending.last.completeError(
        const PlanActivationException(PlanActivationFailure.conflict),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your existing plan was preserved'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Your first 4-week block'),
        -250,
      );
      expect(find.text('Your first 4-week block'), findsOneWidget);
      expect(find.text('Activating your ARC…'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Edit configuration').hitTestable(),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit configuration'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Generate Plan'), 300);
      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      expect(activation.keys.last, isNot(activation.keys.first));
      activation.pending.last.completeError(
        const PlanActivationException(PlanActivationFailure.validation),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('generate a fresh preview'), findsOneWidget);
    },
  );

  test(
    'network exception maps to retryable response and no invalidation',
    () async {
      final client = testClient(
        (_) async => throw http.ClientException('private URL fixture'),
      );
      addTearDown(client.dispose);
      await testSession(client);
      final before = WorkoutService.changes.value;
      await expectLater(
        PlanActivationService(client).activate(realPreview(), activatedId),
        throwsA(
          isA<PlanActivationException>().having(
            (e) => e.failure,
            'failure',
            PlanActivationFailure.network,
          ),
        ),
      );
      expect(WorkoutService.changes.value, before);
    },
  );

  testWidgets(
    'timeout clears confirmation loading on narrow Android viewport; unavailable preserves preview',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final activation = ActivationFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: arcDarkTheme(),
          home: StartArcPage(
            source: BuilderFixture(),
            activation: activation,
            priorityPicker: (_, _) async => [],
          ),
        ),
      );
      await makePreview(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 36));
      await tester.pumpAndSettle();
      expect(find.text('Activating your ARC…'), findsNothing);
      expect(find.textContaining('Check your connection'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-my-arc')).hitTestable(),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      expect(activation.keys.toSet().length, 1);
      activation.pending.last.completeError(
        const PlanActivationException(PlanActivationFailure.unavailable),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Your preview is still here'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // A late completion from the timed-out attempt cannot pop this newer UI state.
      activation.pending.first.complete(
        const ActivatedTrainingPlan(activatedId, 1),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StartArcPage), findsOneWidget);
    },
  );

  testWidgets(
    'each real persisted day opens unchanged SessionPlayer with exact source UUIDs',
    (tester) async {
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final local = jsonDecode(
        File('docs/phase2c_checkpoint3_local_e2e.json').readAsStringSync(),
      ) as Map;
      final owner = (local['activation_payload'] as Map)['user_id'] as String;
      await testSession(client, id: owner);
      final days = WorkoutService.parseDays(local['relations'] as List);
      for (final day in days) {
        final session = WorkoutSession.start(owner, day);
        final service = MemorySessionService(client);
        await tester.pumpWidget(
          MaterialApp(
            theme: arcDarkTheme(),
            home: SessionPlayer(
              key: ValueKey(day.id),
              session: session,
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SessionPlayer), findsOneWidget);
        expect(find.text('SET 1'), findsOneWidget);
        expect(service.saves, isNotEmpty);
        expect(
          service.saves.first['source_prescription'],
          session.toMap()['source_prescription'],
        );
        expect(service.saves.first['session_variant'], 'gym_original');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Home entry receives successful route result, shows success and opens Train',
    (tester) async {
      final client = await widgetClient(tester, (r) async => jsonResponse([]));
      addTearDown(() => tester.runAsync(client.dispose));
      await testSession(client);
      final activation = ActivationFixture();
      var openedTrain = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: arcDarkTheme(),
          home: Scaffold(
            body: StartArcEntry(
              client: client,
              onActivated: () => openedTrain = true,
              planBuilder: (_) => StartArcPage(
                source: BuilderFixture(),
                activation: activation,
                priorityPicker: (_, _) async => [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start My ARC'));
      await makePreview(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-my-arc')));
      await tester.pump();
      activation.pending.single.complete(
        const ActivatedTrainingPlan(activatedId, 1),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StartArcPage), findsNothing);
      expect(openedTrain, true);
      expect(
        find.text('ARC activated. Your weekly plan is ready in Train.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mounted Train refetches activation for its owner, ignores other accounts',
    (tester) async {
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      await testSession(client);
      final workouts = RefreshWorkouts(client);
      await tester.pumpWidget(
        MaterialApp(
          theme: arcDarkTheme(),
          home: TrainPage(
            workoutService: workouts,
            contextService: SavedContext(client, const TrainingContext()),
            sessionService: MemorySessionService(client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initial = workouts.calls;
      expect(find.text('No active training plan yet.'), findsOneWidget);
      WorkoutService.invalidate('00000000-0000-0000-0000-000000000002');
      await tester.pumpAndSettle();
      expect(workouts.calls, initial);
      final local = jsonDecode(
        File('docs/phase2c_checkpoint3_local_e2e.json').readAsStringSync(),
      ) as Map;
      workouts.days = workoutWeek(
        (local['result'] as Map)['plan_id'] as String,
        WorkoutService.parseDays(local['relations'] as List),
      );
      WorkoutService.invalidate(testUserId);
      await tester.pumpAndSettle();
      expect(workouts.calls, initial + 1);
      expect(find.text('No active training plan yet.'), findsNothing);
      expect(find.textContaining('Unable to load your plan'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      WorkoutService.invalidate(testUserId);
      expect(workouts.calls, initial + 1);
    },
  );
}
