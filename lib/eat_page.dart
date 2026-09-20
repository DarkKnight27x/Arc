import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_ctrl.dart';
import 'data/meal_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        final q = search.text.trim().toLowerCase();

        return ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: ListView(
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
                        text: 'Feed the\n',
                        style: TextStyle(
                          fontSize: 36,
                          height: 1.02,
                          color: c.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: 'training.',
                        style: TextStyle(
                          fontSize: 36,
                          height: 1.02,
                          fontStyle: FontStyle.italic,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: c.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: c.line),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: metalPanel(c),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROTEIN TODAY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                    color: c.faint,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '64',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: c.ink,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '  /  120 g',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: c.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹90  /  ₹250',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: 64 / 120,
                          minHeight: 4,
                          color: c.ice,
                          backgroundColor: c.chip,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Today's plate",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<MealNutrition>>(
                  future: _catalog,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return Text(
                        'Catalog error: ${snap.error}',
                        style: TextStyle(color: c.ink),
                      );
                    }
                    final list = (snap.data ?? []).where((m) {
                      if (q.isEmpty) return true;
                      return m.name.toLowerCase().contains(q) ||
                          m.mealType.name.toLowerCase().contains(q) ||
                          m.dietaryTags.any((t) => t.toLowerCase().contains(q));
                    }).toList();
                    if (list.isEmpty) {
                      return Text(
                        'No plate matches that search.',
                        style: TextStyle(color: c.muted),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < list.length; i++)
                          FadeSlideIn(
                            index: i,
                            child: _MealTile(
                              c: c,
                              item: list[i],
                              imageUrl: _meals.imageUrl(list[i].imagePath),
                              onTap: () async {
                                final detail =
                                await _meals.fetchDetail(list[i].mealId);
                                if (!context.mounted || detail == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MealDetailPage(
                                      detail: detail,
                                      imageUrl: _meals.imageUrl(
                                        detail.meal.imagePath,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: metalPanel(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOOD NOTE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: c.faint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Paneer 3–4× this week',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        'Eggs 5+ · eggetarian · no allergies',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MetalBtn(label: '+  Log a meal', onTap: () {}),
                const SizedBox(height: 10),
                MetalBtn(
                  label: 'Tune food setup',
                  ghost: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EatSetupPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.c,
    required this.item,
    required this.onTap,
    this.imageUrl,
  });

  final ArcColors c;
  final MealNutrition item;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl == null
                    ? Container(
                  width: 56,
                  height: 56,
                  color: c.chip,
                  child: Icon(Icons.restaurant, color: c.faint, size: 20),
                )
                    : Image.network(
                  imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: c.chip,
                    child: Icon(Icons.restaurant, color: c.faint, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mealType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: c.faint,
                      ),
                    ),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.proteinG.toStringAsFixed(0)}g',
                    style: TextStyle(fontSize: 13, color: c.ice),
                  ),
                  Text(
                    '${item.caloriesKcal.round()} kcal',
                    style: TextStyle(fontSize: 11, color: c.faint),
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