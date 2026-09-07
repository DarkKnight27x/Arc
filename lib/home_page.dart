import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_ctrl.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onOpenTrain,
    this.onOpenEat,
    this.onOpenRecover,
    this.onOpenYou,
    this.onStartSession,
  });

  final VoidCallback? onOpenTrain;
  final VoidCallback? onOpenEat;
  final VoidCallback? onOpenRecover;
  final VoidCallback? onOpenYou;
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeCtrl.value == ThemeMode.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: ColoredBox(
            color: c.page,
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Row(
                    children: [
                      const ArcLogo(),
                      const Spacer(),
                      Text('THANE',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                              color: c.faint)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('WEDNESDAY  ·  DAY 12',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                          color: c.faint)),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Good morning,',
                        style: TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            color: c.ink)),
                    TextSpan(
                        text: ' Saarthak.',
                        style: TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: c.ink)),
                  ])),
                  const SizedBox(height: 16),
                  _Card(
                    c: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("TODAY'S PATH",
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w600,
                                    color: c.faint)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: c.chip,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: c.cta),
                              ),
                              child: Text('PPL',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c.ice)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Upper push',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: c.ink)),
                        Text('6 movements · 42 min · machines first',
                            style: TextStyle(fontSize: 14, color: c.muted)),
                        const SizedBox(height: 10),
                        Text('2 of 5 this week',
                            style: TextStyle(fontSize: 12, color: c.muted)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: onStartSession ?? () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: c.cta,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start session',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: onStartSession ?? () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.ice,
                              side: BorderSide(color: c.line),
                              backgroundColor: c.chip,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('10-minute version',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Card(
                    c: c,
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: c.ice, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Travel week, still on track',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: c.ink)),
                              Text(
                                'Streak frozen while you are away.',
                                style: TextStyle(fontSize: 13, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Your five doors',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.ink)),
                  const SizedBox(height: 12),
                  _Door(c, Icons.fitness_center, 'Train', 'Upper push · Wed',
                      onOpenTrain),
                  _Door(c, Icons.restaurant, 'Eat', '64 / 120g protein',
                      onOpenEat),
                  _Door(c, Icons.favorite_border, 'Recover',
                      'Ready with room to spare', onOpenRecover),
                  _Door(c, Icons.health_and_safety_outlined, 'Rehab',
                      'Shoulder check-in · idle', null),
                  _Door(c, Icons.person_outline, 'You', '340 XP · 6-day streak',
                      onOpenYou),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.child});
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

class _Door extends StatelessWidget {
  const _Door(this.c, this.icon, this.title, this.subtitle, this.onTap);
  final ArcColors c;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: _Card(
          c: c,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.chip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: c.ice),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: c.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}