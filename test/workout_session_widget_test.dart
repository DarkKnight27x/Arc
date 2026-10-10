import 'dart:async';

import 'package:arc/data/workout_session.dart';
import 'package:arc/data/workout_session_service.dart';
import 'package:arc/session_player.dart';
import 'package:arc/theme_ctrl.dart';
import 'package:arc/widgets/health_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test.dart' show testSession, testUserId;
import 'profile_widget_test.dart' show widgetClient;
import 'workout_test.dart' show sampleDay, jsonResponse;

class MemorySessionService extends WorkoutSessionService {
  MemorySessionService(super.client);
  bool fail = false;
  Completer<void>? remoteGate;
  final List<Map<String, dynamic>> saves = [];
  final List<Map<String, dynamic>> drafts = [];
  @override
  Future<void> save(WorkoutSession session, {bool writeDraft = true}) async {
    if (remoteGate != null) await remoteGate!.future;
    saves.add(WorkoutSession.fromMap(session.toMap()).toMap());
    if (fail) {
      throw const SessionPersistenceException(
        'Cloud save failed. Retry saving.',
      );
    }
  }

  @override
  Future<void> saveDraft(WorkoutSession session) async {
    drafts.add(session.toMap());
  }
}

Future<({WorkoutSession session, MemorySessionService service})> openPlayer(
  WidgetTester tester,
) async {
  final client = await widgetClient(
    tester,
    (request) async => jsonResponse(null),
  );
  addTearDown(
    () => tester.runAsync(() async {
      await client.dispose();
    }),
  );
  await testSession(client);
  final service = MemorySessionService(client);
  final session = WorkoutSession.start(testUserId, sampleDay());
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SessionPlayer(session: session, service: service),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (session: session, service: service);
}

void main() {
  testWidgets('variable set rows, actual rep target and exercise rest timer', (
    tester,
  ) async {
    final setup = await openPlayer(tester);
    expect(find.text('SET 1'), findsOneWidget);
    expect(find.text('SET 2'), findsOneWidget);
    expect(find.text('SET 3'), findsNothing);
    expect(find.text('8–12'), findsNWidgets(2));
    await tester.ensureVisible(find.text('SET 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SET 1'));
    await tester.pump();
    expect(
      tester.widget<LiquidMetalTimer>(find.byType(LiquidMetalTimer)).duration,
      const Duration(seconds: 30),
    );
    expect(setup.session.completion[0], [true, false]);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Exercise'));
    await tester.pumpAndSettle();
    expect(setup.session.currentIndex, 1);
    await tester.ensureVisible(find.text('SET 4'));
    expect(find.text('SET 4'), findsOneWidget);
    await tester.ensureVisible(find.text('SET 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SET 1'));
    await tester.pump();
    expect(
      tester.widget<LiquidMetalTimer>(find.byType(LiquidMetalTimer)).duration,
      const Duration(seconds: 90),
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(setup.session.completion[0], [true, false]);
    expect(setup.session.completion[1], [true, false, false, false]);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Finish partial preserves unchecked sets and failed save stays open',
    (tester) async {
      final setup = await openPlayer(tester);
      await tester.tap(find.text('Next Exercise'));
      await tester.pumpAndSettle();
      setup.service.fail = true;
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('Finish partially completed?'), findsOneWidget);
      await tester.tap(find.text('Finish partial'));
      await tester.pumpAndSettle();
      expect(setup.session.outcome, 'partial');
      expect(setup.session.doneSets, 0);
      expect(find.byType(SessionPlayer), findsOneWidget);
      expect(
        find.textContaining('Cloud save failed. Retry saving.'),
        findsOneWidget,
      );
      setup.service.fail = false;
      await tester.tap(find.text('Save & close'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionPlayer), findsNothing);
      expect(setup.service.saves.map((m) => m['id']).toSet(), {
        setup.session.id,
      });
    },
  );
  testWidgets(
    'Close confirmation allows Continue and Keep draft without completion',
    (tester) async {
      final setup = await openPlayer(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Leave session?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Leave session?'), findsNothing);
      expect(find.byType(SessionPlayer), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep draft'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionPlayer), findsNothing);
      expect(setup.session.status, WorkoutSessionStatus.inProgress);
      expect(setup.session.doneSets, 0);
      expect(setup.service.drafts, isNotEmpty);
    },
  );
  testWidgets('Discard records abandonment and never checks sets', (
    tester,
  ) async {
    final setup = await openPlayer(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(setup.session.outcome, 'discarded');
    expect(setup.session.doneSets, 0);
    expect(setup.service.saves.last['status'], 'abandoned');
    expect(find.byType(SessionPlayer), findsNothing);
  });
  testWidgets('small dark and light screens retain readable session controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => themeCtrl.value = ThemeMode.dark);
    await openPlayer(tester);
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      themeCtrl.value = mode;
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SET 2'));
      await tester.pumpAndSettle();
      expect(find.text('Next Exercise'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('account changes hide the previous user session', (tester) async {
    final setup = await openPlayer(tester);
    await testSession(
      setup.service.client,
      id: '00000000-0000-0000-0000-000000000002',
    );
    await tester.pumpAndSettle();
    expect(find.text('SET 1'), findsNothing);
    expect(
      find.text('Your account changed. Sign in again to resume this session.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'local set changes persist while an earlier cloud save is pending',
    (tester) async {
      final setup = await openPlayer(tester);
      final gate = Completer<void>();
      setup.service.remoteGate = gate;
      await tester.ensureVisible(find.text('SET 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SET 1'));
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SET 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SET 2'));
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect((setup.service.drafts.last['completion'] as List).first, [
        true,
        true,
      ]);
      gate.complete();
      await tester.pumpAndSettle();
    },
  );
}
