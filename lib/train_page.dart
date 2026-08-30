import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _page = Color(0xFFF3F6F1);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);
const _coolBg = Color(0xFFE7EEF2);
const _coolInk = Color(0xFF3D5A66);

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
    final session = _sessions[selected];
    final day = _days[selected];

    return ColoredBox(
      color: _page,
      child: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text('Your week', style: text.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  'Four sessions. Impact stays off while surgery-prep is on.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'Lose fat'),
                    _Chip(label: 'Surgery-prep caution'),
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
                const Text(
                  'Coaching, not a clinician. Stop any movement that hurts.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: _muted),
                ),
              ],
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

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -40, right: -60, child: _Blob(Color(0xFFB7D4C8), 220)),
          Positioned(top: 220, left: -80, child: _Blob(Color(0xFFE8D7B8), 200)),
          Positioned(bottom: 80, right: -40, child: _Blob(Color(0xFFD7E6DF), 180)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
      ),
    );
  }
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
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.62),
                      Colors.white.withOpacity(0.28),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.72)),
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
                      top: 6,
                      child: const _GlassThumb(size: thumb),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < widget.days.length; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _snap(i),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: i == widget.selected ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: i == widget.selected
                                        ? _teal
                                        : (widget.days[i].kind == _DayKind.rest
                                        ? _muted.withOpacity(0.7)
                                        : _ink),
                                  ),
                                  child: Text(widget.days[i].letter),
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

class _GlassThumb extends StatelessWidget {
  const _GlassThumb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.92),
                const Color(0xFFDCEDE4).withOpacity(0.55),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.emphasized = false});
  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: emphasized
                  ? [
                const Color(0xFFDCEDE4).withOpacity(0.72),
                Colors.white.withOpacity(0.38),
              ]
                  : [
                Colors.white.withOpacity(0.58),
                Colors.white.withOpacity(0.24),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassSessionCard extends StatelessWidget {
  const _GlassSessionCard({required this.session, this.featured = false});
  final _Session session;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      emphasized: featured,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.eyebrow,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.meta,
                  style: const TextStyle(fontSize: 13, color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (session.play)
            const SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
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
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REST',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dayLabel is a rest day',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Walk if you want. No session to protect the week.',
            style: TextStyle(fontSize: 13, color: _muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _coolBg.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _coolInk,
            ),
          ),
        ),
      ),
    );
  }
}