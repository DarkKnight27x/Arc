import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'coach_page.dart';
import 'eat_page.dart';
import 'home_page.dart';
import 'theme_ctrl.dart';
import 'train_page.dart';
import 'you_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArcApp());
}

class ArcApp extends StatelessWidget {
  const ArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Arc',
          debugShowCheckedModeBanner: false,
          theme: arcCreamTheme(),
          darkTheme: arcDarkTheme(),
          themeMode: mode,
          home: const HomeShell(),
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

  void _go(int i) => setState(() => index = i);

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
              ),
              const TrainPage(),
              const EatPage(),
              const CoachPage(),
              const YouPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: _go,
            backgroundColor: c.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: c.chip,
            height: 64,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: c.muted),
                selectedIcon: Icon(Icons.home_rounded, color: c.cta),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined, color: c.muted),
                selectedIcon: Icon(Icons.fitness_center, color: c.cta),
                label: 'Train',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined, color: c.muted),
                selectedIcon: Icon(Icons.restaurant, color: c.cta),
                label: 'Eat',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border, color: c.muted),
                selectedIcon: Icon(Icons.favorite, color: c.cta),
                label: 'Recover',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: c.muted),
                selectedIcon: Icon(Icons.person, color: c.cta),
                label: 'You',
              ),
            ],
          ),
        );
      },
    );
  }
}