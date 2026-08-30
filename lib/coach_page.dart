import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _page = Color(0xFFF3F6F1);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  late List<_Msg> _msgs;

  @override
  void initState() {
    super.initState();
    _msgs = [
      _Msg.coach(
        'Morning, Saarthak. Surgery-prep is on and energy looks low. Tell me what changed — I’ll move the plan, not just talk.',
      ),
      _Msg.receipt(
        title: 'Plan set from your passport',
        session: '4 days · 30–45 min',
        intensity: 'Low impact while surgery-prep is on',
      ),
    ];
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _sendChip(_ChipAction a) {
    HapticFeedback.selectionClick();
    setState(() {
      _msgs.add(_Msg.user(a.label));
      _msgs.add(_Msg.coach(a.reply));
      _msgs.add(
        _Msg.receipt(
          title: a.receiptTitle,
          session: a.session,
          intensity: a.intensity,
        ),
      );
    });
    _jump();
  }

  void _sendText() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    HapticFeedback.lightImpact();
    _input.clear();
    setState(() {
      _msgs.add(_Msg.user(t));
      _msgs.add(
        _Msg.coach(
          'Noted. I’ll keep the habit and adjust load. Use a chip if you want the plan rewritten now.',
        ),
      );
    });
    _jump();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: _page,
      child: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach', style: text.headlineLarge),
                      const SizedBox(height: 6),
                      const Text(
                        'Tell it what changed. Today and Train will move.',
                        style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: _msgs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _Bubble(msg: _msgs[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final a in _ChipAction.all) ...[
                          _GlassChip(
                            label: a.label,
                            onTap: () => _sendChip(a),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _GlassComposer(
                    controller: _input,
                    onSend: _sendText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Kind { coach, user, receipt }

class _Msg {
  const _Msg._({
    required this.kind,
    this.body = '',
    this.title = '',
    this.session = '',
    this.intensity = '',
  });

  factory _Msg.coach(String body) => _Msg._(kind: _Kind.coach, body: body);
  factory _Msg.user(String body) => _Msg._(kind: _Kind.user, body: body);
  factory _Msg.receipt({
    required String title,
    required String session,
    required String intensity,
  }) =>
      _Msg._(
        kind: _Kind.receipt,
        title: title,
        session: session,
        intensity: intensity,
      );

  final _Kind kind;
  final String body;
  final String title;
  final String session;
  final String intensity;
}

class _ChipAction {
  const _ChipAction({
    required this.label,
    required this.reply,
    required this.receiptTitle,
    required this.session,
    required this.intensity,
  });

  final String label;
  final String reply;
  final String receiptTitle;
  final String session;
  final String intensity;

  static const all = [
    _ChipAction(
      label: 'Tired',
      reply:
      'We keep the session. Load drops one notch so the habit stays without borrowing from tomorrow.',
      receiptTitle: 'Load reduced for today',
      session: 'Shortened to 20 min',
      intensity: 'Dropped one notch',
    ),
    _ChipAction(
      label: 'Travel',
      reply:
      'Travel mode on. Bodyweight only. Dinner becomes eating-out guidance, not a kitchen plate.',
      receiptTitle: 'Travel mode on',
      session: 'Bodyweight, 25 min',
      intensity: 'Eating-out guidance',
    ),
    _ChipAction(
      label: 'Pain',
      reply:
      'Pain noted with surgery-prep. Lower-body loading comes off. Stop anything that reproduces the pain.',
      receiptTitle: 'Training adjusted',
      session: 'Upper body + easy walk',
      intensity: 'Surgery-prep + pain noted',
    ),
    _ChipAction(
      label: 'Missed',
      reply:
      'Absorbed. Thursday takes a shorter version. No make-up pile, no shame copy.',
      receiptTitle: 'Missed session absorbed',
      session: 'Thursday shortened',
      intensity: 'Week still intact',
    ),
  ];
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -20, right: -40, child: _Blob(Color(0xFFB7D4C8), 220)),
          Positioned(top: 280, left: -80, child: _Blob(Color(0xFFE8D7B8), 200)),
          Positioned(bottom: 120, right: -30, child: _Blob(Color(0xFFD7E6DF), 180)),
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
        color: color.withOpacity(0.5),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(14),
    this.mint = false,
    this.teal = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool mint;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final colors = teal
        ? [_teal.withOpacity(0.92), _teal.withOpacity(0.78)]
        : mint
        ? [
      const Color(0xFFDCEDE4).withOpacity(0.78),
      Colors.white.withOpacity(0.32),
    ]
        : [
      Colors.white.withOpacity(0.6),
      Colors.white.withOpacity(0.24),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: teal ? _teal.withOpacity(0.2) : Colors.white.withOpacity(0.72),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    if (msg.kind == _Kind.receipt) {
      return _Glass(
        mint: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECEIPT',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            _kv('Session', msg.session),
            const Divider(color: Color(0x66E3E8E3), height: 16),
            _kv('Intensity', msg.intensity),
          ],
        ),
      );
    }

    final mine = msg.kind == _Kind.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: _Glass(
          teal: mine,
          radius: mine ? 22 : 24,
          child: Text(
            msg.body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: mine ? Colors.white : _ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Text(
          k.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
    );
  }
}

class _GlassComposer extends StatelessWidget {
  const _GlassComposer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: _teal,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 15,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Tell the coach what changed…',
                hintStyle: TextStyle(color: _muted, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}