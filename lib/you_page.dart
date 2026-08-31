import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arc_theme.dart';
import 'body_avatar_page.dart';
import 'theme_ctrl.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  int tab = 0;
  bool identOpen = false;
  bool whyOpen = true;
  bool fitOpen = false;
  bool limitsOpen = true;
  bool lifeOpen = false;
  bool nutOpen = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your file', style: text.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Everything your coach knows. Change anything, any time.',
                          style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
                        ),
                        const SizedBox(height: 16),
                        _GlassTabs(
                          selected: tab,
                          onSelect: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => tab = i);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: tab == 0
                        ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeCtrl,
                          builder: (_, mode, __) {
                            final isDark = mode == ThemeMode.dark;
                            return ArcCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Appearance',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isDark ? 'Dark' : 'Light',
                                    style: TextStyle(fontSize: 13, color: p.muted),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch.adaptive(
                                    value: isDark,
                                    activeColor: p.accent,
                                    onChanged: (_) => toggleArcTheme(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        ArcCard(
                          child: Column(
                            children: [
                              _KV(label: 'Goal', value: 'Lose fat'),
                              Divider(color: p.line, height: 1),
                              _KV(label: 'Availability', value: '4 days · 30–45 min'),
                              Divider(color: p.line, height: 1),
                              _KV(label: 'Fitness level', value: 'Intermediate'),
                              Divider(color: p.line, height: 1),
                              _KV(
                                label: 'Nutrition',
                                value: 'Eggetarian · Just tell me what to eat',
                              ),
                              Divider(color: p.line, height: 1),
                              _KV(label: 'Recovery', value: '8h sleep · Moderate stress'),
                              Divider(color: p.line, height: 1),
                              _KV(label: 'Context', value: 'Preparing for surgery'),
                            ],
                          ),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        ArcCard(
                          child: Center(
                            child: Text(
                              '+  Change life state',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Fold(
                          label: 'Identity',
                          body: 'Saarthak · Thane · home + office training.',
                          open: identOpen,
                          onTap: () => setState(() => identOpen = !identOpen),
                        ),
                        const SizedBox(height: 10),
                        _Fold(
                          label: 'Goal + why',
                          body:
                          'Lose fat, so the surgery recovery starts from a better place.',
                          open: whyOpen,
                          onTap: () => setState(() => whyOpen = !whyOpen),
                        ),
                        const SizedBox(height: 10),
                        _Fold(
                          label: 'Fitness',
                          body:
                          '4 days · 30–45 min · Home and office · Dumbbells, bands, a bench · Enjoys strength, walking, mobility.',
                          open: fitOpen,
                          onTap: () => setState(() => fitOpen = !fitOpen),
                        ),
                        const SizedBox(height: 10),
                        _Fold(
                          label: 'Health limits',
                          body:
                          'Preparing for surgery. No jumping, no max effort, no breath-holding.',
                          open: limitsOpen,
                          onTap: () => setState(() => limitsOpen = !limitsOpen),
                        ),
                        const SizedBox(height: 10),
                        _Fold(
                          label: 'Lifestyle',
                          body:
                          'Desk job, evening training, family dinners most nights.',
                          open: lifeOpen,
                          onTap: () => setState(() => lifeOpen = !lifeOpen),
                        ),
                        const SizedBox(height: 10),
                        _Fold(
                          label: 'Nutrition',
                          body:
                          'Eggetarian · Just tell me what to eat · Home-cooked most days.',
                          open: nutOpen,
                          onTap: () => setState(() => nutOpen = !nutOpen),
                        ),
                        const SizedBox(height: 10),
                        ArcCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Rehab / surgery protocol',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              Icon(Icons.lock_outline, size: 16, color: p.muted),
                              const SizedBox(width: 6),
                              Text(
                                'Soon',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ArcCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATE TIMELINE',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _TimeDot(
                                title: 'Starting profile created',
                                when: 'Today',
                              ),
                              const SizedBox(height: 12),
                              const _TimeDot(
                                title: 'Fat-loss block began',
                                when: 'Today',
                              ),
                              const SizedBox(height: 12),
                              const _TimeDot(
                                title: 'Surgery-prep caution turned on',
                                when: 'Today',
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: _BodyViewer(),
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

class _Fold extends StatelessWidget {
  const _Fold({
    required this.label,
    required this.body,
    required this.open,
    required this.onTap,
  });

  final String label;
  final String body;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ArcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  color: p.muted,
                ),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 10),
              Text(
                body,
                style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeDot extends StatelessWidget {
  const _TimeDot({required this.title, required this.when});
  final String title;
  final String when;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(when, style: TextStyle(fontSize: 13, color: p.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyViewer extends StatelessWidget {
  const _BodyViewer();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 430,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: dark ? const Color(0xFF141A24) : const Color(0xFFF4F6FA),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.55) : const Color(0xFFC8D0DC),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: dark ? Colors.white.withOpacity(0.07) : Colors.white,
            offset: const Offset(-5, -5),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const BodyAvatar(height: 430),
    );
  }
}

class _GlassTabs extends StatelessWidget {
  const _GlassTabs({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ArcCard(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment:
              selected == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: dark ? const Color(0xFF1A2433) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: dark
                            ? Colors.black.withOpacity(0.45)
                            : const Color(0xFFC8D0DC),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: dark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.white,
                        offset: const Offset(-3, -3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _TabHit(
                  label: 'Brief',
                  selected: selected == 0,
                  onTap: () => onSelect(0),
                ),
                _TabHit(
                  label: 'Body',
                  selected: selected == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabHit extends StatelessWidget {
  const _TabHit({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? p.accent : p.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
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
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.45) : const Color(0xFFC8D0DC),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: dark ? Colors.white.withOpacity(0.06) : Colors.white,
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}