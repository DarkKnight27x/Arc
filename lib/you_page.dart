import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        final dark = mode == ThemeMode.dark;
        final page = dark ? const Color(0xFF0E0E10) : const Color(0xFFF4F1EA);
        final ink = dark ? const Color(0xFFF5F5F6) : const Color(0xFF161616);
        final muted = dark ? const Color(0xFF8B8B93) : const Color(0xFF6E6A62);
        final line = dark ? const Color(0xFF2A2A2E) : const Color(0xFFD9D3C7);
        final chip = dark ? const Color(0xFF17171A) : const Color(0xFFECE7DC);

        return ColoredBox(
          color: page,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 36),
              children: [
                Row(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                      child: const ArcLogo(),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleTheme,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: line),
                        ),
                        child: Text(
                          dark ? 'Dark' : 'Light',
                          style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('YOU', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Saarthak.', style: TextStyle(fontSize: 36, height: 1.02, fontWeight: FontWeight.w500, color: ink)),
                const SizedBox(height: 8),
                Text('Build muscle · intermediate', style: TextStyle(color: muted, fontSize: 15)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _tab(ink, muted, 'Brief', 0),
                    const SizedBox(width: 18),
                    _tab(ink, muted, 'Body', 1),
                  ],
                ),
                if (tab == 0) _brief(page, ink, muted, line) else _body(chip, line, muted),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tab(Color ink, Color muted, String label, int i) {
    final on = tab == i;
    return GestureDetector(
      onTap: () => setState(() => tab = i),
      child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: on ? ink : muted)),
    );
  }

  Widget _brief(Color page, Color ink, Color muted, Color line) {
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
            color: page,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ink),
          ),
          child: Column(
            children: [for (final row in rows) _row(ink, muted, line, row.$1, row.$2)],
          ),
        ),
        const SizedBox(height: 18),
        Text('NOTE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Regular. Travelling this week.', style: TextStyle(color: ink, fontSize: 16)),
      ],
    );
  }

  Widget _row(Color ink, Color muted, Color line, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 15)),
          const Spacer(),
          Text(value, style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _body(Color chip, Color line, Color muted) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chip,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: Text('Body map', style: TextStyle(color: muted, fontSize: 15)),
    );
  }
}