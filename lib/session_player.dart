import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/workout_models.dart';
import 'theme_ctrl.dart';
import 'widgets/health_visuals.dart';

class SessionPlayer extends StatefulWidget {
  const SessionPlayer({
    super.key,
    required this.dayTitle,
    required this.exercises,
  });

  final String dayTitle;
  final List<WorkoutMove> exercises;

  @override
  State<SessionPlayer> createState() => _SessionPlayerState();
}

class _SessionPlayerState extends State<SessionPlayer> {
  int _currentIndex = 0;
  final Map<String, List<bool>> _completion = {};
  bool _resting = false;

  @override
  void initState() {
    super.initState();
    for (var ex in widget.exercises) {
      _completion[ex.id] = List.generate(3, (_) => false);
    }
  }

  void _next() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _finish() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session completed!')),
    );
  }

  void _toggleSet(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      final current = _completion[widget.exercises[_currentIndex].id]!;
      current[index] = !current[index];
      
      if (current[index]) {
        _resting = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        final ex = widget.exercises[_currentIndex];
        final sets = _completion[ex.id]!;

        return Scaffold(
          backgroundColor: c.page,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _header(c),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 10),
                          _gifSection(c, ex),
                          const SizedBox(height: 24),
                          _setTracker(c, ex, sets),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    _navigationBar(c),
                  ],
                ),
                if (_resting)
                  _restOverlay(c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(ArcColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: c.ink),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                widget.dayTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: c.faint,
                ),
              ),
              Text(
                'EXERCISE ${_currentIndex + 1}/${widget.exercises.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _gifSection(ArcColors c, WorkoutMove ex) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: metalPanel(c, glow: true, radius: 28),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ex.gifUrl != null)
              Image.network(
                ex.gifUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(child: CircularProgressIndicator(color: c.brand));
                },
              )
            else
              ColoredBox(
                color: c.chip,
                child: Center(
                  child: Icon(Icons.fitness_center, color: c.faint, size: 48),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ex.machine,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setTracker(ArcColors c, WorkoutMove ex, List<bool> sets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: c.faint,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < sets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SetRow(
              index: i + 1,
              reps: ex.scheme.split('×').last.trim(),
              done: sets[i],
              c: c,
              onTap: () => _toggleSet(i),
            ),
          ),
      ],
    );
  }

  Widget _navigationBar(ArcColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.shell,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: MetalBtn(
              label: 'Previous',
              ghost: true,
              onTap: _prev,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: MetalBtn(
              label: _currentIndex == widget.exercises.length - 1 ? 'Finish' : 'Next Exercise',
              onTap: _next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _restOverlay(ArcColors c) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RESTING',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w800,
                  color: c.brand,
                ),
              ),
              const SizedBox(height: 30),
              LiquidMetalTimer(
                duration: const Duration(seconds: 60),
                onComplete: () => setState(() => _resting = false),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 120,
                child: MetalBtn(
                  label: 'Skip',
                  ghost: true,
                  onTap: () => setState(() => _resting = false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.reps,
    required this.done,
    required this.c,
    required this.onTap,
  });

  final int index;
  final String reps;
  final bool done;
  final ArcColors c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ArcMotion.base,
        padding: const EdgeInsets.all(16),
        decoration: done 
          ? metalWell(c, radius: 20)
          : metalPanel(c, radius: 20),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.brand : c.chip,
                border: Border.all(color: c.line.withOpacity(0.3)),
              ),
              child: Icon(
                done ? Icons.check : Icons.add,
                size: 16,
                color: done ? Colors.white : c.faint,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'SET $index',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: done ? c.muted : c.ink,
              ),
            ),
            const Spacer(),
            Text(
              reps,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: done ? c.faint : c.brand,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'reps',
              style: TextStyle(fontSize: 11, color: c.faint),
            ),
          ],
        ),
      ),
    );
  }
}
