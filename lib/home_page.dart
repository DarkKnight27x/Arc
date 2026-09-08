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
    this.onOpenRehab,
  });

  final VoidCallback? onOpenTrain;
  final VoidCallback? onOpenEat;
  final VoidCallback? onOpenRecover;
  final VoidCallback? onOpenYou;
  final VoidCallback? onStartSession;
  final VoidCallback? onOpenRehab;

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
                  FadeSlideIn(
                    index: 0,
                    child: Text('WEDNESDAY  ·  DAY 12',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                            color: c.faint)),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    index: 1,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: 'Good morning,',
                          style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: c.ink)),
                      TextSpan(
                          text: ' Saarthak.',
                          style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 28,
                              height: 1.1,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: c.ink)),
                    ])),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 2,
                    child: _Card(
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
                                  gradient: LinearGradient(
                                    colors: [c.chip, Color.lerp(c.chip, Colors.black, 0.15)!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.ice.withOpacity(0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
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
                          const SizedBox(height: 12),
                          _WeekDots(c: c, done: 2, total: 5),
                          const SizedBox(height: 4),
                          Text('2 of 5 this week',
                              style: TextStyle(fontSize: 12, color: c.muted)),
                          const SizedBox(height: 14),
                          MetalBtn(
                            label: 'Start session',
                            icon: Icons.play_arrow_rounded,
                            onTap: onStartSession ?? () {},
                          ),
                          const SizedBox(height: 10),
                          MetalBtn(
                            label: '10-minute version',
                            ghost: true,
                            onTap: onStartSession ?? () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 3,
                    child: _Card(
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
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    index: 4,
                    child: Text('Your five doors',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                  ),
                  const SizedBox(height: 12),
                  ..._doors(c).asMap().entries.map(
                        (e) => FadeSlideIn(index: 5 + e.key, child: e.value),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    index: 10,
                    child: _Card(
                      c: c,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REGULAR RHYTHM',
                                    style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                        color: c.brand)),
                                const SizedBox(height: 4),
                                Text('One steady thing today.',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: c.ink)),
                              ],
                            ),
                          ),
                          Text('6 day streak',
                              style: TextStyle(fontSize: 12, color: c.muted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _doors(ArcColors c) => [
    _Door(c, Icons.fitness_center, 'Train', 'Upper push · Wed', onOpenTrain),
    _Door(c, Icons.restaurant, 'Eat', '64 / 120g protein', onOpenEat),
    _Door(c, Icons.favorite_border, 'Recover', 'Ready with room to spare',
        onOpenRecover),
    _Door(c, Icons.health_and_safety_outlined, 'Rehab',
        'Shoulder check-in · idle', onOpenRehab),
    _Door(c, Icons.person_outline, 'You', '340 XP · 6-day streak', onOpenYou),
  ];
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.c, required this.done, required this.total});
  final ArcColors c;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final on = i < done;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: on ? 1 : 0),
            duration: ArcMotion.slow + (ArcMotion.fast * i),
            curve: ArcMotion.spring,
            builder: (_, v, __) => Container(
              width: 8 + (2 * v),
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(c.chip, c.ice, v),
                boxShadow: v > 0.4
                    ? [BoxShadow(color: c.ice.withOpacity(0.4 * v), blurRadius: 6)]
                    : null,
              ),
            ),
          ),
        );
      }),
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
      decoration: metalPanel(c),
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
      child: PressScale(
        onTap: onTap,
        child: _Card(
          c: c,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.chip, Color.lerp(c.chip, Colors.black, 0.18)!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
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