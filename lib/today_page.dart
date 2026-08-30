import 'package:flutter/material.dart';

const _page = Color(0xFFF3F6F1);
const _card = Color(0xFFFFFFFF);
const _mint = Color(0xFFDCEDE4);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);
const _line = Color(0xFFE3E8E3);
const _coolBg = Color(0xFFE7EEF2);
const _coolInk = Color(0xFF3D5A66);
const _sandBg = Color(0xFFF3E6D4);
const _sandInk = Color(0xFF8A5A28);
const _greenChip = Color(0xFFDCEDE4);

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: _page,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  filterQuality: FilterQuality.high,
                ),
                const Spacer(),
                Text(
                  'Coach',
                  style: text.bodySmall?.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: 'Lose fat', bg: _coolBg, fg: _coolInk),
                _Chip(label: 'Surgery-prep caution', bg: _coolBg, fg: _coolInk),
                _Chip(label: 'Travel week', bg: _sandBg, fg: _sandInk),
                _Chip(label: 'Low energy', bg: _sandBg, fg: _sandInk),
                _Chip(
                  label: 'Regular',
                  bg: _greenChip,
                  fg: _teal,
                  icon: Icons.auto_awesome,
                ),
                _Chip(
                  label: '6-day show-up',
                  bg: _coolBg,
                  fg: _coolInk,
                  icon: Icons.ac_unit,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '340 XP',
              style: text.bodySmall?.copyWith(
                color: _muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Text('Good morning, Saarthak.', style: text.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Saturday, August 29',
              style: text.bodyMedium?.copyWith(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            const _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today is a controlled full-body session.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Surgery-prep context is on. We keep training, drop impact, and keep dinner simple.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Card(
              selected: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAIN',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '35 min · full-body',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Home · Strength with steady breathing, no jumping',
                          style: TextStyle(
                            fontSize: 13,
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EAT',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'What to eat today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dinner: Egg bhurji + 1 roti + salad',
                          style: TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.restaurant_outlined, color: _muted, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECOVER',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sleep 8h · keep stress flat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Readiness looks steady. A short walk after dinner helps.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.nightlight_outlined, color: _muted, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '“Tell me if anything feels off today — we can shorten it.”',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: _ink,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: _muted),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Arc follows the limits you stated. It does not manage your surgery.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.selected = false});

  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? _mint : _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? Colors.transparent : _line),
      ),
      child: child,
    );
  }
}