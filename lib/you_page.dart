import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'body_avatar_page.dart';
import 'theme_ctrl.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        final c = ArcColors.of(context);
        final dark = mode == ThemeMode.dark;
        return ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                Row(
                  children: [
                    Text(
                      'YOU  ·  YOUR OPERATING CONTEXT',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: c.faint,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: toggleArcTheme,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
                        decoration: BoxDecoration(
                          color: c.chip,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          children: [
                            Text(
                              dark ? 'Dark metal' : 'Champagne',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: c.ink.withValues(alpha: 0.65)),
                                gradient: const RadialGradient(
                                  center: Alignment(-0.4, -0.5),
                                  colors: [
                                    Color(0xFFF2F5F8),
                                    Color(0xFF8A939C),
                                    Color(0xFF2A2E33),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Keep it ',
                        style: TextStyle(
                          fontSize: 40,
                          height: 1.02,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      TextSpan(
                        text: 'yours.',
                        style: TextStyle(
                          fontSize: 40,
                          height: 1.02,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: metalWell(c),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Seg(
                          'Brief',
                          tab == 0,
                          c,
                              () {
                            HapticFeedback.selectionClick();
                            setState(() => tab = 0);
                          },
                        ),
                      ),
                      Expanded(
                        child: _Seg(
                          'Body',
                          tab == 1,
                          c,
                              () {
                            HapticFeedback.selectionClick();
                            setState(() => tab = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (tab == 0) _Brief(c: c) else _Body(c: c),
              ],
            ),
          ),
        );
      },
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
    return GestureDetector(
      onTap: tap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: on
            ? BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.line),
        )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: on ? c.ink : c.muted,
          ),
        ),
      ),
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({required this.c});
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: metalPanel(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'SAARTHAK  ·  THANE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      color: c.faint,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.chip,
                      border: Border.all(color: c.line),
                    ),
                    child: Icon(Icons.person_outline, size: 16, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The useful brief',
                style: TextStyle(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 14),
              _KV(c, 'Age band', '25–34'),
              _KV(c, 'Training', 'Recreational lifter'),
              _KV(c, 'Goal', 'Lose fat'),
              _KV(c, 'XP / streak', '340  ·  6 days'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Life state',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT NOTE',
                        style: TextStyle(
                            fontSize: 11, letterSpacing: 1.0, color: c.faint)),
                    const SizedBox(height: 4),
                    Text('Regular, travelling this week',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.faint),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Preferences',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: metalPanel(c),
          child: Column(
            children: [
              _KV(c, 'Gym', 'Cult Fit Thane', line: false),
              _KV(c, 'Food', 'Eggetarian · ₹250/day'),
              _KV(c, 'Sleep', 'Target 8 hours'),
              _KV(c, 'Plan', 'PPL · Intermediate'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Life folds',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 8),
        _Fold(c, 'Travel week', 'Active', ok: true),
        const SizedBox(height: 8),
        _Fold(c, 'Injury / rehab', 'Soon'),
        const SizedBox(height: 8),
        _Fold(c, 'Surgery recovery', 'Soon'),
        const SizedBox(height: 16),
        MetalBtn(
          label: 'Open body view  →',
          onTap: () {},
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.c});
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: metalPanel(c),
      clipBehavior: Clip.antiAlias,
      child: const BodyAvatar(height: 430),
    );
  }
}

class _Fold extends StatelessWidget {
  const _Fold(this.c, this.title, this.tag, {this.ok = false});
  final ArcColors c;
  final String title;
  final String tag;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: metalPanel(c),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                if (ok)
                  Text('Active',
                      style: TextStyle(fontSize: 13, color: c.ok)),
              ],
            ),
          ),
          if (ok)
            Icon(Icons.check, color: c.ok, size: 18)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.chip,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.line),
              ),
              child: Text(tag,
                  style: TextStyle(fontSize: 12, color: c.muted)),
            ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.c, this.k, this.v, {this.line = true});
  final ArcColors c;
  final String k, v;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: line
          ? BoxDecoration(
        border: Border(top: BorderSide(color: c.line.withValues(alpha: 0.6))),
      )
          : null,
      child: Row(
        children: [
          Text(k, style: TextStyle(fontSize: 14, color: c.muted)),
          const Spacer(),
          Text(v,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
        ],
      ),
    );
  }
}