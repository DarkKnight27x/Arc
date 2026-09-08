import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class TrainPage extends StatefulWidget {
  const TrainPage({super.key});
  @override
  State<TrainPage> createState() => _TrainPageState();
}

class _Move {
  const _Move({required this.name, required this.machine, this.scheme = '3 × 10'});
  final String name, machine, scheme;
}

class _Region {
  const _Region(this.label, this.moves);
  final String label;
  final List<_Move> moves;
}

class _Day {
  const _Day(this.weekday, this.short, this.muscles, this.regions);
  final String weekday, short, muscles;
  final List<_Region> regions;
}

class _TrainPageState extends State<TrainPage> {
  int day = 2;
  int? open = 0;

  static const days = <_Day>[
    _Day('Mon', 'Back', 'Back + Biceps', [
      _Region('Lats', [
        _Move(name: 'Lat pulldown', machine: 'Pulldown stack'),
        _Move(name: 'Assisted pull-up', machine: 'Assist station'),
        _Move(name: 'Straight-arm pulldown', machine: 'High cable'),
      ]),
      _Region('Mid back', [
        _Move(name: 'Seated row', machine: 'Cable row'),
        _Move(name: 'Chest-supported row', machine: 'Supported row'),
        _Move(name: 'Machine row', machine: 'Plate row'),
      ]),
      _Region('Traps', [
        _Move(name: 'Shrug', machine: 'Smith'),
        _Move(name: 'DB shrug', machine: 'Dumbbells'),
        _Move(name: 'Face pull', machine: 'Rope cable'),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench'),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind'),
        _Move(name: 'Drag curl', machine: 'Barbell / smith'),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad'),
        _Move(name: 'Concentration curl', machine: 'Dumbbell + bench'),
        _Move(name: 'Spider curl', machine: 'Incline face-down'),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells'),
        _Move(name: 'Reverse curl', machine: 'EZ bar'),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley'),
      ]),
    ]),
    _Day('Tue', 'Legs', 'Legs', [
      _Region('Quads', [
        _Move(name: 'Leg press', machine: '45° press'),
        _Move(name: 'Hack squat', machine: 'Hack sled'),
        _Move(name: 'Leg extension', machine: 'Ext. stack'),
      ]),
      _Region('Hamstrings', [
        _Move(name: 'Lying curl', machine: 'Curl stack'),
        _Move(name: 'Seated curl', machine: 'Seated curl'),
        _Move(name: 'RDL', machine: 'Barbell / DB'),
      ]),
      _Region('Glutes', [
        _Move(name: 'Hip thrust', machine: 'Thrust bench'),
        _Move(name: 'Glute kickback', machine: 'Cable ankle'),
        _Move(name: 'Abductor', machine: 'Abductor stack'),
      ]),
      _Region('Calves', [
        _Move(name: 'Standing calf', machine: 'Calf stack'),
        _Move(name: 'Seated calf', machine: 'Seated calf'),
        _Move(name: 'Leg-press calf', machine: 'Press plate'),
      ]),
    ]),
    _Day('Wed', 'Chest', 'Chest + Biceps', [
      _Region('Upper chest', [
        _Move(name: 'Incline machine press', machine: 'Machine'),
        _Move(name: 'Incline smith', machine: 'Alternative'),
        _Move(name: 'Low-to-high cable fly', machine: 'Alternative'),
      ]),
      _Region('Mid chest', [
        _Move(name: 'Chest press', machine: 'Seated press'),
        _Move(name: 'Pec deck', machine: 'Pec deck'),
        _Move(name: 'Flat DB press', machine: 'Flat bench'),
      ]),
      _Region('Lower chest', [
        _Move(name: 'Decline machine press', machine: 'Decline press'),
        _Move(name: 'High-to-low cable fly', machine: 'Dual cable'),
        _Move(name: 'Dip assist', machine: 'Assist station'),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench'),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind'),
        _Move(name: 'Drag curl', machine: 'Smith / bar'),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad'),
        _Move(name: 'Spider curl', machine: 'Incline face-down'),
        _Move(name: 'Cable preacher', machine: 'Low pulley + pad'),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells'),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley'),
        _Move(name: 'Reverse curl', machine: 'EZ bar'),
      ]),
    ]),
    _Day('Thu', 'Shoulders', 'Shoulders + Triceps', [
      _Region('Front delt', [
        _Move(name: 'Seated shoulder press', machine: 'OHP stack'),
        _Move(name: 'Smith press', machine: 'Smith'),
        _Move(name: 'Front raise cable', machine: 'Low cable'),
      ]),
      _Region('Side delt', [
        _Move(name: 'Lateral raise machine', machine: 'Fly stack'),
        _Move(name: 'Cable lateral', machine: 'Low cable'),
        _Move(name: 'DB lateral', machine: 'Dumbbells'),
      ]),
      _Region('Rear delt', [
        _Move(name: 'Reverse pec deck', machine: 'Pec deck'),
        _Move(name: 'Face pull', machine: 'Rope cable'),
        _Move(name: 'Rear DB fly', machine: 'Dumbbells'),
      ]),
      _Region('Triceps · long head', [
        _Move(name: 'Overhead cable ext', machine: 'Rope cable'),
        _Move(name: 'Overhead DB ext', machine: 'Dumbbell'),
        _Move(name: 'Incline skull crusher', machine: 'EZ + bench'),
      ]),
      _Region('Triceps · lateral head', [
        _Move(name: 'Cable pressdown', machine: 'High pulley'),
        _Move(name: 'V-bar pressdown', machine: 'High pulley'),
        _Move(name: 'Kickback cable', machine: 'Low cable'),
      ]),
      _Region('Triceps · medial', [
        _Move(name: 'Reverse pressdown', machine: 'Straight bar'),
        _Move(name: 'Close-grip press', machine: 'Smith / press'),
        _Move(name: 'Machine dip', machine: 'Dip stack'),
      ]),
    ]),
    _Day('Fri', 'Arms', 'Back + Arms', [
      _Region('Lats', [
        _Move(name: 'Neutral pulldown', machine: 'Pulldown'),
        _Move(name: 'Single-arm pulldown', machine: 'High cable'),
        _Move(name: 'DB pullover', machine: 'Bench + DB'),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench'),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind'),
        _Move(name: 'Drag curl', machine: 'Smith'),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad'),
        _Move(name: 'Spider curl', machine: 'Incline face-down'),
        _Move(name: 'Concentration curl', machine: 'Dumbbell'),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells'),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley'),
        _Move(name: 'Reverse curl', machine: 'EZ bar'),
      ]),
      _Region('Triceps · long head', [
        _Move(name: 'Overhead cable ext', machine: 'Rope cable'),
        _Move(name: 'Overhead DB ext', machine: 'Dumbbell'),
        _Move(name: 'Incline skull crusher', machine: 'EZ + bench'),
      ]),
    ]),
  ];

  void _openCoach() {
    final session = days[day].muscles;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainCoachPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = days[day];
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        return ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                Row(
                  children: [
                    const ArcLogo(),
                    const Spacer(),
                    Text(
                      'THANE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: c.faint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'TRAIN',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: c.faint,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.muscles,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 options per part · use the machine in front of you',
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
                const SizedBox(height: 14),
                _SegBar(
                  c: c,
                  index: 0,
                  labels: const ['Plan', 'Coach'],
                  onTap: (i) => i == 1 ? _openCoach() : null,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final on = i == day;
                      return PressScale(
                        onTap: () => setState(() {
                          day = i;
                          open = 0;
                        }),
                        child: AnimatedContainer(
                          duration: ArcMotion.base,
                          curve: ArcMotion.enter,
                          width: 72,
                          decoration: BoxDecoration(
                            gradient: on
                                ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(c.raised, Colors.white, 0.04)!,
                                c.raised,
                              ],
                            )
                                : LinearGradient(
                              colors: [c.chip, c.chip],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: on
                                ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: c.ice.withOpacity(0.18),
                                blurRadius: 10,
                              ),
                            ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: ArcMotion.base,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: on ? c.ink : c.muted),
                                child: Text(days[i].weekday),
                              ),
                              Text(days[i].short,
                                  style: TextStyle(fontSize: 11, color: c.faint)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: metalPanel(c),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GYM',
                                  style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.1,
                                      color: c.faint)),
                              const SizedBox(height: 4),
                              Text('Cult Fit Thane',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: c.ink)),
                              Text('Machines available · 1.4 km',
                                  style: TextStyle(fontSize: 12, color: c.muted)),
                            ],
                          ),
                        ),
                        PressScale(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: metalWell(c),
                            child: Text('Change',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, color: c.ink)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Regions ',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.ink)),
                  TextSpan(
                      text: 'choose what exists',
                      style: TextStyle(fontSize: 13, color: c.faint)),
                ])),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: ArcMotion.base,
                  child: Column(
                    key: ValueKey(day),
                    children: [
                      for (var i = 0; i < d.regions.length; i++)
                        FadeSlideIn(
                          index: i,
                          delayStep: const Duration(milliseconds: 30),
                          child: _RegionTile(
                            c: c,
                            region: d.regions[i],
                            expanded: open == i,
                            onTap: () =>
                                setState(() => open = open == i ? null : i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: metalPanel(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASK THE COACH',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.1,
                              color: c.faint)),
                      const SizedBox(height: 6),
                      Text('Swap a machine · shorten the session.',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: c.ink)),
                      const SizedBox(height: 4),
                      Text('Keep the region. Change what is in front of you.',
                          style: TextStyle(fontSize: 13, color: c.muted)),
                      const SizedBox(height: 12),
                      PressScale(
                        onTap: _openCoach,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: metalPrimary(c),
                          child: Text('Ask coach',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: c.ctaInk)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MetalBtn(
                  label: 'Start session',
                  icon: Icons.play_arrow_rounded,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                MetalBtn(
                  label: 'Use 10-minute version',
                  ghost: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A pill segmented control with a sliding highlight, replacing the old
/// flat-border toggle. index 0 is always "active" here since Coach pushes
/// away from this page rather than switching state on it.
class _SegBar extends StatelessWidget {
  const _SegBar({
    required this.c,
    required this.index,
    required this.labels,
    required this.onTap,
  });
  final ArcColors c;
  final int index;
  final List<String> labels;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: metalWell(c),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == index;
          return Expanded(
            child: PressScale(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: ArcMotion.base,
                curve: ArcMotion.enter,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? c.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: on
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: on ? c.ink : c.muted)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.c,
    required this.region,
    required this.expanded,
    required this.onTap,
  });
  final ArcColors c;
  final _Region region;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: ArcMotion.base,
        curve: ArcMotion.enter,
        decoration: metalPanel(c, glow: expanded),
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(region.label,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.ink)),
                          Text('3 options · machine first',
                              style: TextStyle(fontSize: 12, color: c.faint)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: ArcMotion.base,
                      curve: ArcMotion.enter,
                      child: Icon(Icons.chevron_right, color: c.faint),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: ArcMotion.base,
              curve: ArcMotion.enter,
              child: expanded
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    for (var i = 0; i < region.moves.length; i++)
                      FadeSlideIn(
                        index: i,
                        delayStep: const Duration(milliseconds: 40),
                        dy: 8,
                        child: _MoveRow(c: c, move: region.moves[i]),
                      ),
                  ],
                ),
              )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.c, required this.move});
  final ArcColors c;
  final _Move move;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: metalWell(c),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.raised, Color.lerp(c.raised, Colors.black, 0.2)!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.play_arrow_rounded, color: c.ink, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(move.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                Text('${move.machine} · ${move.scheme}',
                    style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrainCoachPage extends StatelessWidget {
  const TrainCoachPage({super.key, required this.session});
  final String session;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        return Scaffold(
          backgroundColor: c.page,
          appBar: AppBar(
            backgroundColor: c.page,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: c.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Coach',
                style: TextStyle(
                    color: c.ink, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: FadeSlideIn(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: c.ink)),
                  const SizedBox(height: 8),
                  Text('Keep the region. Change the machine. I don’t diagnose.',
                      style: TextStyle(fontSize: 14, color: c.muted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}