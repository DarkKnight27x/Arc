import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/health_models.dart';
import 'data/health_service.dart';
import 'theme_ctrl.dart';
import 'widgets/health_metric_card.dart';
import 'widgets/health_visuals.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onOpenTrain,
    this.onOpenEat,
    this.onOpenRecover,
    this.onOpenYou,
    this.onStartSession,
    this.onOpenRehab,
  });

  final VoidCallback? onOpenTrain;
  final VoidCallback? onOpenEat;
  final VoidCallback? onOpenRecover;
  final VoidCallback? onOpenYou;
  final VoidCallback? onStartSession;
  final VoidCallback? onOpenRehab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HealthService _healthService =
      HealthService.instance;

  ArcHealthData _health = const ArcHealthData();

  bool _loading = true;
  bool _hasHealthAccess = false;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() {
      _loading = true;
    });

    final authorized =
        await _healthService.requestAuthorization();

    if (!authorized) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _hasHealthAccess = false;
      });

      return;
    }

    final data = await _healthService.fetchToday();

    if (!mounted) return;

    setState(() {
      _health = data;
      _hasHealthAccess = true;
      _loading = false;
    });
  }

  String _dateLabel() {
    final now = DateTime.now();

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];

    return '${weekdays[now.weekday - 1]}  ·  '
        '${months[now.month - 1]} ${now.day}';
  }

  String _formatNumber(num value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  String _formatCalories(double calories) {
    return _formatNumber(calories);
  }

  String _formatExercise(Duration duration) {
    if (duration.inMinutes == 0) {
      return '--';
    }

    return '${duration.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeCtrl.value == ThemeMode.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: ColoredBox(
            color: c.page,
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _loadHealth,
                color: c.ice,
                backgroundColor: c.raised,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    36,
                  ),
                  children: [
                    _header(c),
                    const SizedBox(height: 18),

                    FadeSlideIn(
                      index: 0,
                      child: Text(
                        _dateLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                          color: c.faint,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    FadeSlideIn(
                      index: 1,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Good morning,',
                              style: arcDisplay(
                                c,
                                size: 28,
                              ).copyWith(color: c.ink),
                            ),
                            TextSpan(
                              text: ' Saarthak.',
                              style: arcDisplay(
                                c,
                                size: 28,
                                italic: true,
                              ).copyWith(color: c.ink),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (!_hasHealthAccess)
                      FadeSlideIn(
                        index: 2,
                        child: _healthAccessCard(c),
                      )
                    else ...[
                      FadeSlideIn(
                        index: 2,
                        child: _movementHero(c),
                      ),

                      const SizedBox(height: 10),

                      FadeSlideIn(
                        index: 3,
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: HealthMetricCard(
                                label: 'CALORIES',
                                value: _loading
                                    ? '—'
                                    : _formatCalories(
                                        _health.activeCalories,
                                      ),
                                unit: 'kcal',
                                icon:
                                    Icons.local_fire_department_outlined,
                                subtitle:
                                    'active today',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HealthMetricCard(
                                label: 'HEART',
                                value: _loading
                                    ? '—'
                                    : (_health.heartRate
                                            ?.toString() ??
                                        '—'),
                                unit: 'bpm',
                                icon:
                                    Icons.favorite_border,
                                subtitle:
                                    _health
                                            .restingHeartRate !=
                                        null
                                    ? 'resting ${_health.restingHeartRate}'
                                    : 'latest reading',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      FadeSlideIn(
                        index: 4,
                        child: HealthSleepCard(
                          data: _health,
                        ),
                      ),

                      const SizedBox(height: 10),

                      FadeSlideIn(
                        index: 5,
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: HealthMetricCard(
                                label: 'EXERCISE',
                                value: _loading
                                    ? '—'
                                    : _formatExercise(
                                        _health.exercise,
                                      ),
                                unit: '',
                                icon:
                                    Icons.directions_run,
                                subtitle:
                                    _health.flightsClimbed >
                                            0
                                        ? '${_health.flightsClimbed} floors'
                                        : 'movement today',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HealthMetricCard(
                                label: 'HEART RATE',
                                value:
                                    _health.restingHeartRate
                                            ?.toString() ??
                                        '—',
                                unit: 'bpm',
                                icon:
                                    Icons.monitor_heart_outlined,
                                subtitle: _health.hrvMs !=
                                        null
                                    ? 'HRV ${_health.hrvMs!.round()} ms'
                                    : 'resting',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      FadeSlideIn(
                        index: 6,
                        child: _sectionTitle(
                          c,
                          'TODAY',
                        ),
                      ),

                      const SizedBox(height: 12),

                      FadeSlideIn(
                        index: 7,
                        child: _bodySnapshot(c),
                      ),

                      const SizedBox(height: 22),

                      FadeSlideIn(
                        index: 8,
                        child: _trainingCard(c),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(ArcColors c) {
    return Row(
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
    );
  }

  Widget _movementHero(ArcColors c) {
    const stepGoal = 150.0; // Fills at 150 steps
    final progress = (_health.steps / stepGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: metalPanel(
        c,
        glow: true,
        radius: 28,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOVEMENT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: c.faint,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _loading ? '—' : _formatNumber(_health.steps),
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 42,
                        height: 0.9,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _health.distanceKm > 0
                      ? '${_health.distanceKm.toStringAsFixed(1)} km walked'
                      : 'Active today',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: metalWell(c, radius: 999),
                  child: Text(
                    '${(progress * 100).round()}% OF GOAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isArcDark ? c.brand : c.brand.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          LiquidMetalRing(
            value: progress,
            size: 110,
            strokeWidth: 16,
          ),
        ],
      ),
    );
  }

  Widget _healthAccessCard(ArcColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: metalPanel(
        c,
        glow: true,
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: metalWell(
                  c,
                  radius: 13,
                ),
                child: Icon(
                  Icons.favorite_border,
                  color: isArcDark ? c.ice : c.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect your health data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Arc can use your phone or wearable health data '
            'to show movement, calories, sleep, heart rate '
            'and recovery metrics here.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: c.muted,
            ),
          ),

          const SizedBox(height: 16),

          MetalBtn(
            label: 'Connect health data',
            icon: Icons.favorite_rounded,
            onTap: _loadHealth,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    ArcColors c,
    String title,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    );
  }

  Widget _bodySnapshot(ArcColors c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: metalPanel(
        c,
        radius: 22,
      ),
      child: Column(
        children: [
          _SnapshotRow(
            icon: Icons.monitor_weight_outlined,
            label: 'BODY MASS',
            value: _health.weightKg != null
                ? '${_health.weightKg!.toStringAsFixed(1)} kg'
                : 'No data',
            c: c,
          ),
          const SizedBox(height: 14),
          _SnapshotRow(
            icon: Icons.air,
            label: 'RESPIRATION',
            value: _health.respiratoryRate != null
                ? '${_health.respiratoryRate!.round()} / min'
                : 'No data',
            c: c,
          ),
          const SizedBox(height: 14),
          _SnapshotRow(
            icon: Icons.water_drop_outlined,
            label: 'BLOOD OXYGEN',
            value: _health.bloodOxygen != null
                ? '${_health.bloodOxygen!.round()}%'
                : 'No data',
            c: c,
          ),
        ],
      ),
    );
  }

  Widget _trainingCard(ArcColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: metalPanel(
        c,
        glow: true,
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "TODAY'S PATH",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: c.faint,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: metalWell(
                  c,
                  radius: 999,
                ),
                child: Text(
                  'PPL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.ice,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Upper push',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '6 movements · 42 min · machines first',
            style: TextStyle(
              fontSize: 13,
              color: c.muted,
            ),
          ),

          const SizedBox(height: 16),

          MetalBtn(
            label: 'Start session',
            icon: Icons.play_arrow_rounded,
            onTap: widget.onStartSession ?? () {},
          ),

          const SizedBox(height: 10),

          MetalBtn(
            label: '10-minute version',
            ghost: true,
            onTap: widget.onStartSession ?? () {},
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
  });

  final IconData icon;
  final String label;
  final String value;
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
          Container(
            width: 34,
            height: 34,
            decoration: metalWell(
              c,
              radius: 11,
            ),
            child: Icon(
              icon,
              size: 17,
              color: isArcDark ? c.ice : c.ink,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
              color: c.faint,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}