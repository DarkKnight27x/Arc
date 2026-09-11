import 'package:flutter/material.dart';
import 'data/workout_models.dart';
import 'data/workout_service.dart';
import 'theme_ctrl.dart';

class TrainPage extends StatefulWidget {
  const TrainPage({super.key});
  @override
  State<TrainPage> createState() => _TrainPageState();
}

class _TrainPageState extends State<TrainPage> {
  List<WorkoutDay> _days = [];
  int _dayIndex = 0;
  int? open = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final data = await WorkoutService.instance.fetchWorkoutPlan();
    if (!mounted) return;
    setState(() {
      _days = data;
      _loading = false;
    });
  }

  void _openCoach() {
    if (_days.isEmpty) return;
    final session = _days[_dayIndex].title;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainCoachPage(session: session),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return 'Day';
    return names[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        
        if (_loading) {
          return Center(child: CircularProgressIndicator(color: c.brand));
        }

        if (_days.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No workout plan found.',
                  style: TextStyle(color: c.muted, fontSize: 16),
                ),
                const SizedBox(height: 12),
                MetalBtn(
                  label: 'Refresh',
                  onTap: _loadWorkout,
                ),
              ],
            ),
          );
        }

        final d = _days[_dayIndex];

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
                  d.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.estimatedMinutes} min estimated · machines first',
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
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final on = i == _dayIndex;
                      return PressScale(
                        onTap: () => setState(() {
                          _dayIndex = i;
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
                                child: Text(_weekdayName(_days[i].weekday)),
                              ),
                              Text(_days[i].muscles.isNotEmpty ? _days[i].muscles : 'Plan',
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
                    key: ValueKey(_dayIndex),
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
  final WorkoutRegion region;
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
                          Text('${region.moves.length} options · machine first',
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
  final WorkoutMove move;

  void _showGif(BuildContext context) {
    if (move.gifUrl == null) return;
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: metalPanel(c, radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  move.gifUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(color: c.brand),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      move.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      move.machine,
                      style: TextStyle(color: c.muted),
                    ),
                    const SizedBox(height: 16),
                    MetalBtn(
                      label: 'Close',
                      ghost: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: metalWell(c),
      child: Row(
        children: [
          PressScale(
            onTap: () => _showGif(context),
            child: Container(
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
              child: Icon(
                move.gifUrl != null ? Icons.play_arrow_rounded : Icons.info_outline,
                color: c.ink,
                size: 18,
              ),
            ),
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
