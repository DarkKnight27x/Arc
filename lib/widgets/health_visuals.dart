import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme_ctrl.dart';

class LiquidMetalRing extends StatefulWidget {
  const LiquidMetalRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 14,
  });

  final double value;
  final double size;
  final double strokeWidth;

  @override
  State<LiquidMetalRing> createState() => _LiquidMetalRingState();
}

class _LiquidMetalRingState extends State<LiquidMetalRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LiquidRingPainter(
              value: widget.value,
              phase: _controller.value,
              c: c,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _LiquidRingPainter extends CustomPainter {
  _LiquidRingPainter({
    required this.value,
    required this.phase,
    required this.c,
    required this.strokeWidth,
  });

  final double value;
  final double phase;
  final ArcColors c;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track path (well)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = c.chip;
    canvas.drawCircle(center, radius, trackPaint);

    // Inner glow / shadow for the well
    final innerShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withOpacity(0.2);
    canvas.drawCircle(center, radius + (strokeWidth / 2) - 1, innerShadowPaint);

    if (value <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * value.clamp(0.0, 1.0);

    // Liquid gradient
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        c.brand.withOpacity(0.7),
        c.ice,
        c.brand,
      ],
      stops: const [0.0, 0.7, 1.0],
      transform: GradientRotation(startAngle),
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Liquid highlight / shine
    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.3);

    // Only draw shine on the active part
    canvas.drawArc(rect, startAngle + 0.1, sweepAngle - 0.2, false, shinePaint);

    // Leading "blob" effect
    final leadAngle = startAngle + sweepAngle;
    final leadCenter = Offset(
      center.dx + radius * math.cos(leadAngle),
      center.dy + radius * math.sin(leadAngle),
    );

    final blobSize = strokeWidth * (1.2 + 0.1 * math.sin(phase * 2 * math.pi));
    final blobPaint = Paint()
      ..color = c.brand
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawCircle(leadCenter, blobSize / 2, blobPaint);
    
    // Tiny reflection on blob
    final reflectionPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(
      leadCenter + Offset(-blobSize * 0.2, -blobSize * 0.2),
      blobSize * 0.1,
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(_LiquidRingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.phase != phase || oldDelegate.c != c;
}

class LiquidMetalHeart extends StatefulWidget {
  const LiquidMetalHeart({
    super.key,
    required this.rate,
    this.size = 60,
  });

  final int rate;
  final double size;

  @override
  State<LiquidMetalHeart> createState() => _LiquidMetalHeartState();
}

class _LiquidMetalHeartState extends State<LiquidMetalHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(LiquidMetalHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rate != oldWidget.rate) {
      // Adjust speed based on heart rate
      final speed = widget.rate > 0 ? (60 / widget.rate).clamp(0.4, 1.5) : 1.0;
      _controller.duration = Duration(milliseconds: (1000 * speed).round());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Pulse scale
          final scale = 1.0 + 0.1 * math.sin(_controller.value * math.pi);
          return Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: _HeartPainter(
                phase: _controller.value,
                c: c,
                fillLevel: widget.rate > 0 ? (widget.rate / 200).clamp(0.3, 0.9) : 0.0,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({
    required this.phase,
    required this.c,
    required this.fillLevel,
  });

  final double phase;
  final ArcColors c;
  final double fillLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = c.chip;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.25);
    path.cubicTo(width * 0.2, height * 0.1, 0, height * 0.4, width / 2, height * 0.9);
    path.cubicTo(width, height * 0.4, width * 0.8, height * 0.1, width / 2, height * 0.25);

    // Draw background heart (well)
    canvas.drawPath(path, paint);

    // Clip to heart shape for the liquid
    canvas.save();
    canvas.clipPath(path);

    if (fillLevel > 0) {
      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            c.brand,
            c.ice,
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, height));

      final fillHeight = height * (1 - fillLevel);
      final wavePath = Path();
      wavePath.moveTo(0, fillHeight);
      
      for (double i = 0; i <= width; i++) {
        wavePath.lineTo(
          i,
          fillHeight + 4 * math.sin((i / width * 2 * math.pi) + (phase * 2 * math.pi)),
        );
      }
      wavePath.lineTo(width, height);
      wavePath.lineTo(0, height);
      wavePath.close();

      canvas.drawPath(wavePath, liquidPaint);

      // Shine on top of liquid
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(width * 0.3, height * 0.4), width * 0.1, shinePaint);
    }

    canvas.restore();

    // Outline
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = c.line.withOpacity(0.5);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.c != c || oldDelegate.fillLevel != fillLevel;
}

class LiquidMetalSleepPool extends StatefulWidget {
  const LiquidMetalSleepPool({
    super.key,
    required this.totalHours,
    required this.deepHours,
    required this.remHours,
  });

  final double totalHours;
  final double deepHours;
  final double remHours;

  @override
  State<LiquidMetalSleepPool> createState() => _LiquidMetalSleepPoolState();
}

class _LiquidMetalSleepPoolState extends State<LiquidMetalSleepPool>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Container(
      height: 80,
      width: double.infinity,
      decoration: metalWell(c, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SleepPoolPainter(
              phase: _controller.value,
              c: c,
              total: widget.totalHours,
              deep: widget.deepHours,
              rem: widget.remHours,
            ),
          );
        },
      ),
    );
  }
}

class _SleepPoolPainter extends CustomPainter {
  _SleepPoolPainter({
    required this.phase,
    required this.c,
    required this.total,
    required this.deep,
    required this.rem,
  });

  final double phase;
  final ArcColors c;
  final double total;
  final double deep;
  final double rem;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final targetHours = 8.0;
    final fillLevel = (total / targetHours).clamp(0.1, 1.0);
    
    // Layered waves for different sleep types
    _drawWave(canvas, size, fillLevel, c.brand.withOpacity(0.3), phase, 1.0, 6.0);
    _drawWave(canvas, size, fillLevel * 0.7, c.brand.withOpacity(0.5), phase + 0.3, 1.2, 5.0);
    _drawWave(canvas, size, fillLevel * 0.4, c.ice.withOpacity(0.6), phase + 0.6, 1.5, 4.0);

    // Add some metallic specks/bubbles
    final rand = math.Random(42);
    final speckPaint = Paint()..color = Colors.white.withOpacity(0.15);
    for (int i = 0; i < 10; i++) {
      final x = rand.nextDouble() * size.width;
      final y = size.height * (1 - fillLevel) + rand.nextDouble() * size.height * fillLevel;
      final bubbleY = y + 5 * math.sin(phase * 2 * math.pi + x);
      canvas.drawCircle(Offset(x, bubbleY), 1 + rand.nextDouble() * 2, speckPaint);
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double fill,
    Color color,
    double phase,
    double frequency,
    double amplitude,
  ) {
    final paint = Paint()..color = color;
    final path = Path();
    final fillHeight = size.height * (1 - fill);

    path.moveTo(0, fillHeight);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        fillHeight + amplitude * math.sin((i / size.width * frequency * 2 * math.pi) + (phase * 2 * math.pi)),
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SleepPoolPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.c != c;
}

class LiquidMetalTimer extends StatefulWidget {
  const LiquidMetalTimer({
    super.key,
    required this.duration,
    this.onComplete,
    this.size = 200,
  });

  final Duration duration;
  final VoidCallback? onComplete;
  final double size;

  @override
  State<LiquidMetalTimer> createState() => _LiquidMetalTimerState();
}

class _LiquidMetalTimerState extends State<LiquidMetalTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.reverse(from: 1.0).then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final remaining = widget.duration.inSeconds * _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _TimerPainter(
                  progress: _controller.value,
                  c: c,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.ceil().toString(),
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'SECONDS',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: c.faint,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  _TimerPainter({required this.progress, required this.c});
  final double progress;
  final ArcColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 16.0;

    final trackPaint = Paint()
      ..color = c.chip
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final liquidPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [c.brand, c.ice, c.brand],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, startAngle, sweepAngle, false, liquidPaint);

    // Inner glow
    final glowPaint = Paint()
      ..color = c.brand.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.c != c;
}
