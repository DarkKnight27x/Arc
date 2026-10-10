import 'package:arc/data/home_workout.dart';
import 'package:arc/data/home_workout_service.dart';
import 'package:arc/data/training_context_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/session_player.dart';
import 'package:arc/train_page.dart';
import 'package:arc/widgets/training_variant_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_workout_test.dart' show homeDay, buildHome;
import 'profile_test.dart' show testSession, testUserId;
import 'profile_widget_test.dart' show widgetClient;
import 'workout_session_widget_test.dart' show MemorySessionService;
import 'workout_test.dart' show jsonResponse;

class SavedWorkouts extends WorkoutService {
  SavedWorkouts(super.client, this.days);
  final List<WorkoutDay> days;
  @override
  Future<List<WorkoutDay>> fetchWorkoutPlan() async => days;
}

class SavedContext extends TrainingContextService {
  SavedContext(super.client, this.context);
  final TrainingContext context;
  @override
  Future<TrainingContext> load() async => context;
}

class ReviewedHome extends HomeWorkoutService {
  ReviewedHome(super.client);
  @override
  Future<HomeProposal> propose(
    WorkoutDay day,
    Set<String> equipment,
    int? minutes,
  ) async => buildHome(day, equipment: equipment, minutes: minutes);
}

class ExistingSessionService extends MemorySessionService {
  ExistingSessionService(super.client, this.existing);
  final WorkoutSession? existing;
  @override
  Future<WorkoutSession?> resume(
    String dayId, {
    bool reconcile = false,
  }) async => existing;
}

Future<ExistingSessionService> openTrain(
  WidgetTester tester, {
  bool hasPlan = true,
  bool rest = false,
  bool empty = false,
  WorkoutSession? current,
  double textScale = 1,
  TrainingContext context = const TrainingContext(),
}) async {
  final client = await widgetClient(tester, (r) async => jsonResponse(null));
  addTearDown(() => tester.runAsync(client.dispose));
  await testSession(client);
  final days = hasPlan
      ? List.generate(
          7,
          (i) => rest
              ? WorkoutDay(
                  id: '',
                  weekday: i + 1,
                  title: 'Rest Day',
                  isRestDay: true,
                )
              : homeDay(
                  weekday: i + 1,
                  ids: empty
                      ? []
                      : const [
                          '12fd053b-c9d7-4de4-b9f5-61c0f6d8afdf',
                          '39839277-9273-4e7d-bfbc-200f2c1b737a',
                        ],
                ),
        )
      : <WorkoutDay>[];
  final sessions = ExistingSessionService(client, current);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: TrainPage(
          workoutService: SavedWorkouts(client, days),
          contextService: SavedContext(client, context),
          homeService: ReviewedHome(client),
          sessionService: sessions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sessions;
}

void main() {
  testWidgets(
    'Train Home proposal remains usable at 320px and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openTrain(
        tester,
        textScale: 2,
        context: const TrainingContext(location: 'home'),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Dumbbells'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbells'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review & start Home'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('no plan, rest and empty saved day offer no session start', (
    tester,
  ) async {
    await openTrain(tester, hasPlan: false);
    expect(find.text('No active training plan yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await openTrain(tester, rest: true);
    expect(find.byType(TrainingVariantPanel), findsNothing);
    expect(find.text('Start / resume session'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await openTrain(tester, empty: true);
    expect(find.text('Start / resume session'), findsNothing);
  });
  testWidgets(
    'Home preview cannot overwrite in-progress Gym; continue restores exact snapshot',
    (tester) async {
      final day = homeDay(weekday: DateTime.now().weekday);
      final current = WorkoutSession.start(testUserId, day);
      current.toggle(0, 0);
      final service = await openTrain(
        tester,
        current: current,
        context: const TrainingContext(
          injuryWarning: true,
          reportStatus: 'active',
        ),
      );
      await tester.ensureVisible(find.text('Home alternative'));
      await tester.tap(find.text('Home alternative'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Dumbbells'));
      await tester.tap(find.text('Dumbbells'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review & start Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & start Home'));
      await tester.pumpAndSettle();
      expect(find.text('Current gym session'), findsOneWidget);
      expect(find.text('End / discard current'), findsOneWidget);
      await tester.tap(find.text('Keep current draft'));
      await tester.pumpAndSettle();
      expect(service.saves, isEmpty);
      await tester.ensureVisible(find.text('Review & start Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & start Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue current session'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionPlayer), findsOneWidget);
      expect(current.trainingLocation, 'gym');
      expect(current.exercises.first.exerciseId, day.moves.first.exerciseId);
      expect(current.doneSets, 1);
      expect(current.injuryWarning, isTrue);
      expect(service.saves.last['id'], current.id);
      expect(service.saves.last['training_location'], 'gym');
    },
  );
  testWidgets(
    'profile Home preference starts bodyweight only and individual location can change',
    (tester) async {
      await openTrain(
        tester,
        context: const TrainingContext(location: 'home', minutes: 15),
      );
      await tester.ensureVisible(find.text('No equipment'));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'No equipment'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '15 minutes'))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.text('Gym - saved plan'));
      await tester.tap(find.text('Gym - saved plan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start / resume session'));
      expect(find.text('Start / resume session'), findsOneWidget);
    },
  );
}
