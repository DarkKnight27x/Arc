import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class TrainPage extends StatefulWidget {
  const TrainPage({super.key});
  @override
  State<TrainPage> createState() => _TrainPageState();
}

class _Move {
  const _Move({required this.name, required this.machine, required this.gif});
  final String name, machine, gif;
}

class _Region {
  const _Region(this.label, this.moves);
  final String label;
  final List<_Move> moves;
}

class _Day {
  const _Day(this.weekday, this.muscles, this.regions);
  final String weekday, muscles;
  final List<_Region> regions;
}

class _Line {
  const _Line(this.mine, this.text);
  final bool mine;
  final String text;
}

class _TrainPageState extends State<TrainPage> {
  int day = 2;
  int? open;

  static const days = <_Day>[
    _Day('Mon', 'Back + Biceps', [
      _Region('Lats', [
        _Move(name: 'Lat pulldown', machine: 'Pulldown stack', gif: ''),
        _Move(name: 'Assisted pull-up', machine: 'Assist station', gif: ''),
        _Move(name: 'Straight-arm pulldown', machine: 'High cable', gif: ''),
      ]),
      _Region('Mid back', [
        _Move(name: 'Seated row', machine: 'Cable row', gif: ''),
        _Move(name: 'Chest-supported row', machine: 'Supported row', gif: ''),
        _Move(name: 'Machine row', machine: 'Plate row', gif: ''),
      ]),
      _Region('Traps', [
        _Move(name: 'Shrug', machine: 'Smith', gif: ''),
        _Move(name: 'DB shrug', machine: 'Dumbbells', gif: ''),
        _Move(name: 'Face pull', machine: 'Rope cable', gif: ''),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench', gif: ''),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind', gif: ''),
        _Move(name: 'Drag curl', machine: 'Barbell / smith', gif: ''),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad', gif: ''),
        _Move(name: 'Concentration curl', machine: 'Dumbbell + bench', gif: ''),
        _Move(name: 'Spider curl', machine: 'Incline face-down', gif: ''),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells', gif: ''),
        _Move(name: 'Reverse curl', machine: 'EZ bar', gif: ''),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley', gif: ''),
      ]),
    ]),
    _Day('Tue', 'Legs', [
      _Region('Quads', [
        _Move(name: 'Leg press', machine: '45° press', gif: ''),
        _Move(name: 'Hack squat', machine: 'Hack sled', gif: ''),
        _Move(name: 'Leg extension', machine: 'Ext. stack', gif: ''),
      ]),
      _Region('Hamstrings', [
        _Move(name: 'Lying curl', machine: 'Curl stack', gif: ''),
        _Move(name: 'Seated curl', machine: 'Seated curl', gif: ''),
        _Move(name: 'RDL', machine: 'Barbell / DB', gif: ''),
      ]),
      _Region('Glutes', [
        _Move(name: 'Hip thrust', machine: 'Thrust bench', gif: ''),
        _Move(name: 'Glute kickback', machine: 'Cable ankle', gif: ''),
        _Move(name: 'Abductor', machine: 'Abductor stack', gif: ''),
      ]),
      _Region('Calves', [
        _Move(name: 'Standing calf', machine: 'Calf stack', gif: ''),
        _Move(name: 'Seated calf', machine: 'Seated calf', gif: ''),
        _Move(name: 'Leg-press calf', machine: 'Press plate', gif: ''),
      ]),
    ]),
    _Day('Wed', 'Chest + Biceps', [
      _Region('Upper chest', [
        _Move(name: 'Incline machine press', machine: 'Incline press', gif: ''),
        _Move(name: 'Incline smith press', machine: 'Smith', gif: ''),
        _Move(name: 'Low-to-high cable fly', machine: 'Dual cable', gif: ''),
      ]),
      _Region('Mid chest', [
        _Move(name: 'Chest press', machine: 'Seated press', gif: ''),
        _Move(name: 'Pec deck', machine: 'Pec deck', gif: ''),
        _Move(name: 'Flat DB press', machine: 'Flat bench', gif: ''),
      ]),
      _Region('Lower chest', [
        _Move(name: 'Decline machine press', machine: 'Decline press', gif: ''),
        _Move(name: 'High-to-low cable fly', machine: 'Dual cable', gif: ''),
        _Move(name: 'Dip assist', machine: 'Assist station', gif: ''),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench', gif: ''),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind', gif: ''),
        _Move(name: 'Drag curl', machine: 'Smith / bar', gif: ''),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad', gif: ''),
        _Move(name: 'Spider curl', machine: 'Incline face-down', gif: ''),
        _Move(name: 'Cable preacher', machine: 'Low pulley + pad', gif: ''),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells', gif: ''),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley', gif: ''),
        _Move(name: 'Reverse curl', machine: 'EZ bar', gif: ''),
      ]),
    ]),
    _Day('Thu', 'Shoulders + Triceps', [
      _Region('Front delt', [
        _Move(name: 'Seated shoulder press', machine: 'OHP stack', gif: ''),
        _Move(name: 'Smith press', machine: 'Smith', gif: ''),
        _Move(name: 'Front raise cable', machine: 'Low cable', gif: ''),
      ]),
      _Region('Side delt', [
        _Move(name: 'Lateral raise machine', machine: 'Fly stack', gif: ''),
        _Move(name: 'Cable lateral', machine: 'Low cable', gif: ''),
        _Move(name: 'DB lateral', machine: 'Dumbbells', gif: ''),
      ]),
      _Region('Rear delt', [
        _Move(name: 'Reverse pec deck', machine: 'Pec deck', gif: ''),
        _Move(name: 'Face pull', machine: 'Rope cable', gif: ''),
        _Move(name: 'Rear DB fly', machine: 'Dumbbells', gif: ''),
      ]),
      _Region('Triceps · long head', [
        _Move(name: 'Overhead cable ext', machine: 'Rope cable', gif: ''),
        _Move(name: 'Overhead DB ext', machine: 'Dumbbell', gif: ''),
        _Move(name: 'Incline skull crusher', machine: 'EZ + bench', gif: ''),
      ]),
      _Region('Triceps · lateral head', [
        _Move(name: 'Cable pressdown', machine: 'High pulley', gif: ''),
        _Move(name: 'V-bar pressdown', machine: 'High pulley', gif: ''),
        _Move(name: 'Kickback cable', machine: 'Low cable', gif: ''),
      ]),
      _Region('Triceps · medial', [
        _Move(name: 'Reverse pressdown', machine: 'Straight bar', gif: ''),
        _Move(name: 'Close-grip press', machine: 'Smith / press', gif: ''),
        _Move(name: 'Machine dip', machine: 'Dip stack', gif: ''),
      ]),
    ]),
    _Day('Fri', 'Back + Arms', [
      _Region('Lats', [
        _Move(name: 'Neutral pulldown', machine: 'Pulldown', gif: ''),
        _Move(name: 'Single-arm pulldown', machine: 'High cable', gif: ''),
        _Move(name: 'DB pullover', machine: 'Bench + DB', gif: ''),
      ]),
      _Region('Biceps · long head', [
        _Move(name: 'Incline DB curl', machine: 'Incline bench', gif: ''),
        _Move(name: 'Bayesian cable curl', machine: 'Low cable behind', gif: ''),
        _Move(name: 'Drag curl', machine: 'Smith', gif: ''),
      ]),
      _Region('Biceps · short head', [
        _Move(name: 'Preacher curl', machine: 'Preacher pad', gif: ''),
        _Move(name: 'Spider curl', machine: 'Incline face-down', gif: ''),
        _Move(name: 'Concentration curl', machine: 'Dumbbell', gif: ''),
      ]),
      _Region('Brachialis', [
        _Move(name: 'Hammer curl', machine: 'Dumbbells', gif: ''),
        _Move(name: 'Rope hammer cable', machine: 'Low pulley', gif: ''),
        _Move(name: 'Reverse curl', machine: 'EZ bar', gif: ''),
      ]),
      _Region('Triceps · long head', [
        _Move(name: 'Overhead cable ext', machine: 'Rope cable', gif: ''),
        _Move(name: 'Overhead DB ext', machine: 'Dumbbell', gif: ''),
        _Move(name: 'Incline skull crusher', machine: 'EZ + bench', gif: ''),
      ]),
    ]),
  ];

  void _openCoach(ArcColors c) {
    final session = days[day].muscles;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoachSheet(c: c, session: session),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const ArcLogo(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _InTab(
                      c: c,
                      label: 'Plan',
                      on: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _InTab(
                      c: c,
                      label: 'Coach',
                      on: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TrainCoachPage(session: d.muscles),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('TRAIN',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: c.faint)),
                const SizedBox(height: 6),
                Text(d.muscles,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                const SizedBox(height: 4),
                Text('3 options per part · use the machine in front of you',
                    style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _openCoach(c),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.cta.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.chip,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.cta),
                          ),
                          child: Icon(Icons.auto_awesome, size: 16, color: c.cta),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ask the coach',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.ink)),
                              Text('Swap a machine · shorten the session',
                                  style: TextStyle(fontSize: 12, color: c.muted)),
                            ],
                          ),
                        ),
                        Icon(Icons.north_east, size: 16, color: c.faint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final on = i == day;
                      return GestureDetector(
                        onTap: () => setState(() {
                          day = i;
                          open = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.chip,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: on ? c.cta : c.line),
                          ),
                          child: Text(days[i].weekday,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: on ? c.ink : c.muted)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < d.regions.length; i++)
                  _RegionTile(
                    c: c,
                    region: d.regions[i],
                    expanded: open == i,
                    onTap: () => setState(() => open = open == i ? null : i),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachSheet extends StatefulWidget {
  const _CoachSheet({required this.c, required this.session});
  final ArcColors c;
  final String session;

  @override
  State<_CoachSheet> createState() => _CoachSheetState();
}

class _CoachSheetState extends State<_CoachSheet> {
  final input = TextEditingController();
  final lines = <_Line>[];

  @override
  void initState() {
    super.initState();
    lines.addAll([
      _Line(false,
          'This block is ${widget.session}. Pick the machine that exists. I will not invent a diagnosis.'),
      _Line(false, 'Ask for a swap, a shorter cut, or what to skip.'),
    ]);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _send() {
    final t = input.text.trim();
    if (t.isEmpty) return;
    input.clear();
    setState(() {
      lines.add(_Line(true, t));
      lines.add(_Line(
        false,
        'Noted. Stay on the same region, change the machine, keep the other two options in reserve.',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: c.page,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: c.cta, size: 18),
                  const SizedBox(width: 8),
                  Text('Session coach',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink)),
                  const Spacer(),
                  Text(widget.session,
                      style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: lines.length,
                itemBuilder: (_, i) {
                  final m = lines[i];
                  return Align(
                    alignment:
                    m.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.mine ? c.cta : c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: m.mine ? null : Border.all(color: c.line),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: m.mine ? Colors.white : c.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      style: TextStyle(color: c.ink),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask for a swap…',
                        hintStyle: TextStyle(color: c.faint),
                        filled: true,
                        fillColor: c.chip,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c.cta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_upward,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: expanded ? c.cta : c.line),
        ),
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
                      child: Text(region.label,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink)),
                    ),
                    Text('3 options',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: c.faint,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              for (final m in region.moves) _MoveRow(c: c, move: m),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.chip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_circle_outline, color: c.ice),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(move.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                Text(move.machine,
                    style: TextStyle(fontSize: 13, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _InTab extends StatelessWidget {
  const _InTab({
    required this.c,
    required this.label,
    required this.on,
    required this.onTap,
  });
  final ArcColors c;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.chip,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? c.cta : c.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: on ? c.ink : c.muted)),
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
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                const SizedBox(height: 6),
                Text('Same thread as Recover. Back returns to the plan.',
                    style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.line),
                    ),
                    child: Text(
                      'Ask for a machine swap or a shorter cut. I don’t diagnose.',
                      style: TextStyle(fontSize: 15, height: 1.4, color: c.ink),
                    ),
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