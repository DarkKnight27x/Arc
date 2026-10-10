import 'dart:async';

import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/data/workout_session_service.dart';
import 'package:arc/widgets/start_arc_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_test.dart' show testClient, testSession, testUserId;
import 'profile_widget_test.dart' show widgetClient;
import 'workout_test.dart' show jsonResponse, sampleDay;

class HomePlans extends WorkoutService {
  HomePlans(super.client);
  List<WorkoutDay> days = [];
  int reads = 0;
  bool fail = false;
  Completer<List<WorkoutDay>>? pending;
  @override
  Future<List<WorkoutDay>> fetchWorkoutPlan() async {
    reads++;
    if (pending != null) return pending!.future;
    if (fail) throw const FormatException('Private backend details');
    return days;
  }
}

class HomeSessions extends WorkoutSessionService {
  HomeSessions(super.client);
  WorkoutSessionStatus? status;
  int reads = 0;
  bool fail = false;
  @override
  Future<WorkoutSessionStatus?> currentDayStatus(
    String dayId, {
    DateTime? now,
  }) async {
    reads++;
    expectSync(dayId, 'day-1');
    if (fail) throw const FormatException('Private backend details');
    return status;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<(HomePlans, HomeSessions)> fixtures(WidgetTester tester) async {
    final client = await widgetClient(tester, (_) async => jsonResponse([]));
    addTearDown(() => tester.runAsync(client.dispose));
    await tester.runAsync(() => testSession(client));
    return (HomePlans(client), HomeSessions(client));
  }

  Future<void> show(
    WidgetTester tester,
    HomePlans plans,
    HomeSessions sessions, {
    bool active = true,
    DateTime? today,
    WidgetBuilder? builder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartArcEntry(
            workoutService: plans,
            sessionService: sessions,
            isActive: active,
            now: () => today ?? DateTime(2026, 10, 12),
            planBuilder: builder,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'confirmed no plan shows CTA; active authoritative plan hides CTA',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      await show(tester, plans, sessions);
      expect(find.text('Start My ARC'), findsOneWidget);
      expect(plans.reads, 1);
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      WorkoutService.invalidate(testUserId);
      await tester.pumpAndSettle();
      expect(find.text('Start My ARC'), findsNothing);
      expect(find.text('ARC ACTIVE'), findsOneWidget);
      expect(find.text('Saved workout'), findsOneWidget);
      expect(find.text('Not completed today'), findsOneWidget);
      expect(plans.reads, 2);
      expect(sessions.reads, 1);
    },
  );

  testWidgets(
    'rest day includes next scheduled workout without history request',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      await show(tester, plans, sessions, today: DateTime(2026, 10, 13));
      expect(find.text('Rest day'), findsOneWidget);
      expect(find.text('Next: Saved workout · Monday'), findsOneWidget);
      expect(sessions.reads, 0);
    },
  );

  testWidgets('activation event refreshes Home before builder route returns', (
    tester,
  ) async {
    final (plans, sessions) = await fixtures(tester);
    await show(
      tester,
      plans,
      sessions,
      builder: (_) => Scaffold(
        body: TextButton(
          onPressed: () {
            plans.days = workoutWeek('plan-1', [sampleDay()]);
            WorkoutService.invalidate(testUserId);
          },
          child: const Text('Confirm fixture'),
        ),
      ),
    );
    await tester.tap(find.text('Start My ARC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm fixture'));
    await tester.pumpAndSettle();
    expect(find.text('ARC ACTIVE', skipOffstage: false), findsOneWidget);
    expect(find.text('Start My ARC', skipOffstage: false), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ARC ACTIVE'), findsOneWidget);
    expect(
      plans.reads,
      2,
    ); // Route return does not duplicate activation refresh.
  });

  testWidgets('resume refreshes today and completion', (tester) async {
    final (plans, sessions) = await fixtures(tester);
    plans.days = workoutWeek('plan-1', [sampleDay()]);
    await show(tester, plans, sessions);
    sessions.status = WorkoutSessionStatus.completed;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Workout completed today'), findsOneWidget);
    expect(plans.reads, 2);
  });

  testWidgets(
    'returning from Train coalesces hidden session events and refreshes once',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      await show(tester, plans, sessions);
      await show(tester, plans, sessions, active: false);
      sessions.status = WorkoutSessionStatus.completed;
      WorkoutSessionService.invalidate(testUserId);
      WorkoutSessionService.invalidate(testUserId);
      await tester.pump();
      expect(plans.reads, 1);
      await show(tester, plans, sessions);
      await tester.pumpAndSettle();
      expect(find.text('Workout completed today'), findsOneWidget);
      expect(plans.reads, 2);
    },
  );

  testWidgets(
    'saved session event refreshes visible Home; unrelated owner events ignored',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      await show(tester, plans, sessions);
      WorkoutSessionService.invalidate('other-owner');
      WorkoutService.invalidate('other-owner');
      await tester.pump();
      expect(plans.reads, 1);
      sessions.status = WorkoutSessionStatus.inProgress;
      WorkoutSessionService.invalidate(testUserId);
      await tester.pumpAndSettle();
      expect(find.text('Workout in progress'), findsOneWidget);
      expect(sessions.reads, 2);
    },
  );

  testWidgets('network failure never guesses no plan and retry recovers', (
    tester,
  ) async {
    final (plans, sessions) = await fixtures(tester);
    plans.fail = true;
    await show(tester, plans, sessions);
    expect(find.text('Start My ARC'), findsNothing);
    expect(
      find.text('Your training status is unavailable. Please retry.'),
      findsOneWidget,
    );
    expect(find.textContaining('Private backend'), findsNothing);
    plans.fail = false;
    await tester.tap(find.text('Retry training plan check'));
    await tester.pumpAndSettle();
    expect(find.text('Start My ARC'), findsOneWidget);
  });

  testWidgets(
    'history failure preserves confirmed active plan without claiming untouched',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      sessions.fail = true;
      await show(tester, plans, sessions);
      expect(find.text('ARC ACTIVE'), findsOneWidget);
      expect(find.text('Not completed today'), findsNothing);
      expect(find.text('Start My ARC'), findsNothing);
      expect(find.text('Retry workout status'), findsOneWidget);
      sessions.fail = false;
      sessions.status = WorkoutSessionStatus.completed;
      await tester.tap(find.text('Retry workout status'));
      await tester.pumpAndSettle();
      expect(find.text('Workout completed today'), findsOneWidget);
    },
  );

  testWidgets(
    'account switch clears old owner and ignores delayed prior result',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      final oldRead = Completer<List<WorkoutDay>>();
      plans.pending = oldRead;
      await show(tester, plans, sessions);
      expect(find.text('Start My ARC'), findsNothing);
      plans.pending = null;
      await tester.runAsync(
        () => testSession(
          plans.client,
          id: '00000000-0000-0000-0000-000000000002',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start My ARC'), findsOneWidget);
      oldRead.complete(workoutWeek('old-owner-plan', [sampleDay()]));
      await tester.pumpAndSettle();
      expect(find.text('ARC ACTIVE'), findsNothing);
      expect(sessions.reads, 0);
    },
  );

  testWidgets('logout clears active status and does not show no-plan CTA', (
    tester,
  ) async {
    final (plans, sessions) = await fixtures(tester);
    plans.days = workoutWeek('plan-1', [sampleDay()]);
    await show(tester, plans, sessions);
    await tester.runAsync(() => plans.client.auth.signOut());
    await tester.pumpAndSettle();
    expect(find.text('ARC ACTIVE'), findsNothing);
    expect(find.text('Start My ARC'), findsNothing);
    expect(find.text('Sign in to see your training status.'), findsOneWidget);
  });

  testWidgets(
    'in-flight invalidations queue one fresh read; disposed completion ignored',
    (tester) async {
      final (plans, sessions) = await fixtures(tester);
      final read = Completer<List<WorkoutDay>>();
      plans.pending = read;
      await show(tester, plans, sessions);
      WorkoutService.invalidate(testUserId);
      WorkoutService.invalidate(testUserId);
      await tester.pump();
      expect(plans.reads, 1);
      plans.pending = null;
      plans.days = workoutWeek('plan-1', [sampleDay()]);
      read.complete([]);
      await tester.pumpAndSettle();
      expect(plans.reads, 2);
      expect(find.text('ARC ACTIVE'), findsOneWidget);
      final disposed = Completer<List<WorkoutDay>>();
      plans.pending = disposed;
      WorkoutService.invalidate(testUserId);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      disposed.complete([]);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test('history read uses own day and local-day window; completed wins', () async {
    final client = testClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/workout_sessions'));
      expect(request.url.queryParameters['select'], 'status');
      expect(request.url.queryParameters['user_id'], 'eq.$testUserId');
      expect(request.url.queryParameters['workout_day_id'], 'eq.day-1');
      final start = DateTime(2026, 10, 12).toUtc().toIso8601String();
      final end = DateTime(2026, 10, 13).toUtc().toIso8601String();
      expect(
        request.url.queryParameters['or'],
        '(and(started_at.gte.$start,started_at.lt.$end),and(completed_at.gte.$start,completed_at.lt.$end))',
      );
      return jsonResponse([
        {'status': 'in_progress'},
        {'status': 'completed'},
      ]);
    });
    addTearDown(client.dispose);
    await testSession(client);
    expect(
      await WorkoutSessionService(client)
          .currentDayStatus('day-1', now: DateTime(2026, 10, 12)),
      WorkoutSessionStatus.completed,
    );
  });
}
