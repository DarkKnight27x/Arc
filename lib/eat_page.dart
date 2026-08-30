import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _page = Color(0xFFF3F6F1);
const _teal = Color(0xFF0E5C4B);
const _ink = Color(0xFF1A1F1C);
const _muted = Color(0xFF6B746E);
const _coolBg = Color(0xFFE7EEF2);
const _coolInk = Color(0xFF3D5A66);

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

    return ColoredBox(
      color: _page,
      child: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text('What to eat today', style: text.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  'Eggetarian, everyday plates. Nothing to weigh.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
                ),
                const SizedBox(height: 16),
                _GlassSearchBar(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'Eggetarian'),
                    _Chip(label: 'Budget ₹'),
                  ],
                ),
                const SizedBox(height: 18),
                if (shown.isEmpty)
                  const _GlassEmpty()
                else
                  for (var i = 0; i < shown.length; i++) ...[
                    _GlassMealCard(meal: shown[i]),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 4),
                const _PrimaryGlassButton(label: 'What should I eat now?'),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: _GhostGlassButton(label: 'Log a meal')),
                    SizedBox(width: 10),
                    Expanded(child: _GhostGlassButton(label: 'Cook brief')),
                  ],
                ),
              ],
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

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -30, left: -50, child: _Blob(Color(0xFFE8D7B8), 210)),
          Positioned(top: 180, right: -70, child: _Blob(Color(0xFFB7D4C8), 230)),
          Positioned(bottom: 40, left: -30, child: _Blob(Color(0xFFD7E6DF), 190)),
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
        color: color.withOpacity(0.55),
      ),
    );
  }
}

class _GlassSearchBar extends StatelessWidget {
  const _GlassSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.28),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.78)),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: _teal.withOpacity(0.9), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  cursorColor: _teal,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _ink,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search idli, dal, egg…',
                    hintStyle: TextStyle(
                      color: _muted,
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
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _muted.withOpacity(0.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.emphasized = false,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final bool emphasized;
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
              colors: emphasized
                  ? [
                const Color(0xFFDCEDE4).withOpacity(0.74),
                Colors.white.withOpacity(0.34),
              ]
                  : [
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

class _GlassMealCard extends StatelessWidget {
  const _GlassMealCard({required this.meal});
  final _Meal meal;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      emphasized: meal.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.slot,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meal.plate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meal.note,
            style: const TextStyle(fontSize: 13.5, height: 1.4, color: _muted),
          ),
          if (meal.cue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meal.cue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _teal.withOpacity(0.95),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassEmpty extends StatelessWidget {
  const _GlassEmpty();

  @override
  Widget build(BuildContext context) {
    return const _GlassPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nothing matches that. Try “idli”, “dal”, or “egg”.',
          style: TextStyle(fontSize: 14, color: _muted, height: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryGlassButton extends StatelessWidget {
  const _PrimaryGlassButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _GhostGlassButton extends StatelessWidget {
  const _GhostGlassButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.42),
            border: Border.all(color: Colors.white.withOpacity(0.75)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _coolBg.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _coolInk,
            ),
          ),
        ),
      ),
    );
  }
}