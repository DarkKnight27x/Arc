import 'package:flutter/material.dart';

import '../data/home_workout.dart';
import '../data/home_workout_service.dart';
import '../data/workout_models.dart';
import '../theme_ctrl.dart';

class TrainingVariantPanel extends StatefulWidget {
  const TrainingVariantPanel({
    super.key,
    required this.day,
    required this.service,
    required this.location,
    required this.onLocation,
    required this.onStart,
    required this.moveBuilder,
    this.initialMinutes,
  });
  final WorkoutDay day;
  final HomeWorkoutService service;
  final String location;
  final ValueChanged<String> onLocation;
  final void Function(HomeProposal) onStart;
  final Widget Function(WorkoutMove) moveBuilder;
  final int? initialMinutes;
  @override
  State<TrainingVariantPanel> createState() => _TrainingVariantPanelState();
}

class _TrainingVariantPanelState extends State<TrainingVariantPanel> {
  final Set<String> _equipment = {'bodyweight'};
  int? _minutes;
  HomeProposal? _proposal;
  String? _error;
  bool _loading = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
    if (widget.location == 'home') _load();
  }

  @override
  void didUpdateWidget(covariant TrainingVariantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day.id != widget.day.id ||
        (oldWidget.location != widget.location && widget.location == 'home')) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _proposal = null;
      _error = null;
    });
    try {
      final proposal = await widget.service.propose(
        widget.day,
        Set.of(_equipment),
        _minutes,
      );
      if (mounted && request == _request) {
        setState(() {
          _proposal = proposal;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = e is StateError ? e.message.toString() : 'Unable to load reviewed alternatives. Check your connection and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: metalPanel(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAINING LOCATION',
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final location in ['gym', 'home'])
                ChoiceChip(
                  label: Text(
                    location == 'gym' ? 'Gym - saved plan' : 'Home alternative',
                  ),
                  selected: widget.location == location,
                  onSelected: (_) => widget.onLocation(location),
                ),
            ],
          ),
          Text(
            'Scheduled focus: ${widget.day.moves.map((m) => m.primaryTarget == null ? 'Unspecified target' : muscleGroup(m.primaryTarget!)).toSet().join(', ')}',
            style: TextStyle(color: c.ink),
          ),
          if (widget.location == 'home') ...[
            const SizedBox(height: 16),
            Text('AVAILABLE EQUIPMENT', style: TextStyle(color: c.muted)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('No equipment'),
                  selected: _equipment.length == 1,
                  onSelected: (_) {
                    _equipment
                      ..clear()
                      ..add('bodyweight');
                    _load();
                  },
                ),
                for (final option in [
                  ('dumbbells', 'Dumbbells'),
                  ('bands', 'Resistance bands'),
                ])
                  FilterChip(
                    label: Text(option.$2),
                    selected: _equipment.contains(option.$1),
                    onSelected: (selected) {
                      if (selected) {
                        _equipment.add(option.$1);
                      } else {
                        _equipment.remove(option.$1);
                      }
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('TIME AVAILABLE', style: TextStyle(color: c.muted)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in <int?>[null, 30, 15])
                  ChoiceChip(
                    label: Text(
                      minutes == null
                          ? 'Full available session'
                          : '$minutes minutes',
                    ),
                    selected: _minutes == minutes,
                    onSelected: (_) {
                      _minutes = minutes;
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Home uses reviewed prescriptions. Estimates include setup, rests and transitions; they are not a duration guarantee.',
              style: TextStyle(color: c.muted),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: c.ink)),
              TextButton(
                onPressed: _load,
                child: const Text('Retry alternatives'),
              ),
            ],
            if (_proposal != null) ...[
              if (_proposal!.available)
                Text(
                  'HOME PROPOSAL - about ${(_proposal!.estimatedSeconds / 60).ceil()} minutes',
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
                ),
              for (final warning in _proposal!.limitations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(warning, style: TextStyle(color: c.muted)),
                ),
              for (final move in _proposal!.moves) ...[
                Text(
                  '${muscleGroup(move.primaryTarget!)} - ${move.movementPattern}',
                  style: TextStyle(color: c.muted),
                ),
                widget.moveBuilder(move),
              ],
              if (_proposal!.available)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PressScale(
                    onTap: () => widget.onStart(_proposal!),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: metalPrimary(c),
                      child: Text(
                        'Review & start Home',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.ctaInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
