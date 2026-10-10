import 'dart:async';
import 'dart:convert';

import 'package:arc/data/exercise_media.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/focus_workout_page.dart';
import 'package:arc/theme_ctrl.dart';
import 'package:arc/widgets/exercise_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_test.dart' show testClient;
import 'profile_widget_test.dart' show widgetClient;
import 'start_arc_test.dart' as builder;
import 'training_plan_generator_test.dart' as engine;
import 'workout_test.dart' show exercise, dayRow, jsonResponse;
import 'workout_session_widget_test.dart' show openPlayer;
import 'train_variant_test.dart' show openTrain;

class DemoBundle extends CachingAssetBundle {
  final pending = Completer<ByteData>();
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{})!;
    }
    if (key.endsWith('stalled.gif')) return pending.future;
    if (!key.endsWith('valid.gif')) throw StateError('Missing fixture');
    final bytes = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    return ByteData.sublistView(bytes);
  }
}

Widget mediaApp(Widget child, {DemoBundle? bundle, double size = 240}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: bundle ?? DemoBundle(),
          child: Center(
            child: SizedBox(width: size, height: size, child: child),
          ),
        ),
      ),
    );

Future<void> decodeFrames(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    themeCtrl.value = ThemeMode.dark;
  });
  test('null, blanks, malformed types and unsafe paths are absent', () {
    for (final value in [
      null,
      '',
      '  \n ',
      4,
      '../demo.gif',
      '%2e%2e/demo.gif',
      '/demo.gif',
      'file:///demo.gif',
      'https:',
      'javascript:alert(1)',
      'https://user:secret@example.com/demo.gif',
      'bad\\demo.gif',
    ]) {
      expect(ExerciseMediaPath.normalize(value), isNull, reason: '$value');
    }
  });
  test('valid storage and absolute paths resolve without double prefixing', () {
    String storage(String path) => 'https://example.com/exercise-gifs/$path';
    expect(
      ExerciseMediaPath.resolve('  squat.gif  ', storageUrl: storage),
      'https://example.com/exercise-gifs/squat.gif',
    );
    expect(
      ExerciseMediaPath.resolve(
        'https://example.com/demo.gif',
        storageUrl: storage,
      ),
      'https://example.com/demo.gif',
    );
    expect(ExerciseMediaPath.resolve('squat.gif'), isNull);
    expect(
      ExerciseMediaPath.resolve(
        'squat.gif',
        storageUrl: (_) => throw StateError('offline'),
      ),
      isNull,
    );
  });
  test(
    'optional media does not change programming eligibility or validation',
    () {
      for (final path in [
        null,
        '',
        '  ',
        'missing.gif',
        'file:///invalid.gif',
      ]) {
        final rows = engine
            .completeFixture()
            .map(
              (e) => TrainingCatalogExercise.fromMap({
                ...e.sourceSnapshot,
                'id': e.id,
                'is_published': true,
                'movement_patterns': e.metadata.patterns.toList(),
                'required_equipment': e.metadata.requiredEquipment.toList(),
                'allowed_locations': ['gym'],
                'difficulty': 'beginner',
                'gif_path': path,
              }),
            )
            .toList();
        expect(rows.every((e) => e.usable), true);
        expect(
          engine.generate(engine.config(), exercises: rows).available,
          true,
        );
        expect(
          TrainingCatalogExercise.fromMap({
            ...engine.catalogRow(1, 'chest'),
            'instructions': [],
            'gif_path': path,
          }).usable,
          false,
        );
        expect(
          TrainingCatalogExercise.fromMap({
            ...engine.catalogRow(1, 'chest'),
            'target_muscle': '',
            'gif_path': path,
          }).usable,
          false,
        );
        expect(
          TrainingCatalogExercise.fromMap({
            ...engine.catalogRow(1, 'chest'),
            'equipment': '',
            'gif_path': path,
          }).usable,
          false,
        );
      }
    },
  );
  test('parser keeps exact provenance while blank and wrong-type media are optional', () {
    for (final path in [null, '', '  ', 12]) {
      final row = exercise(0);
      row['exercise_library'] = <String, dynamic>{
        ...(row['exercise_library'] as Map<String, Object>),
        'gif_path': path,
      };
      final day = WorkoutService.parseDays([
        dayRow([row]),
      ], gifUrl: (p) => 'https://example.com/$p').single;
      expect(day.canStart, true);
      expect(day.moves.single.gifUrl, isNull);
      expect(day.moves.single.gifPath, path is String ? path : null);
    }
  });
  test(
    'latest lookup reads only published exercise media and writes nothing',
    () async {
      final client = testClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/exercise_library'));
        expect(request.url.queryParameters['select'], 'gif_path');
        expect(request.url.queryParameters['id'], 'eq.${engine.fixtureId(1)}');
        expect(request.url.queryParameters['is_published'], 'eq.true');
        return jsonResponse({'gif_path': 'later.gif'});
      });
      addTearDown(client.dispose);
      expect(
        await ExerciseMediaPath.latest(engine.fixtureId(1), client: client),
        'later.gif',
      );
    },
  );
  for (final path in [null, '', '   ', 'file:///missing.gif']) {
    testWidgets('fallback for $path keeps dark container readable', (
      tester,
    ) async {
      await tester.pumpWidget(mediaApp(ExerciseMedia(path: path)));
      expect(find.text('COMING SOON'), findsOneWidget);
      final text = tester.widget<Text>(find.text('COMING SOON'));
      expect(text.style!.color, ArcColors.dark.ink);
      final contrast =
          (ArcColors.dark.ink.computeLuminance() + .05) /
          (ArcColors.dark.raised.computeLuminance() + .05);
      expect(contrast, greaterThan(4.5));
      expect(tester.getSize(find.byType(ExerciseMedia)), const Size(240, 240));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'small fallback remains readable on narrow cards with large text',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const Center(
              child: SizedBox(width: 54, height: 54, child: ExerciseMedia()),
            ),
          ),
        ),
      );
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('valid GIF decodes and replaces fallback', (tester) async {
    await tester.pumpWidget(
      mediaApp(const ExerciseMedia(path: 'assets/valid.gif')),
    );
    await decodeFrames(tester);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.text('COMING SOON'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing asset shows the same fallback without exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      mediaApp(const ExerciseMedia(path: 'assets/missing.gif')),
    );
    await decodeFrames(tester);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed network media is contained and never leaves spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      mediaApp(const ExerciseMedia(path: 'https://example.invalid/demo.gif')),
    );
    await decodeFrames(tester);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('stalled image is bounded even if provider never completes', (
    tester,
  ) async {
    await tester.pumpWidget(
      mediaApp(const ExerciseMedia(path: 'assets/stalled.gif')),
    );
    await tester.pump(const Duration(seconds: 16));
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'same saved exercise picks up later GIF on resume without regeneration',
    (tester) async {
      Object? current;
      var calls = 0;
      await tester.pumpWidget(
        mediaApp(
          ExerciseMedia(
            path: null,
            exerciseId: engine.fixtureId(1),
            lookup: (_) async {
              calls++;
              return current;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('COMING SOON'), findsOneWidget);
      current = 'assets/valid.gif';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await decodeFrames(tester);
      expect(calls, 2);
      expect(find.text('COMING SOON'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'late lookup from previous exercise cannot replace current media',
    (tester) async {
      final old = Completer<Object?>();
      Future<Object?> lookup(String id) =>
          id == engine.fixtureId(1) ? old.future : Future.value(null);
      await tester.pumpWidget(
        mediaApp(
          ExerciseMedia(exerciseId: engine.fixtureId(1), lookup: lookup),
        ),
      );
      await tester.pumpWidget(
        mediaApp(
          ExerciseMedia(exerciseId: engine.fixtureId(2), lookup: lookup),
        ),
      );
      old.complete('assets/valid.gif');
      await tester.pumpAndSettle();
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
  testWidgets(
    'Start My ARC successful preview renders optional media fallback',
    (tester) async {
      await builder.openConfiguration(tester, builder.BuilderFixture());
      await builder.generate(tester);
      expect(find.textContaining('explicitly confirm to activate'), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(ExerciseMedia).first, 300);
      expect(find.text('COMING SOON'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Browse Anatomy card and detail both render fallback and retain metadata',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => jsonResponse([
          {...engine.catalogRow(1, 'chest'), 'name': 'Fixture chest'},
        ]),
      );
      addTearDown(
        () => tester.runAsync(() async {
          await client.dispose();
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FocusWorkoutPage(muscles: const ['chest'], client: client),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fixture chest'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
      await tester.tap(find.byType(ExerciseMedia));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('COMING SOON'), findsNWidgets(2));
      expect(find.text('Exercise demo in production'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('SessionPlayer missing GIF preserves playable prescription', (
    tester,
  ) async {
    final setup = await openPlayer(tester);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('Move 0'), findsOneWidget);
    expect(find.text('SET 1'), findsOneWidget);
    expect(setup.session.exercises.first.available, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Train opens media detail even when the saved move has no GIF', (
    tester,
  ) async {
    await openTrain(tester);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.play_arrow_rounded).first,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
