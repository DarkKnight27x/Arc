// Offline Android fixture. Never connects to hosted Supabase or real accounts.
import 'dart:convert';

import 'package:arc/data/plan_activation_service.dart';
import 'package:arc/data/workout_models.dart';
import 'package:arc/data/workout_service.dart';
import 'package:arc/data/workout_session.dart';
import 'package:arc/data/workout_session_service.dart';
import 'package:arc/train_page.dart';
import 'package:arc/widgets/start_arc_entry.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const firstOwner = '00000000-0000-0000-0000-000000000001';
const otherOwner = '00000000-0000-0000-0000-000000000002';
bool active = false, completed = false, unavailable = false;
int planReads = 0;
late SupabaseClient client;

Future<void> account(String owner) async {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'exp': 4102444800, 'sub': owner})))
      .replaceAll('=', '');
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.fixture',
      'refresh_token': 'offline-fixture',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': 4102444800,
      'user': {
        'id': owner,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'fixture@example.invalid',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': {},
        'user_metadata': {},
      },
    }),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  client = SupabaseClient(
    'https://offline-fixture.example.invalid',
    'fixture',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    httpClient: MockClient((request) async {
      Object body = [];
      int code = 200;
      if (request.url.path.endsWith('/workout_plans')) {
        planReads++;
        debugPrint('HOME_PROBE plan_reads=$planReads');
        if (unavailable) {
          body = {'code': '08006', 'message': 'offline fixture failure'};
          code = 503;
        } else if (active && client.auth.currentUser?.id == firstOwner) {
          body = [
            {'id': 'fixture-plan'},
          ];
        }
      } else if (request.url.path.endsWith('/workout_days')) {
        body = List.generate(
          7,
          (i) => {
            'id': 'fixture-day-${i + 1}',
            'workout_plan_id': 'fixture-plan',
            'weekday': i + 1,
            'title': 'Fixture workout ${i + 1}',
            'estimated_minutes': 20,
            'notes': 'Chest',
            'workout_day_exercises': [
              {
                'id': 'fixture-prescription-${i + 1}',
                'exercise_id': 'fixture-library',
                'sort_order': 0,
                'sets': 1,
                'reps': '5',
                'rest_seconds': 0,
                'exercise_library': {
                  'name': 'Fixture movement',
                  'equipment': 'Bodyweight',
                  'target_muscle': 'Chest',
                  'is_published': true,
                  'gif_path': null,
                  'instructions': ['Controlled movement.'],
                },
              },
            ],
          },
        );
      } else if (request.url.path.endsWith('/workout_sessions')) {
        body = completed
            ? [
                {'status': 'completed'},
              ]
            : [];
      } else if (request.url.path.endsWith('/rpc/save_workout_session')) {
        final data = (jsonDecode(request.body) as Map)['payload'] as Map;
        completed = data['status'] == 'completed';
        body = data['id'];
      }
      return http.Response(
        jsonEncode(body),
        code,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );
  await account(firstOwner);
  runApp(const MaterialApp(home: Probe(), debugShowCheckedModeBanner: false));
}

class Probe extends StatefulWidget {
  const Probe({super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  int index = 0;
  late final workouts = WorkoutService(client);
  late final sessions = WorkoutSessionService(client);
  Future<void> saveFixture() async {
    final week = await workouts.fetchWorkoutPlan();
    final WorkoutDay day = week[DateTime.now().weekday - 1];
    final session = WorkoutSession.start(firstOwner, day);
    session.toggle(0, 0);
    session.finish();
    await sessions.save(session);
    setState(() => index = 0);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(),
    child: Scaffold(
      appBar: AppBar(title: const Text('OFFLINE Home status fixture')),
      body: Column(
        children: [
          Wrap(
            children: [
              TextButton(
                onPressed: saveFixture,
                child: const Text('Complete/save fixture'),
              ),
              TextButton(
                onPressed: () => account(otherOwner),
                child: const Text('Switch owner'),
              ),
              TextButton(
                onPressed: () => client.auth.signOut(),
                child: const Text('Log out'),
              ),
              TextButton(
                onPressed: () {
                  unavailable = true;
                  WorkoutService.invalidate(client.auth.currentUser!.id);
                },
                child: const Text('Fail next read'),
              ),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: StartArcEntry(
                    workoutService: workouts,
                    sessionService: sessions,
                    isActive: index == 0,
                    onOpenTrain: () => setState(() => index = 1),
                    onActivated: () => setState(() => index = 1),
                    planBuilder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Offline activation')),
                      body: Center(
                        child: FilledButton(
                          onPressed: () {
                            active = true;
                            WorkoutService.invalidate(firstOwner);
                            Navigator.of(context).pop(
                              const ActivatedTrainingPlan('fixture-plan', 1),
                            );
                          },
                          child: const Text('Confirm fixture ARC'),
                        ),
                      ),
                    ),
                  ),
                ),
                TrainPage(workoutService: workouts, sessionService: sessions),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Train',
          ),
        ],
      ),
    ),
  );
}
