import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class EatPage extends StatelessWidget {
  const EatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        return ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _Bar(c: c),
                const SizedBox(height: 18),
                Text('EAT  ·  WEDNESDAY',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: c.faint,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Feed the\n',
                      style: TextStyle(
                          fontSize: 34,
                          height: 1.08,
                          color: c.ink,
                          fontWeight: FontWeight.w500)),
                  TextSpan(
                      text: 'training.',
                      style: TextStyle(
                          fontSize: 34,
                          height: 1.08,
                          fontStyle: FontStyle.italic,
                          color: c.ink,
                          fontWeight: FontWeight.w500)),
                ])),
                const SizedBox(height: 8),
                Text('Indian plates, a clear budget.',
                    style: TextStyle(fontSize: 14, color: c.muted)),
                const SizedBox(height: 16),
                _Box(
                  c: c,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROTEIN TODAY',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                    color: c.faint)),
                            const SizedBox(height: 6),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: '64',
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: c.ink)),
                              TextSpan(
                                  text: '  /  120 g',
                                  style:
                                  TextStyle(fontSize: 14, color: c.muted)),
                            ])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('BUDGET',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                  color: c.faint)),
                          const SizedBox(height: 6),
                          Text('₹90  /  ₹250',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text("Today's plate",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                const SizedBox(height: 10),
                _Meal('BREAKFAST', 'Idli + sambar + 2 eggs', '24g', c),
                _Meal('LUNCH', 'Roti + palak + dal + curd', '29g', c),
                _Meal('DINNER', 'Family plate · leave room for dal', 'flexible', c),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: c.cta,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('+  Log a meal',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.c});
  final ArcColors c;
  @override
  Widget build(BuildContext context) {
    return const ArcLogo();
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.c, required this.child});
  final ArcColors c;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

class _Meal extends StatelessWidget {
  const _Meal(this.slot, this.title, this.p, this.c);
  final String slot, title, p;
  final ArcColors c;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Box(
        c: c,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot,
                      style: TextStyle(
                          fontSize: 11, letterSpacing: 1.0, color: c.faint)),
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.ink)),
                ],
              ),
            ),
            Text(p, style: TextStyle(fontSize: 13, color: c.ice)),
          ],
        ),
      ),
    );
  }
}