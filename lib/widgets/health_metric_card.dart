import 'package:flutter/material.dart';

import '../data/health_models.dart';
import '../theme_ctrl.dart';
import 'health_visuals.dart';

class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.subtitle,
    this.progress,
    this.large = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String? subtitle;
  final double? progress;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final isHeart = label.toUpperCase().contains('HEART');

    return Container(
      padding: EdgeInsets.all(large ? 20 : 16),
      decoration: metalPanel(
        c,
        glow: large,
        radius: large ? 24 : 20,
      ),
      child: Stack(
        children: [
          if (isHeart && !large)
            Positioned(
              right: -8,
              bottom: -2, // Moved up from -10 to prevent clipping
              child: Opacity(
                opacity: 0.15,
                child: LiquidMetalHeart(
                  rate: int.tryParse(value) ?? 0,
                  size: 80,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: metalWell(
                      c,
                      radius: 12,
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: c.ice,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: c.faint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: large ? 34 : 27,
                      height: 0.95,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.muted,
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 14),
                _MetalProgress(
                  value: progress!.clamp(0.0, 1.0),
                  c: c,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class HealthSleepCard extends StatelessWidget {
  const HealthSleepCard({
    super.key,
    required this.data,
  });

  final ArcHealthData data;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours == 0 && minutes == 0) {
      return '--';
    }

    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);

    final sleepProgress =
        data.sleepScore.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: metalPanel(
        c,
        glow: true,
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: metalWell(
                  c,
                  radius: 12,
                ),
                child: Icon(
                  Icons.nightlight_round,
                  size: 17,
                  color: c.ice,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SLEEP',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: c.faint,
                ),
              ),
              const Spacer(),
              Text(
                data.sleep.inMinutes == 0
                    ? 'NO DATA'
                    : '${(sleepProgress * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: c.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDuration(data.sleep),
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 34,
                            height: 0.95,
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'sleep',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SleepStage(
                          label: 'DEEP',
                          value: _formatDuration(data.deepSleep),
                          c: c,
                        ),
                        const SizedBox(width: 16),
                        _SleepStage(
                          label: 'REM',
                          value: _formatDuration(data.remSleep),
                          c: c,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // The Sleep Pool Visualization
              SizedBox(
                width: 100,
                height: 100,
                child: LiquidMetalSleepPool(
                  totalHours: data.sleepHours,
                  deepHours: data.deepSleep.inMinutes / 60.0,
                  remHours: data.remSleep.inMinutes / 60.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MetalProgress(
            value: sleepProgress,
            c: c,
          ),
        ],
      ),
    );
  }
}

class _SleepStage extends StatelessWidget {
  const _SleepStage({
    required this.label,
    required this.value,
    required this.c,
  });

  final String label;
  final String value;
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: c.faint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}

class _MetalProgress extends StatelessWidget {
  const _MetalProgress({
    required this.value,
    required this.c,
  });

  final double value;
  final ArcColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: metalWell(
        c,
        radius: 999,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      c.brand.withOpacity(0.8),
                      c.ice,
                      c.brand,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.brand.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      // Liquid shine
                      Positioned(
                        top: 2,
                        left: 4,
                        right: 4,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
