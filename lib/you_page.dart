import 'package:flutter/material.dart';

import 'theme_ctrl.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  int tab = 0;

  void _toggleTheme() {
    final dark = themeCtrl.value == ThemeMode.dark;
    themeCtrl.value = dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return ColoredBox(
      color: c.page,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 36),
          children: [
            Row(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                  child: const ArcLogo(),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleTheme,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line),
                    ),
                    child: Text(
                      themeCtrl.value == ThemeMode.dark ? 'Dark' : 'Light',
                      style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('YOU', style: TextStyle(color: c.muted, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Saarthak.', style: TextStyle(fontSize: 36, height: 1.02, fontWeight: FontWeight.w500, color: c.ink)),
            const SizedBox(height: 8),
            Text('Build muscle · intermediate', style: TextStyle(color: c.muted, fontSize: 15)),
            const SizedBox(height: 22),
            Row(
              children: [
                _tab(c, 'Brief', 0),
                const SizedBox(width: 18),
                _tab(c, 'Body', 1),
              ],
            ),
            const SizedBox(height: 22),
            if (tab == 0) _brief(c) else _body(c),
          ],
        ),
      ),
    );
  }

  Widget _tab(ArcColors c, String label, int i) {
    final on = tab == i;
    return GestureDetector(
      onTap: () => setState(() => tab = i),
      child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: on ? c.ink : c.muted)),
    );
  }

  Widget _brief(ArcColors c) {
    const rows = [
      ('Goal', 'Build muscle'),
      ('Experience', 'Intermediate'),
      ('Location', 'Gym'),
      ('Diet', 'Nonveg'),
      ('Height', '178 cm'),
      ('Weight', '76 kg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          decoration: BoxDecoration(
            color: c.page,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.ink),
          ),
          child: Column(
            children: [for (final row in rows) _row(c, row.$1, row.$2)],
          ),
        ),
        const SizedBox(height: 18),
        Text('NOTE', style: TextStyle(color: c.muted, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Regular. Travelling this week.', style: TextStyle(color: c.ink, fontSize: 16)),
      ],
    );
  }

  Widget _row(ArcColors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: c.muted, fontSize: 15)),
          const Spacer(),
          Text(value, style: TextStyle(color: c.ink, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _body(ArcColors c) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Text('Body map', style: TextStyle(color: c.muted, fontSize: 15)),
    );
  }
}
