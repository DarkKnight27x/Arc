import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arc_theme.dart';

class TrainPage extends StatefulWidget {
  const TrainPage({super.key});

  @override
  State<TrainPage> createState() => _TrainPageState();
}

class _TrainPageState extends State<TrainPage> {
  static const _days = [
    _DayData('M', 'Mon', kind: _DayKind.done),
    _DayData('T', 'Tue', kind: _DayKind.rest),
    _DayData('W', 'Wed', kind: _DayKind.planned),
    _DayData('T', 'Thu', kind: _DayKind.rest),
    _DayData('F', 'Fri', kind: _DayKind.planned),
    _DayData('S', 'Sat', kind: _DayKind.today),
    _DayData('S', 'Sun', kind: _DayKind.rest),
  ];

  static const _sessions = <int, _Session>{
    0: _Session(
      eyebrow: 'MON',
      title: '30 min · push + core',
      meta: 'Home · No floor impact',
    ),
    2: _Session(
      eyebrow: 'WED',
      title: '40 min · lower + walk',
      meta: 'Home · Controlled tempo',
    ),
    4: _Session(
      eyebrow: 'FRI',
      title: '30 min · pull + mobility',
      meta: 'Home · Easy on the joints',
    ),
    5: _Session(
      eyebrow: 'TODAY',
      title: '35 min · full-body',
      meta: 'Home · Strength, steady breathing, no jumping',
      play: true,
    ),
  };

  int selected = 5;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final session = _sessions[selected];
    final day = _days[selected];

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              dark
                  ? 'assets/images/darkBackground.png'
                  : 'assets/images/lightBackground.jpeg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Text('Your week', style: text.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Four sessions. Impact stays off while surgery-prep is on.',
                    style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: 'Lose fat', bg: p.chip, fg: p.chipInk),
                      _Chip(label: 'Surgery-prep caution', bg: p.chip, fg: p.chipInk),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _GlassDayRail(
                    days: _days,
                    selected: selected,
                    onSelect: (i) => setState(() => selected = i),
                  ),
                  const SizedBox(height: 22),
                  if (session != null)
                    _GlassSessionCard(
                      session: session,
                      featured: day.kind == _DayKind.today,
                    )
                  else
                    _GlassRestCard(dayLabel: day.name),
                  const SizedBox(height: 12),
                  for (final entry in _sessions.entries)
                    if (entry.key != selected) ...[
                      _GlassSessionCard(session: entry.value),
                      const SizedBox(height: 12),
                    ],
                  Text(
                    'Coaching, not a clinician. Stop any movement that hurts.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DayKind { today, done, planned, rest }

class _DayData {
  const _DayData(this.letter, this.name, {required this.kind});
  final String letter;
  final String name;
  final _DayKind kind;
}

class _Session {
  const _Session({
    required this.eyebrow,
    required this.title,
    required this.meta,
    this.play = false,
  });
  final String eyebrow;
  final String title;
  final String meta;
  final bool play;
}

class _GlassDayRail extends StatefulWidget {
  const _GlassDayRail({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<_DayData> days;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<_GlassDayRail> createState() => _GlassDayRailState();
}

class _GlassDayRailState extends State<_GlassDayRail> {
  double? _dragLeft;

  void _snap(int i) {
    HapticFeedback.selectionClick();
    widget.onSelect(i.clamp(0, widget.days.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, box) {
        const pad = 6.0;
        const thumb = 44.0;
        final slot = (box.maxWidth - pad * 2) / widget.days.length;
        final targetLeft = pad + widget.selected * slot + (slot - thumb) / 2;
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
            final i = ((center - pad) / slot).round().clamp(0, 6);
            setState(() => _dragLeft = null);
            _snap(i);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF141A24) : const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withOpacity(0.55)
                          : const Color(0xFFC8D0DC),
                      offset: const Offset(6, 6),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: dark ? Colors.white.withOpacity(0.07) : Colors.white,
                      offset: const Offset(-5, -5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: _dragLeft == null
                          ? const Duration(milliseconds: 280)
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      left: left,
                      top: 7,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: thumb,
                            height: thumb,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark ? const Color(0xFF1A2433) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: dark
                                      ? Colors.black.withOpacity(0.5)
                                      : const Color(0xFFC8D0DC),
                                  offset: const Offset(3, 3),
                                  blurRadius: 6,
                                ),
                                BoxShadow(
                                  color: dark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.white,
                                  offset: const Offset(-3, -3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < widget.days.length; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _snap(i),
                              child: Center(
                                child: Text(
                                  widget.days[i].letter,
                                  style: TextStyle(
                                    fontSize: i == widget.selected ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: i == widget.selected
                                        ? p.accent
                                        : (widget.days[i].kind == _DayKind.rest
                                        ? p.muted
                                        : p.ink),
                                  ),
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

class _GlassSessionCard extends StatelessWidget {
  const _GlassSessionCard({required this.session, this.featured = false});
  final _Session session;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return ArcCard(
      selected: featured,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.eyebrow,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.meta,
                  style: TextStyle(fontSize: 13, color: p.muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (session.play)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, color: p.onAccent),
            ),
        ],
      ),
    );
  }
}

class _GlassRestCard extends StatelessWidget {
  const _GlassRestCard({required this.dayLabel});
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return ArcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REST',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w600,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dayLabel is a rest day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Walk if you want. No session to protect the week.',
            style: TextStyle(fontSize: 13, color: p.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.45) : const Color(0xFFC8D0DC),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: dark ? Colors.white.withOpacity(0.06) : Colors.white,
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}