import 'package:flutter/material.dart';
import 'train_page.dart';

const _page = Color(0xFFF3F6F1);
const _card = Color(0xFFFFFFFF);
const _mint = Color(0xFFDCEDE4);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);
const _line = Color(0xFFE3E8E3);
const _coolBg = Color(0xFFE7EEF2);
const _coolInk = Color(0xFF3D5A66);

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: _page,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text('Your week', style: text.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Four sessions. Impact stays off while surgery-prep is on.',
              style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: 'Lose fat', bg: _coolBg, fg: _coolInk),
                _Chip(label: 'Surgery-prep caution', bg: _coolBg, fg: _coolInk),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Day(letter: 'M', active: true),
                _Day(letter: 'T', active: false),
                _Day(letter: 'W', active: true),
                _Day(letter: 'T', active: false),
                _Day(letter: 'F', active: true),
                _Day(letter: 'S', active: true, today: true),
                _Day(letter: 'S', active: false),
              ],
            ),
            const SizedBox(height: 18),
            const _SessionCard(
              selected: true,
              eyebrow: 'TODAY',
              title: '35 min · full-body',
              meta: 'Home · Strength, steady breathing, no jumping',
              showPlay: true,
            ),
            const SizedBox(height: 12),
            const _SessionCard(
              eyebrow: 'MON',
              title: '30 min · push + core',
              meta: 'Home · No floor impact',
            ),
            const SizedBox(height: 12),
            const _SessionCard(
              eyebrow: 'WED',
              title: '40 min · lower + walk',
              meta: 'Home · Controlled tempo',
            ),
            const SizedBox(height: 12),
            const _SessionCard(
              eyebrow: 'FRI',
              title: '30 min · pull + mobility',
              meta: 'Home · Easy on the joints',
            ),
            const SizedBox(height: 16),
            const Text(
              'Coaching, not a clinician. Stop any movement that hurts.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: _muted),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.letter,
    required this.active,
    this.today = false,
  });
  final String letter;
  final bool active;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: today ? _teal : (active ? _mint : Colors.transparent),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: today ? Colors.white : (active ? _teal : _muted),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.eyebrow,
    required this.title,
    required this.meta,
    this.selected = false,
    this.showPlay = false,
  });

  final String eyebrow;
  final String title;
  final String meta;
  final bool selected;
  final bool showPlay;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 13, color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (showPlay)
            const SizedBox(
              width: 40,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}