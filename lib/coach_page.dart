import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arc_theme.dart';

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
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Morning'
        : hour < 17
        ? 'Afternoon'
        : 'Evening';

    _msgs = [
      _Msg.coach(
        '$greet, Saarthak. Surgery-prep is on and energy looks low. Tell me what changed — I’ll move the plan, not just talk.',
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

  List<BoxShadow> _neu(bool dark) => [
    BoxShadow(
      color: dark ? Colors.black.withOpacity(0.5) : const Color(0xFFC8D0DC),
      offset: const Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: dark ? Colors.white.withOpacity(0.07) : Colors.white,
      offset: const Offset(-3, -3),
      blurRadius: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF141A24) : const Color(0xFFF4F6FA);

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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coach', style: text.headlineLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Tell it what changed. Today and Train will move.',
                          style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final a in _ChipAction.all) ...[
                                GestureDetector(
                                  onTap: () => _sendChip(a),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: fill,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: _neu(dark),
                                    ),
                                    child: Text(
                                      a.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                          decoration: BoxDecoration(
                            color: fill,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: _neu(dark),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  cursorColor: p.accent,
                                  minLines: 1,
                                  maxLines: 4,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: p.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tell the coach what changed…',
                                    hintStyle: TextStyle(color: p.muted),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                  onSubmitted: (_) => _sendText(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _sendText,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: p.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: p.onAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF141A24) : const Color(0xFFF4F6FA);

    if (msg.kind == _Kind.receipt) {
      return ArcCard(
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECEIPT',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 10),
            _kv(p, 'Session', msg.session),
            Divider(color: p.line, height: 16),
            _kv(p, 'Intensity', msg.intensity),
          ],
        ),
      );
    }

    final mine = msg.kind == _Kind.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? p.accent : fill,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: dark ? Colors.black.withOpacity(0.5) : const Color(0xFFC8D0DC),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
              if (!mine)
                BoxShadow(
                  color: dark ? Colors.white.withOpacity(0.07) : Colors.white,
                  offset: const Offset(-3, -3),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Text(
            msg.body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: mine ? p.onAccent : p.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(ArcPalette p, String k, String v) {
    return Row(
      children: [
        Text(
          k.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            color: p.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
  }
}