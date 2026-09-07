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
  @override
  Widget build(BuildContext context) {
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
                _Bar(c: c),
                const SizedBox(height: 18),
                Text(
                  'YOU  ·  YOUR OPERATING CONTEXT',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: c.faint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep it yours',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.08,
                    color: c.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                    const SizedBox(width: 8),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.c});
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    final dark = themeCtrl.value == ThemeMode.dark;
    return Row(
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
        const Spacer(),
        GestureDetector(
          onTap: toggleArcTheme,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.chip,
              shape: BoxShape.circle,
              border: Border.all(color: c.line),
            ),
            child: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 16,
              color: c.muted,
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
    return GestureDetector(
      onTap: tap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.chip,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? c.cta : c.line),
        ),
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
        _Box(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAARTHAK  ·  THANE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: c.faint,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The useful brief',
                style: TextStyle(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 14),
              _KV('Age band', '25–34', c),
              _KV('Training', 'Recreational lifter', c),
              _KV('Goal', 'Lose fat', c),
              _KV('XP / streak', '340  ·  6 days', c),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Life state',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 8),
        _Box(
          c: c,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT NOTE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: c.faint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Regular, travelling this week',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.faint),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 8),
        _Box(
          c: c,
          child: Column(
            children: [
              _KV('Gym', 'Cult Fit Thane', c),
              _KV('Food', 'Eggetarian · ₹250/day', c),
              _KV('Sleep', 'Target 8 hours', c),
              _KV('Plan', 'PPL · Intermediate', c),
            ],
          ),
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
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: const BodyAvatar(height: 430),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.c, required this.child});
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

class _KV extends StatelessWidget {
  const _KV(this.k, this.v, this.c);
  final String k;
  final String v;
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(k, style: TextStyle(fontSize: 14, color: c.muted)),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}