import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arc_theme.dart';
import 'coach_page.dart';
import 'eat_page.dart';
import 'theme_ctrl.dart';
import 'today_page.dart';
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        final dark = mode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'Arc',
          debugShowCheckedModeBanner: false,
          theme: arcLight(),
          darkTheme: arcDark(),
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconOn = dark ? const Color(0xFF3B82F6) : const Color(0xFF1B2B4B);
    final iconOff = dark ? const Color(0xFF8B97AB) : const Color(0xFF6B7A90);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [
          TodayPage(),
          TrainPage(),
          EatPage(),
          CoachPage(),
          YouPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: LayoutBuilder(
          builder: (context, box) {
            const pad = 6.0;
            const thumb = 46.0;
            final slot = (box.maxWidth - pad * 2) / 5;
            final left = pad + index * slot + (slot - thumb) / 2;

            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(dark ? 0.22 : 0.55),
                        Colors.white.withOpacity(dark ? 0.06 : 0.18),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(dark ? 0.45 : 0.85),
                      width: 1.4,
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        left: left,
                        top: 6,
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: thumb,
                              height: thumb,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(dark ? 0.55 : 0.95),
                                    Colors.white.withOpacity(dark ? 0.12 : 0.35),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _NavHit(
                            icon: Icons.home_rounded,
                            selected: index == 0,
                            on: iconOn,
                            off: iconOff,
                            onTap: () => setState(() => index = 0),
                          ),
                          _NavHit(
                            icon: Icons.fitness_center_rounded,
                            selected: index == 1,
                            on: iconOn,
                            off: iconOff,
                            onTap: () => setState(() => index = 1),
                          ),
                          _NavHit(
                            icon: Icons.restaurant_rounded,
                            selected: index == 2,
                            on: iconOn,
                            off: iconOff,
                            onTap: () => setState(() => index = 2),
                          ),
                          _NavHit(
                            icon: Icons.chat_bubble_rounded,
                            selected: index == 3,
                            on: iconOn,
                            off: iconOff,
                            onTap: () => setState(() => index = 3),
                          ),
                          _NavHit(
                            icon: Icons.person_rounded,
                            selected: index == 4,
                            on: iconOn,
                            off: iconOff,
                            onTap: () => setState(() => index = 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class _GlassNav extends StatefulWidget {
  const _GlassNav({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  State<_GlassNav> createState() => _GlassNavState();
}

class _GlassNavState extends State<_GlassNav> {
  static const _icons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  double? _dragLeft;

  void _snap(int i) {
    HapticFeedback.selectionClick();
    widget.onSelect(i.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconOn = dark ? const Color(0xFF3B82F6) : const Color(0xFF1B2B4B);
    final iconOff = dark ? const Color(0xFF8B97AB) : const Color(0xFF6B7A90);

    return LayoutBuilder(
      builder: (context, box) {
        const pad = 6.0;
        const barH = 58.0;
        const thumb = 46.0;
        final slot = (box.maxWidth - pad * 2) / 5;
        final targetLeft = pad + widget.index * slot + (slot - thumb) / 2;
        final left = _dragLeft ?? targetLeft;

        return GestureDetector(
          onHorizontalDragStart: (_) => _dragLeft = targetLeft,
          onHorizontalDragUpdate: (d) {
            setState(() {
              _dragLeft = (_dragLeft! + d.delta.dx).clamp(
                pad,
                box.maxWidth - pad - thumb,
              );
            });
          },
          onHorizontalDragEnd: (_) {
            final center = (_dragLeft ?? targetLeft) + thumb / 2;
            final i = ((center - pad) / slot).round().clamp(0, 4);
            setState(() => _dragLeft = null);
            _snap(i);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                height: barH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(dark ? 0.22 : 0.55),
                      Colors.white.withOpacity(dark ? 0.06 : 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(dark ? 0.45 : 0.85),
                    width: 1.4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedPositioned(
                      duration: _dragLeft == null
                          ? const Duration(milliseconds: 280)
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      left: left,
                      top: (barH - thumb) / 2,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: thumb,
                            height: thumb,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(dark ? 0.55 : 0.95),
                                  Colors.white.withOpacity(dark ? 0.12 : 0.35),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _snap(i),
                              child: Center(
                                child: Icon(
                                  _icons[i],
                                  size: 22,
                                  color: i == widget.index ? iconOn : iconOff,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class _NavHit extends StatelessWidget {
  const _NavHit({
    required this.icon,
    required this.selected,
    required this.on,
    required this.off,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color on;
  final Color off;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Icon(icon, size: 22, color: selected ? on : off),
        ),
      ),
    );
  }
}