// Local-only Android reproduction harness. No hosted account or database calls.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/train_page.dart';

class FixtureWorkouts extends WorkoutService {
  FixtureWorkouts()
    : super(SupabaseClient('http://127.0.0.1:1', 'local-fixture'));
  @override
  Future<List<WorkoutDay>> fetchWorkoutPlan() async => List.generate(
    7,
    (i) => WorkoutDay(
      id: '20000000-0000-0000-0000-000000000001',
      planId: '30000000-0000-0000-0000-000000000001',
      weekday: i + 1,
      title: 'Navigation fixture',
      regions: const [
        WorkoutRegion(
          label: 'Chest',
          moves: [
            WorkoutMove(
              id: '40000000-0000-0000-0000-000000000001',
              exerciseId: '50000000-0000-0000-0000-000000000001',
              name: 'No GIF fixture',
              machine: 'Bodyweight',
              sortOrder: 0,
              primaryTarget: 'chest',
              instructions: ['Controlled movement.'],
            ),
            WorkoutMove(
              id: '40000000-0000-0000-0000-000000000002',
              exerciseId: '50000000-0000-0000-0000-000000000002',
              name: 'GIF fixture',
              machine: 'Bodyweight',
              sortOrder: 1,
              primaryTarget: 'chest',
              gifPath: 'assets/trainerAnimations/Avatar.gif',
              instructions: ['Controlled movement.'],
            ),
          ],
        ),
      ],
    ),
  );
}

class StackLog extends NavigatorObserver {
  StackLog(this.label);
  final String label;
  final routes = <Route<dynamic>>[];
  void log() => debugPrint(
    'NAV_PROBE $label stack=${routes.map((r) => r.settings.name ?? r.runtimeType.toString()).toList()}',
  );
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    log();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
    log();
  }
}

void main() {
  final inner = GlobalKey<NavigatorState>();
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      navigatorObservers: [StackLog('root')],
      home: NavigatorPopHandler<Object?>(
        onPopWithResult: (result) => inner.currentState?.pop(result),
        child: Navigator(
          key: inner,
          observers: [StackLog('signed-in')],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home-train'),
            builder: (_) =>
                Scaffold(body: TrainPage(workoutService: FixtureWorkouts())),
          ),
        ),
      ),
    ),
  );
}
