import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_ctrl.dart';
import 'data/enums.dart';
import 'data/meal_service.dart';
import 'data/models/meal.dart';
import 'data/models/meal_nutrition.dart';
import 'features/eat/eat_setup_page.dart';
import 'features/eat/meal_detail_page.dart';

class EatPage extends StatefulWidget {
  const EatPage({super.key});
  @override
  State<EatPage> createState() => _EatPageState();
}

class _EatPageState extends State<EatPage> {
  final search = TextEditingController();
  late final MealService _meals = MealService(Supabase.instance.client);
  late Future<List<MealNutrition>> _catalog;
  MealType? _type;
  String? _diet; // veg | egg | nonveg

  @override
  void initState() {
    super.initState();
    _catalog = _meals.listCatalog();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String get _weekday {
    const names = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return names[DateTime.now().weekday - 1];
  }

  List<MealNutrition> _filter(List<MealNutrition> all) {
    final q = search.text.trim().toLowerCase();
    return all.where((m) {
      if (_type != null && m.mealType != _type) return false;
      if (_diet != null) {
        final tags = m.dietaryTags.map((e) => e.toLowerCase()).toList();
        if (_diet == 'nonveg') {
          if (!tags.contains('nonveg')) return false;
        } else if (!tags.contains(_diet)) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.mealType.name.toLowerCase().contains(q) ||
          m.dietaryTags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _open(MealNutrition item) async {
    final detail = await _meals.fetchDetail(item.mealId);
    if (!mounted || detail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealDetailPage(
          detail: detail,
          imageUrl: _meals.imageUrl(detail.meal.imagePath),
        ),
      ),
    );
  }

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
            child: FutureBuilder<List<MealNutrition>>(
              future: _catalog,
              builder: (context, snap) {
                final all = snap.data ?? [];
                final list = _filter(all);
                int n(MealType t) =>
                    all.where((m) => m.mealType == t).length;
                String? thumb(MealType t) {
                  final hit = all.where((m) => m.mealType == t);
                  if (hit.isEmpty) return null;
                  return _meals.imageUrl(hit.first.imagePath);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    Row(
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
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'EAT  ·  $_weekday',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: c.faint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Feed the training',
                            style: TextStyle(
                              fontSize: 36,
                              height: 1.02,
                              color: c.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Indian plates, a clear budget, no calorie theatre.',
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: c.ink),
                      decoration: InputDecoration(
                        hintText: 'Search plates, dal, eggs…',
                        hintStyle: TextStyle(color: c.faint),
                        prefixIcon: Icon(Icons.search, color: c.muted),
                        filled: true,
                        fillColor: c.chip,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: c.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: c.cta),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeCard(
                            c: c,
                            label: 'BREAKFAST',
                            count: n(MealType.breakfast),
                            imageUrl: thumb(MealType.breakfast),
                            selected: _type == MealType.breakfast,
                            onTap: () => setState(() {
                              _type = _type == MealType.breakfast
                                  ? null
                                  : MealType.breakfast;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeCard(
                            c: c,
                            label: 'LUNCH',
                            count: n(MealType.lunch),
                            imageUrl: thumb(MealType.lunch),
                            selected: _type == MealType.lunch,
                            onTap: () => setState(() {
                              _type = _type == MealType.lunch
                                  ? null
                                  : MealType.lunch;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeCard(
                            c: c,
                            label: 'SNACKS',
                            count: n(MealType.snack),
                            imageUrl: thumb(MealType.snack),
                            selected: _type == MealType.snack,
                            onTap: () => setState(() {
                              _type = _type == MealType.snack
                                  ? null
                                  : MealType.snack;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeCard(
                            c: c,
                            label: 'DINNER',
                            count: n(MealType.dinner),
                            imageUrl: thumb(MealType.dinner),
                            selected: _type == MealType.dinner,
                            onTap: () => setState(() {
                              _type = _type == MealType.dinner
                                  ? null
                                  : MealType.dinner;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Chip(
                            c: c,
                            label: 'All',
                            on: _type == null && _diet == null,
                            onTap: () => setState(() {
                              _type = null;
                              _diet = null;
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Breakfast',
                            on: _type == MealType.breakfast,
                            onTap: () => setState(() {
                              _type = MealType.breakfast;
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Lunch',
                            on: _type == MealType.lunch,
                            onTap: () => setState(() {
                              _type = MealType.lunch;
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Dinner',
                            on: _type == MealType.dinner,
                            onTap: () => setState(() {
                              _type = MealType.dinner;
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Snacks',
                            on: _type == MealType.snack,
                            onTap: () => setState(() {
                              _type = MealType.snack;
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Veg',
                            on: _diet == 'veg',
                            onTap: () => setState(() {
                              _diet = _diet == 'veg' ? null : 'veg';
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Egg',
                            on: _diet == 'egg',
                            onTap: () => setState(() {
                              _diet = _diet == 'egg' ? null : 'egg';
                            }),
                          ),
                          _Chip(
                            c: c,
                            label: 'Non-veg',
                            on: _diet == 'nonveg',
                            onTap: () => setState(() {
                              _diet = _diet == 'nonveg' ? null : 'nonveg';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'PLATES',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                            color: c.faint,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${list.length} of ${all.length}',
                          style: TextStyle(fontSize: 12, color: c.faint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (snap.connectionState != ConnectionState.done)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snap.hasError)
                      Text(
                        'Catalog error: ${snap.error}',
                        style: TextStyle(color: c.ink),
                      )
                    else if (list.isEmpty)
                        Text(
                          'No plate matches that search.',
                          style: TextStyle(color: c.muted),
                        )
                      else
                        ...list.map(
                              (item) => _DishCard(
                            c: c,
                            item: item,
                            imageUrl: _meals.imageUrl(item.imagePath),
                            onTap: () => _open(item),
                          ),
                        ),
                    const SizedBox(height: 16),
                    MetalBtn(
                      label: 'Tune food setup',
                      ghost: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EatSetupPage(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.c,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final ArcColors c;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.cta : c.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: c.faint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl == null
                  ? Container(width: 40, height: 40, color: c.chip)
                  : Image.network(
                imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 40, height: 40, color: c.chip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.c,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final ArcColors c;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? c.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? c.ink : c.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: on ? c.page : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.c,
    required this.item,
    required this.onTap,
    this.imageUrl,
  });

  final ArcColors c;
  final MealNutrition item;
  final String? imageUrl;
  final VoidCallback onTap;

  String get _diet {
    final tags = item.dietaryTags.map((e) => e.toLowerCase()).toList();
    if (tags.contains('nonveg')) return 'Non-veg';
    if (tags.contains('egg')) return 'Egg';
    return 'Veg';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl == null
                    ? Container(
                  width: 72,
                  height: 72,
                  color: c.chip,
                  child: Icon(Icons.restaurant, color: c.faint),
                )
                    : Image.network(
                  imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: c.chip,
                    child: Icon(Icons.restaurant, color: c.faint),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.mealType.name[0].toUpperCase()}${item.mealType.name.substring(1)}  ·  $_diet',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                    const SizedBox(height: 8),
                    _VialRow(c: c, item: item),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.proteinG.toStringAsFixed(
                      item.proteinG == item.proteinG.roundToDouble() ? 0 : 1,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    'g P',
                    style: TextStyle(fontSize: 11, color: c.ice),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VialRow extends StatelessWidget {
  const _VialRow({required this.c, required this.item});

  final ArcColors c;
  final MealNutrition item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Vial(
            c: c,
            letter: 'P',
            value: '${item.proteinG.toStringAsFixed(0)}g',
            fill: (item.proteinG / 40).clamp(0, 1),
            color: c.ice,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Vial(
            c: c,
            letter: 'C',
            value: '${item.carbsG.toStringAsFixed(0)}g',
            fill: (item.carbsG / 80).clamp(0, 1),
            color: const Color(0xFF7D8A9E),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Vial(
            c: c,
            letter: 'F',
            value: '${item.fatG.toStringAsFixed(0)}g',
            fill: (item.fatG / 30).clamp(0, 1),
            color: const Color(0xFFB08968),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Vial(
            c: c,
            letter: 'K',
            value: '${item.caloriesKcal.round()}',
            fill: (item.caloriesKcal / 700).clamp(0, 1),
            color: c.faint,
          ),
        ),
      ],
    );
  }
}

class _Vial extends StatelessWidget {
  const _Vial({
    required this.c,
    required this.letter,
    required this.value,
    required this.fill,
    required this.color,
  });

  final ArcColors c;
  final String letter;
  final String value;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$letter  $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 4,
              color: color,
              backgroundColor: c.chip,
            ),
          ),
        ),
      ],
    );
  }
}