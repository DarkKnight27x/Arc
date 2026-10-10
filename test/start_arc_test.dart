import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arc/start_arc_page.dart';
import 'package:arc/widgets/start_arc_entry.dart';
import 'package:arc/data/arc_plan_builder_service.dart';
import 'package:arc/data/profile_service.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:arc/data/training_plan_generator.dart';

import 'training_plan_generator_test.dart' show completeFixture, catalogRow;
import 'profile_test.dart' show testClient, testSession, testUserId;
import 'workout_test.dart' show jsonResponse;
import 'profile_widget_test.dart' show widgetClient;

class BuilderFixture implements ArcPlanBuilderSource {
  bool unavailable = false, failLoad = false, failGenerate = false;
  int loads = 0;
  TrainingPlanConfig? generated;
  @override
  Future<ProfileRow?> profile() async {
    if (failLoad) throw StateError('Fixture network failure');
    return const ProfileRow(
      userId: testUserId,
      fitnessGoal: 'Build muscle',
      experienceLevel: 'Beginner',
      trainDays: 3,
      age: 25,
      workoutLocation: 'Gym',
      sessionDurationMinutes: 90,
    );
  }

  @override
  Future<TrainingCatalog> catalog() async {
    loads++;
    return TrainingCatalog(completeFixture());
  }

  @override
  Future<TrainingGenerationResult> generate(TrainingPlanConfig config) async {
    if (failGenerate) throw StateError('Fixture interruption');
    generated = config;
    final rows = await catalog();
    return TrainingPlanGenerator().generate(
      config,
      unavailable
          ? TrainingCatalog(
              rows.exercises.where(
                (e) => e.metadata.primaryMuscle != 'hamstrings',
              ),
            )
          : rows,
    );
  }
}

Future<void> openConfiguration(
  WidgetTester tester,
  BuilderFixture source, {
  Brightness brightness = Brightness.dark,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: StartArcPage(
        source: source,
        priorityPicker: (_, current) async => ['chest', 'hamstring'],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select Priority Muscles'));
  await tester.pumpAndSettle();
}

Future<void> generate(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Dumbbells'), 400);
  await tester.tap(find.text('Dumbbells'));
  await tester.scrollUntilVisible(find.text('Generate Plan'), 300);
  await tester.tap(find.text('Generate Plan'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'narrow screen with larger text supports configuration and unavailable result',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = BuilderFixture()..unavailable = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: StartArcPage(
            source: source,
            priorityPicker: (_, current) async => ['hamstring'],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select Priority Muscles'));
      await tester.pumpAndSettle();
      await generate(tester);
      await tester.scrollUntilVisible(find.text('Edit configuration'), 250);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'journey selection accepts 60 and 90 days without changing training weekdays',
    (tester) async {
      for (final days in [60, 90]) {
        final source = BuilderFixture();
        await tester.pumpWidget(const SizedBox());
        await openConfiguration(tester, source);
        await tester.scrollUntilVisible(find.text('30 days'), 300);
        await tester.tap(find.text('30 days'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('$days days').last);
        await tester.pumpAndSettle();
        await generate(tester);
        expect(source.generated!.journeyDays, days);
        expect(source.generated!.weekdays, [1, 3, 5]);
      }
    },
  );
  test('catalog discards completion from a different account', () async {
    late final dynamic client;
    bool switched = false;
    client = testClient((request) async {
      if (!switched) {
        switched = true;
        await testSession(client, id: '00000000-0000-0000-0000-000000000002');
      }
      return jsonResponse(
        request.url.queryParameters['offset'] == '0'
            ? [catalogRow(1, 'chest')]
            : [],
      );
    });
    addTearDown(client.dispose);
    await testSession(client);
    final source = ArcPlanBuilderService(client);
    final loaded = await source.catalog();
    expect(loaded.exercises, isEmpty);
    expect(loaded.issues.single.code, TrainingIssueCode.catalogUnavailable);
  });
  test(
    'anatomy IDs share canonical vocabulary; unrelated body regions excluded',
    () {
      expect(canonicalMuscle('deltoids'), 'shoulders');
      expect(canonicalMuscle('gluteal'), 'glutes');
      expect(canonicalMuscle('hamstring'), 'hamstrings');
      expect(canonicalMuscle('forearm'), 'forearms');
      expect(canonicalMuscle('upper-back'), 'upper_back');
      expect(canonicalMuscle('lower-back'), 'spinal_extensors');
      expect(anatomyPriorityIds, isNot(contains('hair')));
      expect(canonicalEquipment('body weight'), 'bodyweight');
      expect(canonicalEquipment('dumbbell'), 'dumbbells');
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'profile-prefilled flow renders complete preview in ${brightness.name}',
      (tester) async {
        final source = BuilderFixture();
        await openConfiguration(tester, source, brightness: brightness);
        expect(find.text('Configure ARC'), findsOneWidget);
        expect(find.text('Build muscle'), findsOneWidget);
        expect(find.text('90 minutes'), findsOneWidget);
        await generate(tester);
        expect(find.text('Your ARC Preview'), findsOneWidget);
        expect(source.generated!.weekdays, [1, 3, 5]);
        expect(source.generated!.priorities, {'chest', 'hamstrings'});
        expect(source.generated!.journeyDays, 30);
        expect(source.loads, 2);
        expect(find.text('Monday · Full body'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Sunday · Rest day'), 500);
        expect(find.text('Sunday · Rest day'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unavailable shows unsupported priority and editable configuration',
    (tester) async {
      final source = BuilderFixture()..unavailable = true;
      await openConfiguration(tester, source);
      await generate(tester);
      expect(
        find.textContaining("This training combination isn't available yet"),
        findsOneWidget,
      );
      expect(
        find.text('Priorities needing coverage: Hamstrings'),
        findsOneWidget,
      );
      expect(find.textContaining('missingMuscles'), findsNothing);
      await tester.ensureVisible(find.text('Edit configuration'));
      await tester.tap(find.text('Edit configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Configure ARC'), findsOneWidget);
    },
  );
  testWidgets('loading failure is retryable and sanitized', (tester) async {
    final source = BuilderFixture()..failLoad = true;
    await tester.pumpWidget(MaterialApp(home: StartArcPage(source: source)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fixture network'), findsNothing);
    source.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Select Priority Muscles'), findsOneWidget);
  });
  testWidgets('generation interruption keeps editable form', (tester) async {
    final source = BuilderFixture()..failGenerate = true;
    await openConfiguration(tester, source);
    await generate(tester);
    expect(find.text('Configure ARC'), findsOneWidget);
    expect(
      find.text('We could not generate your preview. Please try again.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Generate Plan'), 200);
    expect(find.text('Generate Plan'), findsOneWidget);
  });
  testWidgets(
    'no active plan entry is scoped and navigates; active plan hides it',
    (tester) async {
      bool active = false, opened = false;
      final client = await widgetClient(tester, (request) async {
        expect(request.method, 'GET');
        if (!request.url.path.endsWith('workout_plans')) return jsonResponse([]);
        expect(request.url.queryParameters['user_id'], 'eq.$testUserId');
        expect(request.url.queryParameters['plan_type'], 'eq.training');
        return jsonResponse(
          active
              ? [
                  {'id': 'fixture-plan'},
                ]
              : [],
        );
      });
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.runAsync(() => testSession(client));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartArcEntry(
              client: client,
              openBuilder: () => opened = true,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start My ARC'));
      expect(opened, true);
      await tester.pumpWidget(const SizedBox());
      active = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StartArcEntry(client: client)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start My ARC'), findsNothing);
    },
  );
  test(
    'runtime builder re-reads library each generation and performs only GETs',
    () async {
      int libraryReads = 0;
      final client = testClient((request) async {
        expect(request.method, 'GET');
        final path = request.url.path;
        expect(path.contains('exercise_generation_profiles'), false);
        if (path.endsWith('profiles')) {
          return jsonResponse({
            'user_id': testUserId,
            'age': 25,
            'user_state': {},
          });
        }
        if (path.endsWith('rehab_cases')) return jsonResponse([]);
        if (path.endsWith('exercise_library')) {
          libraryReads++;
          final offset = int.parse(
            request.url.queryParameters['offset'] ?? '0',
          );
          return jsonResponse(offset == 0 ? [catalogRow(1, 'chest')] : []);
        }
        throw StateError('Unexpected request');
      });
      addTearDown(client.dispose);
      await testSession(client);
      final service = ArcPlanBuilderService(client);
      final config = TrainingPlanConfig(
        goal: TrainingGoal.buildMuscle,
        experience: TrainingExperience.beginner,
        weekdays: [1, 4],
        equipment: ['dumbbells'],
        sessionMinutes: 90,
        journeyDays: 60,
        age: 25,
      );
      await service.generate(config);
      final before = libraryReads;
      await service.generate(config);
      expect(libraryReads, greaterThan(before));
    },
  );
  test(
    'Browse retains default behavior and selection mode isolates global focus',
    () {
      final page = File('lib/anatomy_test_page.dart').readAsStringSync();
      expect(page, contains('this.prioritySelection = false'));
      expect(page, contains('FocusWorkoutPage(muscles: List.of(_selected))'));
      final branch = page.substring(
        page.indexOf('if (widget.prioritySelection) {'),
        page.indexOf('final name = msg.message.trim();'),
      );
      expect(branch, contains('return;'));
      expect(branch, isNot(contains('MuscleFocus.selected')));
    },
  );
}
