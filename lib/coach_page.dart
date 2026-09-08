import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});
  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _Msg {
  const _Msg(this.mine, this.text);
  final bool mine;
  final String text;
}

class _CoachPageState extends State<CoachPage> {
  int tab = 0;
  final search = TextEditingController();
  final input = TextEditingController();
  final lines = <_Msg>[
    const _Msg(false,
        'Keep today’s plan steady. If something feels off, stay in the region and change the machine.\n\nARC does not diagnose injuries.'),
    const _Msg(true, 'Can you make this a shorter day?'),
    const _Msg(false,
        'Keep the first three movements and leave one set in reserve. Ten minutes is enough to stay consistent.'),
  ];

  static const physios = [
    ('Motion Lab Physio', 'Thane West · 1.2 km', 'Sports + shoulder'),
    ('Restore Clinic', 'Naupada · 2.1 km', 'Post-op + strength'),
    ('Hiranandani Physio', 'Powai · 6.4 km', 'Knee + spine'),
    ('Bandra Sports PT', 'Bandra W · 18 km', 'Lifters + return to gym'),
  ];

  @override
  void dispose() {
    search.dispose();
    input.dispose();
    super.dispose();
  }

  void _send([String? raw]) {
    final t = (raw ?? input.text).trim();
    if (t.isEmpty) return;
    input.clear();
    setState(() {
      lines.add(_Msg(true, t));
      lines.add(const _Msg(
        false,
        'Noted. Same region, different machine. Stop the set if pain rises.',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        final q = search.text.trim().toLowerCase();
        final list = physios
            .where((p) =>
        q.isEmpty ||
            p.$1.toLowerCase().contains(q) ||
            p.$2.toLowerCase().contains(q) ||
            p.$3.toLowerCase().contains(q))
            .toList();

        return ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
                      const SizedBox(height: 16),
                      Text('RECOVER  ·  LIVE CONTEXT',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.1,
                              color: c.faint,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Coach\n',
                            style: TextStyle(
                                fontSize: 36,
                                height: 1.02,
                                fontWeight: FontWeight.w500,
                                color: c.ink)),
                        TextSpan(
                            text: 'for today.',
                            style: TextStyle(
                                fontSize: 36,
                                height: 1.02,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: c.ink)),
                      ])),
                      const SizedBox(height: 6),
                      Text('Training · food · recovery',
                          style: TextStyle(fontSize: 14, color: c.muted)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: metalWell(c),
                        child: Row(
                          children: [
                            _Seg('Coach', tab == 0, c,
                                    () => setState(() => tab = 0)),
                            _Seg('Rehab', tab == 1, c,
                                    () => setState(() => tab = 1)),
                            _Seg('Physio', tab == 2, c,
                                    () => setState(() => tab = 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tab == 0) _coach(c),
                      if (tab == 1) _rehab(c),
                      if (tab == 2) _physio(c, list),
                    ],
                  ),
                ),
                if (tab == 0) _composer(c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coach(ArcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Hint(c, 'Swap this machine', () => _send('Swap this machine')),
            _Hint(c, '10-min cut', () => _send('Give me a 10-min cut')),
            _Hint(c, 'Shoulder feels off', () => _send('Shoulder feels off')),
          ],
        ),
        const SizedBox(height: 14),
        for (final m in lines) _Bubble(c: c, msg: m),
      ],
    );
  }

  Widget _composer(ArcColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: metalWell(c),
        child: Row(
          children: [
            PressScale(
              onTap: () => _send('Attached a note'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.raised,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: Icon(Icons.add, color: c.ink, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: input,
                style: TextStyle(color: c.ink),
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask anything about today…',
                  hintStyle: TextStyle(color: c.faint, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            PressScale(
              onTap: _send,
              child: Container(
                width: 36,
                height: 36,
                decoration: metalPrimary(c).copyWith(
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(Icons.arrow_forward, color: c.ctaInk, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rehab(ArcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARC screens what you report. It does not diagnose an injury.',
          style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORTED',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1.0, color: c.faint)),
              const SizedBox(height: 6),
              Text('Shoulder tightness · left',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: c.ink)),
              Text('Idle this week · no clinician note uploaded',
                  style: TextStyle(fontSize: 13, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In the gym',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
              const SizedBox(height: 8),
              Text('Keep pressing. Drop overhead if it pinches.',
                  style: TextStyle(fontSize: 14, color: c.muted)),
              Text('Prefer supported machines.',
                  style: TextStyle(fontSize: 14, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MetalBtn(
          label: 'Find a physiotherapist',
          onTap: () => setState(() => tab = 2),
        ),
      ],
    );
  }

  Widget _physio(ArcColors c, List<(String, String, String)> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search real physios near you',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 6),
        Text('Thane / Mumbai · sample until bookings are live.',
            style: TextStyle(fontSize: 13, color: c.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.ink),
          decoration: InputDecoration(
            hintText: 'Name, area, or specialty',
            hintStyle: TextStyle(color: c.faint),
            prefixIcon: Icon(Icons.search, color: c.muted),
            filled: true,
            fillColor: c.chip,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PressScale(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: metalPanel(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.$1,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                    Text(p.$2, style: TextStyle(fontSize: 13, color: c.muted)),
                    Text(p.$3, style: TextStyle(fontSize: 12, color: c.faint)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg(this.label, this.on, this.c, this.tap);
  final String label;
  final bool on;
  final ArcColors c;
  final VoidCallback tap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        onTap: tap,
        child: AnimatedContainer(
          duration: ArcMotion.base,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: on ? c.ink : c.muted)),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.c, this.label, this.onTap);
  final ArcColors c;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: metalWell(c),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: c.ink)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.c, required this.msg});
  final ArcColors c;
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: metalPanel(c),
        child: Text(msg.text,
            style: TextStyle(fontSize: 14, height: 1.4, color: c.ink)),
      ),
    );
  }
}