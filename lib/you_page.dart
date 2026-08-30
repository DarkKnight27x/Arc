import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
const _page = Color(0xFFF3F6F1);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);
const _coolBg = Color(0xFFE7EEF2);
const _coolInk = Color(0xFF3D5A66);
const _sand = Color(0xFFF3E6D4);
const _sandInk = Color(0xFF8A5A28);

class ArcLogo extends StatelessWidget {
  const ArcLogo({super.key, this.height = 28});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      filterQuality: FilterQuality.high,
    );
  }
}
class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  int tab = 0;
  bool whyOpen = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: _page,
      child: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your file', style: text.headlineLarge),
                      const SizedBox(height: 8),
                      const Text(
                        'Everything your coach knows. Change anything, any time.',
                        style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      const _Glass(
                        child: Column(
                          children: [
                            _KV(label: 'Goal', value: 'Lose fat'),
                            Divider(color: Color(0x66E3E8E3), height: 1),
                            _KV(
                              label: 'Availability',
                              value: '4 days · 30–45 min',
                            ),
                            Divider(color: Color(0x66E3E8E3), height: 1),
                            _KV(label: 'Fitness level', value: 'Intermediate'),
                            Divider(color: Color(0x66E3E8E3), height: 1),
                            _KV(
                              label: 'Nutrition',
                              value: 'Eggetarian · Just tell me what to eat',
                            ),
                            Divider(color: Color(0x66E3E8E3), height: 1),
                            _KV(
                              label: 'Recovery',
                              value: '8h sleep · Moderate stress',
                            ),
                            Divider(color: Color(0x66E3E8E3), height: 1),
                            _KV(label: 'Context', value: 'Preparing for surgery'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(label: 'Lose fat', cool: true),
                          _Chip(label: 'Surgery-prep caution', cool: true),
                          _Chip(label: 'Travel week', sand: true),
                          _Chip(label: 'Low energy', sand: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _GhostButton(label: '+  Change life state'),
                      const SizedBox(height: 12),
                      const _RowCard(
                        title: 'Identity',
                        trailing: Icons.chevron_right,
                      ),
                      const SizedBox(height: 10),
                      _WhyCard(
                        open: whyOpen,
                        onTap: () => setState(() => whyOpen = !whyOpen),
                      ),
                    ],
                  )
                      : const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _BodyViewer(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _BodyViewer extends StatelessWidget {
  const _BodyViewer();

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------------------------
    // TODO(3D) — add the body model here
    //
    // Do not edit the Brief tab. This widget is the Body tab.
    // Package:
    //   flutter pub add model_viewer_plus
    //
    // Behaviour to build:
    //   - drag to rotate the mannequin
    //   - pinch to zoom
    //   - mark injured regions (hip, knee, shoulder…) in red
    //   - Android needs usesCleartextTraffic="true" on <application>
    //     and INTERNET permission as a sibling of <application>, not inside it
    //   - never put ModelViewer inside a ListView (it hangs on emulator)
    //
    // Swap this empty box for the viewer when the GLB is ready.
    // ---------------------------------------------------------------------------
    return const SizedBox.expand();
  }
}
class _GlassTabs extends StatelessWidget {
  const _GlassTabs({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Glass(
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
                    color: Colors.white.withOpacity(0.72),
                    border: Border.all(color: Colors.white.withOpacity(0.9)),
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
              color: selected ? _teal : _muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Goal + why',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  color: _muted,
                ),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 10),
              const Text(
                'Lose fat, so the surgery recovery starts from a better place.',
                style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.title, required this.trailing});
  final String title;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          Icon(trailing, color: _muted),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.cool = false, this.sand = false});
  final String label;
  final bool cool;
  final bool sand;

  @override
  Widget build(BuildContext context) {
    final bg = sand ? _sand : _coolBg;
    final fg = sand ? _sandInk : _coolInk;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -30, right: -50, child: _Blob(Color(0xFFB7D4C8), 210)),
          Positioned(top: 240, left: -70, child: _Blob(Color(0xFFE8D7B8), 200)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.58),
                Colors.white.withOpacity(0.24),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}