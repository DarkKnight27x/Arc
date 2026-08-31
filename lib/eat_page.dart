import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arc_theme.dart';

class EatPage extends StatefulWidget {
  const EatPage({super.key});

  @override
  State<EatPage> createState() => _EatPageState();
}

class _EatPageState extends State<EatPage> {
  static const _meals = [
    _Meal(
      slot: 'BREAKFAST',
      plate: '2 idli + sambar + 1 boiled egg',
      note: 'Add a spoon of coconut chutney if you want. Eat slowly.',
      cue: 'Protein first, then the carb.',
      tags: ['idli', 'sambar', 'egg', 'breakfast'],
    ),
    _Meal(
      slot: 'LUNCH',
      plate: '2 roti + dal + sabzi + curd',
      note: 'Fill half the plate with the sabzi. One roti less than usual is enough.',
      cue: '',
      tags: ['roti', 'dal', 'sabzi', 'curd', 'lunch'],
    ),
    _Meal(
      slot: 'DINNER',
      plate: 'Egg bhurji + 1 roti + salad',
      note: 'Keep it simple tonight — you train in the evening.',
      cue: 'Light dinner suits surgery-prep weeks.',
      featured: true,
      tags: ['egg', 'bhurji', 'roti', 'salad', 'dinner'],
    ),
  ];

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = ArcPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? _meals
        : _meals
        .where(
          (m) =>
      m.plate.toLowerCase().contains(q) ||
          m.slot.toLowerCase().contains(q) ||
          m.tags.any((t) => t.contains(q)),
    )
        .toList();

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                children: [
                  Text('What to eat today', style: text.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Eggetarian, everyday plates. Nothing to weigh.',
                    style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: 'Eggetarian', bg: p.chip, fg: p.chipInk),
                      _Chip(label: 'Budget ₹', bg: p.chip, fg: p.chipInk),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (shown.isEmpty)
                    ArcCard(
                      child: Text(
                        'Nothing matches that. Try “idli”, “dal”, or “egg”.',
                        style: TextStyle(fontSize: 14, color: p.muted, height: 1.4),
                      ),
                    )
                  else
                    for (final m in shown) ...[
                      ArcCard(
                        selected: m.featured,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.slot,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w600,
                                color: p.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m.plate,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m.note,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: p.muted,
                              ),
                            ),
                            if (m.cue.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                m.cue,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 4),
                  Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: dark
                              ? Colors.black.withOpacity(0.45)
                              : const Color(0xFFC8D0DC),
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      'What should I eat now?',
                      style: TextStyle(
                        color: p.onAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ArcCard(
                          child: Center(
                            child: Text(
                              'Log a meal',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ArcCard(
                          child: Center(
                            child: Text(
                              'Cook brief',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _Meal {
  const _Meal({
    required this.slot,
    required this.plate,
    required this.note,
    required this.cue,
    required this.tags,
    this.featured = false,
  });
  final String slot;
  final String plate;
  final String note;
  final String cue;
  final List<String> tags;
  final bool featured;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return ArcCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: p.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                cursorColor: p.accent,
                style: TextStyle(
                  fontSize: 15,
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search idli, dal, egg…',
                  hintStyle: TextStyle(
                    color: p.muted,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                  HapticFeedback.selectionClick();
                },
                child: Icon(Icons.close_rounded, size: 18, color: p.muted),
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