import 'dart:async';

import 'package:arc/data/home_workout.dart';
import 'package:arc/data/home_workout_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/session_player.dart';
import 'package:arc/widgets/training_variant_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_workout_test.dart' show homeDay, buildHome;
import 'profile_test.dart' show testSession, testUserId;
import 'profile_widget_test.dart' show widgetClient;
import 'workout_session_widget_test.dart' show MemorySessionService;
import 'workout_test.dart' show jsonResponse;

class ControlledHomeService extends HomeWorkoutService {
  ControlledHomeService(super.client);
  final pending = <Completer<HomeProposal>>[];
  final choices = <({Set<String> equipment, int? minutes})>[];
  @override
  Future<HomeProposal> propose(
    WorkoutDay day,
    Set<String> equipment,
    int? minutes,
  ) {
    choices.add((equipment: equipment, minutes: minutes));
    final request = Completer<HomeProposal>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  testWidgets(
    'equipment changes invalidate old async proposals; Home/Gym remains reversible',
    (tester) async {
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final service = ControlledHomeService(client);
      var location = 'gym';
      HomeProposal? started;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => TrainingVariantPanel(
                  day: homeDay(),
                  service: service,
                  location: location,
                  onLocation: (value) => setState(() => location = value),
                  onStart: (p) => started = p,
                  moveBuilder: (m) => Text(m.name),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home alternative'));
      await tester.pump();
      expect(service.choices.first.equipment, {'bodyweight'});
      expect(service.choices.first.minutes, isNull);
      await tester.tap(find.text('Dumbbells'));
      await tester.pump();
      expect(service.pending.length, 2);
      service.pending.first.complete(buildHome(homeDay()));
      await tester.pump();
      expect(find.text('Review & start Home'), findsNothing);
      service.pending.last.complete(buildHome(homeDay()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review & start Home'));
      await tester.tap(find.text('Review & start Home'));
      expect(started, isNotNull);
      await tester.ensureVisible(find.text('Gym - saved plan'));
      await tester.tap(find.text('Gym - saved plan'));
      await tester.pump();
      expect(location, 'gym');
      expect(find.text('Review & start Home'), findsNothing);
    },
  );
  testWidgets(
    'unavailable mappings and failure display reasons without a start control',
    (tester) async {
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final service = ControlledHomeService(client);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainingVariantPanel(
                day: homeDay(),
                service: service,
                location: 'home',
                onLocation: (_) {},
                onStart: (_) {},
                moveBuilder: (m) => Text(m.name),
              ),
            ),
          ),
        ),
      );
      service.pending.last.complete(
        buildHome(homeDay(), equipment: {'bodyweight'}),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No valid home workout'), findsOneWidget);
      expect(find.text('Review & start Home'), findsNothing);
      await tester.tap(find.text('Resistance bands'));
      await tester.pump();
      service.pending.last.completeError(
        StateError('Mapping migration needs deployment'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mapping migration needs deployment'), findsOneWidget);
      expect(find.text('Retry alternatives'), findsOneWidget);
    },
  );
  testWidgets(
    '320px Home equipment and time choices wrap at large text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final service = ControlledHomeService(client);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainingVariantPanel(
                day: homeDay(),
                service: service,
                location: 'home',
                onLocation: (_) {},
                onStart: (_) {},
                moveBuilder: (m) => Text(m.name),
              ),
            ),
          ),
        ),
      );
      service.pending.last.complete(
        buildHome(homeDay(), equipment: {'bodyweight'}),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('15 minutes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('15 minutes'));
      await tester.pump();
      expect(service.choices.last.minutes, 15);
      service.pending.last.complete(
        buildHome(homeDay(), equipment: {'bodyweight'}, minutes: 15),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Home player shows actual variant, persists draft on Back during pending save',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = await widgetClient(
        tester,
        (r) async => jsonResponse(null),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      await testSession(client);
      final session = WorkoutSession.start(
        testUserId,
        homeDay(),
        home: buildHome(homeDay(), minutes: 15),
      );
      session.injuryWarning = true;
      final service = MemorySessionService(client)
        ..remoteGate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
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
      expect(find.textContaining('SAVED DAY - HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.textContaining('Reported discomfort'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep draft'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionPlayer), findsNothing);
      expect(service.drafts.last['training_location'], 'home');
      expect(session.outcome, isNull);
      service.remoteGate!.complete();
      await tester.pumpAndSettle();
    },
  );
}
