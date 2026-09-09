import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/auth_gate.dart';
import 'coach_page.dart';
import 'eat_page.dart';
import 'home_page.dart';
import 'theme_ctrl.dart';
import 'train_page.dart';
import 'you_page.dart';
import 'rehab_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbojicqbpqgotdmdayku.supabase.co',
    publishableKey: 'sb_publishable_Ies5q2ep0It3CJPUoPYf0A_0J4O2azG',
  );

  runApp(const ArcApp());
}

class ArcApp extends StatelessWidget {
  const ArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        final dark = mode == ThemeMode.dark;

        SystemChrome.setSystemUIOverlayStyle(
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );

        return MaterialApp(
          title: 'Arc',
          debugShowCheckedModeBanner: false,
          theme: arcCreamTheme(),
          darkTheme: arcDarkTheme(),
          themeMode: mode,

          // Authentication now comes before the main app.
          home: const AuthGate(
            app: HomeShell(),
          ),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  void _go(int i) {
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);

        return Scaffold(
          backgroundColor: c.page,

          body: IndexedStack(
            index: index,
            children: [
              HomePage(
                onOpenTrain: () => _go(1),
                onOpenEat: () => _go(2),
                onOpenRecover: () => _go(3),
                onOpenYou: () => _go(4),
                onStartSession: () => _go(1),
                onOpenRehab: () => showRehabSheet(context),
              ),

              const TrainPage(),
              const EatPage(),
              const CoachPage(),
              const YouPage(),
            ],
          ),

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: c.shell,
              border: Border(
                top: BorderSide(color: c.line),
              ),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _go,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: c.raised,
              height: 68,
              destinations: [
                _dest(
                  c,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                  0,
                ),
                _dest(
                  c,
                  Icons.fitness_center_outlined,
                  Icons.fitness_center,
                  'Train',
                  1,
                ),
                _dest(
                  c,
                  Icons.restaurant_outlined,
                  Icons.restaurant,
                  'Eat',
                  2,
                ),
                _dest(
                  c,
                  Icons.favorite_border,
                  Icons.favorite,
                  'Recover',
                  3,
                ),
                _dest(
                  c,
                  Icons.person_outline,
                  Icons.person,
                  'You',
                  4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  NavigationDestination _dest(
      ArcColors c,
      IconData off,
      IconData on,
      String label,
      int i,
      ) {
    final sel = index == i;

    return NavigationDestination(
      icon: Icon(
        off,
        color: c.muted,
      ),
      selectedIcon: Icon(
        on,
        color: sel ? c.ink : c.muted,
      ),
      label: label,
    );
  }
}