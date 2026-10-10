import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arc/data/exercise_media.dart';
import 'package:arc/data/training_context_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/focus_workout_page.dart';
import 'package:arc/train_page.dart';
import 'package:arc/widgets/exercise_detail_dialog.dart';
import 'package:arc/widgets/exercise_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_widget_test.dart' show widgetClient;
import 'profile_test.dart' show testSession;
import 'train_variant_test.dart' show SavedWorkouts, SavedContext;
import 'workout_test.dart' show sampleDay, jsonResponse;
import 'exercise_media_test.dart' show DemoBundle, decodeFrames;

class Routes extends NavigatorObserver {
  final stack = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.remove(route);
}

Future<(Routes, Routes)> nestedTrain(
  WidgetTester tester, {
  WorkoutDay? day,
}) async {
  final client = await widgetClient(tester, (_) async => jsonResponse(null));
  await testSession(client);
  addTearDown(() => tester.runAsync(client.dispose));
  final root = Routes(), inner = Routes();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      navigatorObservers: [root],
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/signed-in-home'),
          builder: (_) => Scaffold(
            body: TrainPage(
              workoutService: SavedWorkouts(
                client,
                List.filled(7, day ?? sampleDay()),
              ),
              contextService: SavedContext(client, const TrainingContext()),
            ),
          ),
        ),
        observers: [inner],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byIcon(Icons.play_arrow_rounded).first,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(find.byIcon(Icons.play_arrow_rounded).first),
    alignment: .5,
  );
  await tester.pumpAndSettle();
  return (root, inner);
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('Train exercise Close preserves signed-in nested navigator', (
    tester,
  ) async {
    final (root, inner) = await nestedTrain(tester);
    expect(root.stack.length, 1);
    expect(inner.stack.length, 1);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();
    expect(root.stack.length, 2);
    expect(inner.stack.length, 1);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    // Route counts are safe diagnostics: no account or exercise payload data.
    debugPrint(
      'After Close: root=${root.stack.length}, signed-in=${inner.stack.length}',
    );
    expect(tester.takeException(), isNull);
    expect(root.stack.length, 1);
    expect(inner.stack.length, 1);
    expect(find.byType(TrainPage), findsOneWidget);
  });
  testWidgets(
    'Train system Back and repeated name taps preserve route stacks',
    (tester) async {
      final (root, inner) = await nestedTrain(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Move 0').first);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(root.stack.length, 1);
        expect(inner.stack.length, 1);
        expect(find.byType(TrainPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'Persisted generated prescription uses library UUID, not prescription UUID',
    (tester) async {
      final fixture = jsonDecode(
        File('docs/phase2c_checkpoint3_pg17_local_e2e.json').readAsStringSync(),
      );
      final day = WorkoutService.parseDays(
        List<dynamic>.from(fixture['relations']),
      ).first;
      await nestedTrain(tester, day: day);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pumpAndSettle();
      final media = tester.widget<ExerciseMedia>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(ExerciseMedia),
        ),
      );
      expect(media.exerciseId, day.moves.first.exerciseId);
      expect(media.exerciseId, isNot(day.moves.first.id));
      final requests = <Uri>[];
      final client = await widgetClient(tester, (request) async {
        requests.add(request.url);
        return jsonResponse({'gif_path': null});
      });
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.runAsync(
        () => ExerciseMediaPath.latest(media.exerciseId!, client: client),
      );
      expect(
        requests.single.queryParameters['id'],
        'eq.${day.moves.first.exerciseId}',
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Browse Anatomy nested detail closes without removing Browse route',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => jsonResponse([
          {
            'id': '50000000-0000-0000-0000-000000000001',
            'name': 'Browse fixture',
            'target_muscle': 'chest',
            'gif_path': null,
            'instructions': ['Browse instruction'],
          },
        ]),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final root = Routes(), inner = Routes();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          navigatorObservers: [root],
          home: Navigator(
            observers: [inner],
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) =>
                  FocusWorkoutPage(muscles: const ['chest'], client: client),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Browse fixture'));
      await tester.pumpAndSettle();
      expect(find.text('Browse instruction'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(root.stack.length, 1);
      expect(inner.stack.length, 1);
      expect(find.byType(FocusWorkoutPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final path in [
    null,
    '../invalid.gif',
    'assets/missing.gif',
    'assets/valid.gif',
  ]) {
    testWidgets('Bounded detail media $path and optional metadata are safe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (_, child) =>
              DefaultAssetBundle(bundle: DemoBundle(), child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showExerciseDetails(
                  context,
                  name: null,
                  target: '',
                  equipment: 4,
                  instructions: [null, 2, '', 'Safe instruction'],
                  mediaPath: path,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await decodeFrames(tester);
      expect(find.text('Target muscle: Not specified'), findsOneWidget);
      expect(find.text('Safe instruction'), findsOneWidget);
      if (path != 'assets/valid.gif') {
        expect(find.text('COMING SOON'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final timeout in [false, true]) {
    testWidgets(
      'Detail lookup ${timeout ? 'timeout' : 'failure'} has fallback, retry and Back',
      (tester) async {
        var calls = 0;
        final ids = <String>[];
        const libraryId = '50000000-0000-0000-0000-000000000001';
        Future<Object?> lookup(String id) {
          calls++;
          ids.add(id);
          return timeout
              ? Completer<Object?>().future
              : Future.error(StateError('private error'));
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showExerciseDetails(
                    context,
                    name: 'Available exercise',
                    exerciseId: libraryId,
                    lookup: lookup,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (timeout) await tester.pump(const Duration(seconds: 16));
        expect(find.text('COMING SOON'), findsOneWidget);
        expect(find.text('private error'), findsNothing);
        await tester.tap(find.text('Demo unavailable? Retry'));
        await tester.pumpAndSettle();
        if (timeout) await tester.pump(const Duration(seconds: 16));
        expect(calls, 2);
        expect(ids, [libraryId, libraryId]);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Missing or invalid library ID never queries a prescription ID', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                for (final id in [null, '', 4, 'source-prescription'])
                  TextButton(
                    onPressed: () => showExerciseDetails(
                      context,
                      name: 'Exercise',
                      exerciseId: id,
                      lookup: (_) async {
                        calls++;
                        return null;
                      },
                    ),
                    child: Text('Open $id'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final id in [null, '', 4, 'source-prescription']) {
      await tester.tap(find.text('Open $id'));
      await tester.pumpAndSettle();
      expect(find.text('COMING SOON'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Long instructions at 200 percent text keep Close reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showExerciseDetails(
                context,
                name: 'Long exercise',
                instructions: List.filled(
                  60,
                  'Controlled movement with a complete instruction.',
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
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
