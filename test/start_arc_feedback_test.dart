import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arc/data/arc_plan_builder_service.dart';
import 'package:arc/data/profile_service.dart';
import 'package:arc/data/training_plan_generator.dart';
import 'package:arc/data/training_plan_models.dart';
import 'package:arc/start_arc_page.dart';
import 'package:arc/theme_ctrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'training_plan_generator_test.dart' show completeFixture;

class FeedbackFixture implements ArcPlanBuilderSource {
  int calls = 0;
  bool missingLocation = false;
  var completion = Completer<TrainingGenerationResult>();
  @override
  Future<ProfileRow?> profile() async => ProfileRow(
    userId: 'fixture-owner',
    age: 25,
    fitnessGoal: 'Build muscle',
    experienceLevel: 'Beginner',
    trainDays: 3,
    sessionDurationMinutes: 90,
    workoutLocation: missingLocation ? null : 'Gym',
  );
  @override
  Future<TrainingCatalog> catalog() async => TrainingCatalog(completeFixture());
  @override
  Future<TrainingGenerationResult> generate(TrainingPlanConfig config) {
    calls++;
    return completion.future;
  }
}

Future<void> configure(WidgetTester tester, FeedbackFixture fixture) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: arcDarkTheme(),
      home: StartArcPage(
        source: fixture,
        priorityPicker: (_, current) async => [],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select Priority Muscles'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Dumbbells'), 300);
  await tester.tap(find.text('Dumbbells'));
  await tester.scrollUntilVisible(find.text('Generate Plan'), 300);
}

TrainingGenerationResult available() => TrainingPlanGenerator().generate(
  TrainingPlanConfig(
    goal: TrainingGoal.buildMuscle,
    experience: TrainingExperience.beginner,
    weekdays: [1, 3, 5],
    equipment: ['dumbbells'],
    sessionMinutes: 90,
    journeyDays: 30,
    age: 25,
  ),
  TrainingCatalog(completeFixture()),
);

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    themeCtrl.value = ThemeMode.dark;
  });
  testWidgets('Generate invokes once, shows loading and clears it on success', (
    tester,
  ) async {
    final fixture = FeedbackFixture();
    await configure(tester, fixture);
    await tester.tap(find.text('Generate Plan'));
    await tester.tap(
      find.text('Generate Plan'),
    ); // Same frame, before disabled UI.
    expect(fixture.calls, 1);
    await tester.pump();
    expect(find.text('Generating your plan…').hitTestable(), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    fixture.completion.complete(available());
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('30-day ARC journey').hitTestable(), findsOneWidget);
  });
  testWidgets(
    'exception clears loading, displays visible sanitized error and retries',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      fixture.completion.completeError(
        StateError('Sensitive server fixture error'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find
            .text('We could not generate your preview. Please try again.')
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.textContaining('Sensitive server'), findsNothing);
      fixture.completion = Completer<TrainingGenerationResult>();
      await tester.tap(find.text('Retry generation'));
      await tester.pump();
      expect(fixture.calls, 2);
      expect(find.text('Generating your plan…').hitTestable(), findsOneWidget);
      fixture.completion.complete(available());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('30-day ARC journey').hitTestable(), findsOneWidget);
    },
  );
  testWidgets(
    'timeout clears loading and late completion cannot replace retry',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      final timedOut = fixture.completion;
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Retry generation').hitTestable(), findsOneWidget);
      fixture.completion = Completer<TrainingGenerationResult>();
      await tester.tap(find.text('Retry generation'));
      await tester.pump();
      timedOut.complete(available());
      await tester.pump();
      expect(find.text('Generating your plan…').hitTestable(), findsOneWidget);
      fixture.completion.complete(available());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'actual catalog unavailable result visibly lists required leg areas without priorities',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      final audit = jsonDecode(
        File('docs/phase2c_readonly_database_audit.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final catalog = TrainingCatalog(
        (audit['catalog_rows'] as List).map(
          (r) => TrainingCatalogExercise.fromMap(Map<String, dynamic>.from(r)),
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
          sessionMinutes: 90,
          journeyDays: 30,
          age: 25,
        ),
        catalog,
      );
      expect(result.available, false);
      fixture.completion.complete(result);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find
            .textContaining("This training combination isn't available yet")
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        find
            .text('Required areas needing coverage: Hamstrings, Quadriceps')
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.textContaining('missingMuscles'), findsNothing);
      await tester.scrollUntilVisible(find.text('Retry generation'), 150);
      fixture.completion = Completer<TrainingGenerationResult>();
      await tester.tap(find.text('Retry generation'));
      await tester.pump();
      expect(fixture.calls, 2);
      fixture.completion.complete(result);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Edit configuration'), 150);
      await tester.tap(find.text('Edit configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Configure ARC'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Fitness goal')).dy, inInclusiveRange(0,600));
    },
  );
  testWidgets(
    'catalog fetch result error is retryable rather than a coverage claim',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      fixture.completion.complete(
        TrainingGenerationResult(
          catalogCount: 0,
          eligibleCount: 0,
          issues: [
            TrainingIssue(
              TrainingIssueCode.catalogUnavailable,
              'Internal fixture detail',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find
            .text('We could not load the exercise catalog. Please try again.')
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Internal fixture'), findsNothing);
    },
  );
  testWidgets(
    'completion after leaving the page does not update disposed state',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      fixture.completion.complete(available());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'local controls, disabled states and dropdown popup use ARC contrast tokens',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      final local = Theme.of(tester.element(find.text('Generate Plan')));
      final c = ArcColors.dark;
      expect(local.textTheme.bodyMedium!.color, c.ink);
      expect(local.inputDecorationTheme.labelStyle!.color, c.muted);
      expect(local.inputDecorationTheme.helperStyle!.color, c.muted);
      expect(
        local.filledButtonTheme.style!.foregroundColor!.resolve({
          WidgetState.disabled,
        }),
        c.muted,
      );
      expect(
        local.filledButtonTheme.style!.backgroundColor!.resolve({
          WidgetState.disabled,
        }),
        c.chip,
      );
      expect(local.textButtonTheme.style!.foregroundColor!.resolve({}), c.ink);
      expect(local.chipTheme.selectedColor, c.ink);
      expect(local.cardTheme.color, c.surface);
      await tester.scrollUntilVisible(find.text('Monday'), -200);
      expect(tester.widget<Text>(find.text('Monday')).style!.color, c.page);
      expect(tester.widget<Text>(find.text('Tuesday')).style!.color, c.ink);
      await tester.scrollUntilVisible(find.text('Gym'), -250);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.dropdownColor, c.surface);
      expect(dropdown.style!.color, c.ink);
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();
      final popup = Theme.of(tester.element(find.text('Home').last));
      expect(popup.textTheme.bodyMedium!.color, c.ink);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ARC dark configuration body and dropdown values are readable', (
    tester,
  ) async {
    final fixture = FeedbackFixture();
    await configure(tester, fixture);
    await tester.scrollUntilVisible(
      find.text(
        'Your existing profile preferences are filled in where available. These choices apply to this preview.',
      ),
      -300,
    );
    final element = tester.element(
      find.text(
        'Your existing profile preferences are filled in where available. These choices apply to this preview.',
      ),
    );
    expect(DefaultTextStyle.of(element).style.color, ArcColors.dark.ink);
  });
  testWidgets(
    'incomplete configuration produces visible recoverable feedback',
    (tester) async {
      final fixture = FeedbackFixture()..missingLocation = true;
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();
      expect(fixture.calls, 0);
      expect(
        find.textContaining('Choose a goal').hitTestable(),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'result content starts at the top after generating from bottom of form',
    (tester) async {
      final fixture = FeedbackFixture();
      await configure(tester, fixture);
      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      fixture.completion.complete(available());
      await tester.pumpAndSettle();
      expect(find.text('30-day ARC journey').hitTestable(), findsOneWidget);
      expect(find.text('Monday · Full body').hitTestable(), findsOneWidget);
    },
  );
}
