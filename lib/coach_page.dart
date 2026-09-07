import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  int tab = 0; // 0 recover  1 rehab  2 physio
  final search = TextEditingController();

  static const physios = [
    ('Motion Lab Physio', 'Thane West · 1.2 km', 'Sports + shoulder'),
    ('Restore Clinic', 'Naupada · 2.1 km', 'Post-op + strength'),
    ('Hiranandani Physio', 'Powai · 6.4 km', 'Knee + spine'),
    ('Bandra Sports PT', 'Bandra W · 18 km', 'Lifters + return to gym'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const ArcLogo(),
                const SizedBox(height: 16),
                Text('RECOVER',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: c.faint,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('A little more margin.',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: c.ink)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Seg('Signal', tab == 0, c, () => setState(() => tab = 0)),
                    const SizedBox(width: 8),
                    _Seg('Rehab', tab == 1, c, () => setState(() => tab = 1)),
                    const SizedBox(width: 8),
                    _Seg('Physio', tab == 2, c, () => setState(() => tab = 2)),
                  ],
                ),
                const SizedBox(height: 16),
                if (tab == 0) _signal(c),
                if (tab == 1) _rehab(c),
                if (tab == 2) _physio(c, list),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _signal(ArcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('READINESS',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1.0, color: c.faint)),
              Text('7.4',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600, color: c.ink)),
              Text('Ready with room',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: c.ink)),
              Text('Sleep 7h 12m / 8h target',
                  style: TextStyle(fontSize: 13, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          c: c,
          child: Row(
            children: [
              Icon(Icons.self_improvement, color: c.ice),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Yoga · 20 min · shoulders + hips',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
              ),
            ],
          ),
        ),
      ],
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
        _Card(
          c: c,
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
        _Card(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What to do in the gym',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
              const SizedBox(height: 8),
              Text('• Keep pressing, drop overhead load if it pinches',
                  style: TextStyle(fontSize: 14, color: c.muted)),
              Text('• Prefer supported machines over free-weight flyes',
                  style: TextStyle(fontSize: 14, color: c.muted)),
              Text('• Stop the set if pain rises, not just fatigue',
                  style: TextStyle(fontSize: 14, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Card(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check-in',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
              const SizedBox(height: 8),
              Text('Same / better / worse than last session?',
                  style: TextStyle(fontSize: 14, color: c.muted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _Chip(c, 'Better'),
                  _Chip(c, 'Same'),
                  _Chip(c, 'Worse'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => setState(() => tab = 2),
            style: FilledButton.styleFrom(
              backgroundColor: c.cta,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Find a physiotherapist',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
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
        Text('Thane / Mumbai · listings will later come from bookings.',
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
              borderSide: BorderSide(color: c.cta),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Card(
              c: c,
              child: Row(
                children: [
                  Icon(Icons.favorite_border, color: c.ice),
                  const SizedBox(width: 12),
                  Expanded(
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
                  Icon(Icons.chevron_right, color: c.faint),
                ],
              ),
            ),
          ),
        if (list.isEmpty)
          Text('No match. Try “Thane” or “shoulder”.',
              style: TextStyle(color: c.muted)),
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
      child: GestureDetector(
        onTap: tap,
        child: Container(
          height: 40,
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
      ),
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

class _Chip extends StatelessWidget {
  const _Chip(this.c, this.label);
  final ArcColors c;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Text(label, style: TextStyle(color: c.ink, fontWeight: FontWeight.w600)),
    );
  }
}