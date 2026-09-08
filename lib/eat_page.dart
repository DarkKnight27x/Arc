import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

class EatPage extends StatefulWidget {
  const EatPage({super.key});
  @override
  State<EatPage> createState() => _EatPageState();
}

class _MealData {
  const _MealData(this.slot, this.title, this.p, this.rs);
  final String slot, title, p, rs;
}

class _EatPageState extends State<EatPage> {
  final search = TextEditingController();

  static const meals = [
    _MealData('BREAKFAST', 'Idli + sambar + 2 eggs', '24g', '₹38'),
    _MealData('LUNCH', 'Roti + palak + dal + curd', '29g', '₹52'),
    _MealData('DINNER', 'Family plate · leave room for dal', '—', 'flexible'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        final q = search.text.trim().toLowerCase();
        final list = meals
            .where((m) =>
        q.isEmpty ||
            m.slot.toLowerCase().contains(q) ||
            m.title.toLowerCase().contains(q))
            .toList();

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
                    Text('THANE',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                            color: c.faint)),
                  ],
                ),
                const SizedBox(height: 18),
                Text('EAT  ·  WEDNESDAY',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: c.faint,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Feed the\n',
                      style: TextStyle(
                          fontSize: 36,
                          height: 1.02,
                          color: c.ink,
                          fontWeight: FontWeight.w500)),
                  TextSpan(
                      text: 'training.',
                      style: TextStyle(
                          fontSize: 36,
                          height: 1.02,
                          fontStyle: FontStyle.italic,
                          color: c.ink,
                          fontWeight: FontWeight.w500)),
                ])),
                const SizedBox(height: 8),
                Text('Indian plates, a clear budget, no calorie theatre.',
                    style: TextStyle(fontSize: 14, color: c.muted)),
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
                                Text('PROTEIN TODAY',
                                    style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                        color: c.faint)),
                                const SizedBox(height: 6),
                                Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: '64',
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: c.ink)),
                                  TextSpan(
                                      text: '  /  120 g',
                                      style: TextStyle(
                                          fontSize: 14, color: c.muted)),
                                ])),
                              ],
                            ),
                          ),
                          Text('₹90  /  ₹250',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.ink)),
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
                Text("Today's plate",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                const SizedBox(height: 10),
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn(index: i, child: _Meal(c, list[i])),
                if (list.isEmpty)
                  Text('No plate matches that search.',
                      style: TextStyle(color: c.muted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: metalPanel(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FOOD NOTE',
                          style: TextStyle(
                              fontSize: 11, letterSpacing: 1.0, color: c.faint)),
                      const SizedBox(height: 6),
                      Text('Paneer 3–4× this week',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink)),
                      Text('Eggs 5+ · eggetarian · no allergies',
                          style: TextStyle(fontSize: 13, color: c.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MetalBtn(label: '+  Log a meal', onTap: () {}),
                const SizedBox(height: 10),
                MetalBtn(label: 'Tune food setup', ghost: true, onTap: () {}),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Meal extends StatelessWidget {
  const _Meal(this.c, this.m);
  final ArcColors c;
  final _MealData m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                BoxDecoration(color: c.ok, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.slot,
                        style: TextStyle(
                            fontSize: 11, letterSpacing: 1.0, color: c.faint)),
                    Text(m.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m.p, style: TextStyle(fontSize: 13, color: c.ice)),
                  Text(m.rs, style: TextStyle(fontSize: 11, color: c.faint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}