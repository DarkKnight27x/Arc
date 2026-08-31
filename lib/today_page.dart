import 'package:flutter/material.dart';

import 'arc_theme.dart';
import 'rehab_sheet.dart';
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final hour = now.hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final dateLabel =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

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
                  Row(
                    children: [
                      Image.asset(
                        dark
                            ? 'assets/images/logo_white.png'
                            : 'assets/images/logo.png',
                        height: 40,
                        filterQuality: FilterQuality.high,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => showRehabSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: p.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_outline, size: 14, color: p.onAccent),
                              const SizedBox(width: 6),
                              Text(
                                'Rehab',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.onAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: 'Lose fat', bg: p.chip, fg: p.chipInk),
                      _Chip(
                        label: 'Surgery-prep caution',
                        bg: p.chip,
                        fg: p.chipInk,
                      ),
                      _Chip(label: 'Travel week', bg: p.sand, fg: p.sandInk),
                      _Chip(label: 'Low energy', bg: p.sand, fg: p.sandInk),
                      _Chip(
                        label: 'Regular',
                        bg: p.cardHi,
                        fg: p.accent,
                        icon: Icons.auto_awesome,
                      ),
                      _Chip(
                        label: '6-day show-up',
                        bg: p.chip,
                        fg: p.chipInk,
                        icon: Icons.ac_unit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '340 XP',
                    style: text.bodySmall?.copyWith(
                      color: p.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('$greet, Saarthak.', style: text.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    dateLabel,
                    style: text.bodyMedium?.copyWith(color: p.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  ArcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today is a controlled full-body session.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: p.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Surgery-prep context is on. We keep training, drop impact, and keep dinner simple.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ArcCard(
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
                                  color: p.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '35 min · full-body',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Home · Strength with steady breathing, no jumping',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: p.muted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: p.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ArcCard(
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
                                  color: p.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'What to eat today',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dinner: Egg bhurji + 1 roti + salad',
                                style: TextStyle(fontSize: 13, color: p.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.restaurant_outlined, color: p.muted, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ArcCard(
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
                                  color: p.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sleep 8h · keep stress flat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Readiness looks steady. A short walk after dinner helps.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: p.muted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.nightlight_outlined, color: p.muted, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ArcCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '“Tell me if anything feels off today — we can shorten it.”',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              color: p.ink,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arc follows the limits you stated. It does not manage your surgery.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 88,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_rounded, color: p.onAccent, size: 34),
                  const SizedBox(height: 4),
                  Text(
                    'Off Plan?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: p.onAccent,
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
          ),
        ],
      ),
    );
  }
}