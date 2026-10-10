import 'data/home_workout.dart';
import 'data/home_workout_service.dart';
import 'data/training_context_service.dart';
import 'widgets/training_variant_panel.dart';
import 'injury_mode.dart';

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/workout_session.dart';
import 'data/workout_session_service.dart';

import 'package:flutter/material.dart';

import 'data/workout_models.dart';
import 'data/workout_service.dart';
import 'coach_page.dart';
import 'session_player.dart';
import 'theme_ctrl.dart';
import 'widgets/exercise_detail_dialog.dart';
import 'widgets/location_label.dart';
import 'focus_workout_page.dart';
import 'anatomy_test_page.dart';

class TrainPage extends StatefulWidget {
  const TrainPage({
    super.key,
    this.workoutService,
    this.homeService,
    this.sessionService,
    this.contextService,
  });
  final WorkoutService? workoutService;
  final HomeWorkoutService? homeService;
  final WorkoutSessionService? sessionService;
  final TrainingContextService? contextService;
  @override
  State<TrainPage> createState() => _TrainPageState();
}

class _TrainPageState extends State<TrainPage> {
  WorkoutService get _workouts =>
      widget.workoutService ?? WorkoutService.instance;
  WorkoutSessionService get _sessions =>
      widget.sessionService ?? _sessionService!;
  WorkoutSessionService? _sessionService;
  String _location = 'gym';
  TrainingContext _trainingContext = const TrainingContext();
  List<WorkoutDay> _days = [];
  int _dayIndex = DateTime.now().weekday - 1;
  String? _error;
  bool _starting = false;
  int _request = 0;
  StreamSubscription<AuthState>? _authSubscription;
  int? open = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WorkoutService.changes.addListener(_planActivated);
    _sessionService =
        widget.sessionService ?? WorkoutSessionService(_workouts.client);
    _loadWorkout();
    _authSubscription = _workouts.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.signedOut) {
        _loadWorkout();
      }
    });
  }

  @override
  void dispose() {
    WorkoutService.changes.removeListener(_planActivated);
    _request++;
    _authSubscription?.cancel();
    super.dispose();
  }

  void _planActivated() {
    if (WorkoutService.changes.value?.owner ==
        _workouts.client.auth.currentUser?.id) {
      _loadWorkout(activated: true);
    }
  }

  Future<void> _loadWorkout({bool activated = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _days = [];
    });
    try {
      final data = await _workouts.fetchWorkoutPlan();
      TrainingContext context;
      try {
        context =
            await (widget.contextService ??
                    TrainingContextService(_workouts.client))
                .load();
      } catch (_) {
        context = const TrainingContext(
          error: 'Unable to verify saved discomfort reports. Home is not an injury-safe adaptation.',
        );
      }
      if (!mounted || request != _request) return;
      setState(() {
        _days = data;
        _trainingContext = context;
        _location = activated ? 'gym' : context.location;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = e is FormatException
            ? 'Your saved plan has malformed workout data. Please retry or have the plan corrected.'
            : e is AuthException
            ? e.message
            : 'Unable to load your plan. Check your connection and retry.';
      });
    }
  }

  void _openCoach() {
    final session = _days.isEmpty ? 'Training' : _days[_dayIndex].title;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoachPage(coachOnly: true, session: session),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return 'Day';
    return names[weekday - 1];
  }

  DateTime _dateFor(int weekday) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: weekday - 1));
  }

  Future<void> _startSession(WorkoutDay d, {HomeProposal? home}) async {
    if (!d.canStart || _starting) return;
    setState(() => _starting = true);
    try {
      final service = _sessions;
      WorkoutSession? previous;
      try {
        previous = await service.resume(d.id, reconcile: true);
      } on SessionConflictException catch (conflict) {
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Device and cloud sessions differ'),
            content: const Text(
              'Choose the exact snapshot to continue. The other device snapshot is retained as a conflict backup; no sets will be merged.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep drafts'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'local'),
                child: const Text('Device draft'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'remote'),
                child: const Text('Cloud session'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        previous = choice == 'local' ? conflict.local : conflict.remote;
        await service.resolveConflict(
          previous,
          choice == 'local' ? conflict.remote : conflict.local,
        );
      }
      if (!mounted) return;
      if (previous != null) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Current ${previous!.trainingLocation} session'),
            content: Text(
              'Continue the saved equipment, time choice and exercises. To start another variant, explicitly end or discard this session first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep current draft'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'continue'),
                child: const Text('Continue current session'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'end'),
                child: const Text('End / discard current'),
              ),
            ],
          ),
        );
        if (!mounted || action == null) return;
        if (action == 'end') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Use Finish or Close > Discard in the current player, then choose the new variant.',
              ),
            ),
          );
        }
      } else if (home != null) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Start this Home proposal?'),
            content: SingleChildScrollView(
              child: Text(
                '${home.moves.length} exercises. Equipment: ${home.equipment.join(', ')}. Estimated ${(home.estimatedSeconds / 60).ceil()} minutes.\n${home.limitations.join('\n')}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Review'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start Home'),
              ),
            ],
          ),
        );
        if (accepted != true) return;
      }
      if (!mounted) return;
      final userId = _workouts.client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Please sign in again.');
      final session = previous ?? WorkoutSession.start(userId, d, home: home);
      final wasWarned = session.injuryWarning;
      session.injuryWarning =
          session.injuryWarning ||
          _trainingContext.injuryWarning ||
          InjuryMode.current.value != null;
      if (!wasWarned && session.injuryWarning) session.revision++;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionPlayer(session: session, service: service),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is SessionPersistenceException ? e.message : 'Unable to open your session. Check your connection and retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, _, _) {
        final c = ArcColors.of(context);

        if (_loading) {
          return Center(child: CircularProgressIndicator(color: c.brand));
        }

        if (_days.isEmpty || _error != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error ?? 'No active training plan yet.',
                  style: TextStyle(color: c.muted, fontSize: 16),
                ),
                const SizedBox(height: 12),
                MetalBtn(label: 'Refresh', onTap: _loadWorkout),
                const SizedBox(height: 12),
                MetalBtn(label: 'Coach', ghost: true, onTap: _openCoach),
                const SizedBox(height: 12),
                MetalBtn(
                  label: 'Browse anatomy',
                  ghost: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnatomyTestPage()),
                  ),
                ),
              ],
            ),
          );
        }

        final d = _days[_dayIndex];
        final weekdayExtent =
            56 * MediaQuery.textScalerOf(context).scale(12) / 12;

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
                    LocationLabel(c: c),
                  ],
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<List<String>>(
                  valueListenable: MuscleFocus.selected,
                  builder: (_, muscles, _) {
                    if (muscles.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FocusWorkoutPage(muscles: muscles),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: metalPanel(c),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRIORITY MUSCLES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.1,
                                        color: c.faint,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      muscles.join(' · '),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: c.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: c.muted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  'TRAIN',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: c.faint,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0xFFF5F5F6),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AnatomyTestPage(),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Image.asset(
                            'assets/images/priorityMuscles.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  d.isRestDay
                      ? 'No workout prescribed for this weekday.'
                      : d.estimatedMinutes == null
                      ? 'Duration not specified'
                      : '${d.estimatedMinutes} min estimated',
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
                if (d.muscles.isNotEmpty)
                  Text(d.muscles, style: TextStyle(color: c.muted)),
                const SizedBox(height: 14),
                _SegBar(
                  c: c,
                  index: 0,
                  labels: const ['Plan', 'Coach'],
                  onTap: (i) => i == 1 ? _openCoach() : null,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: weekdayExtent,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final on = i == _dayIndex;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _dayIndex = i;
                          open = 0;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: weekdayExtent,
                          height: weekdayExtent,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? c.cta : const Color(0xFFF5F5F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: on ? c.cta : const Color(0xFFD9D3C7),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekdayName(_days[i].weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: on
                                      ? c.ctaInk
                                      : const Color(0xFF111111),
                                ),
                              ),
                              Text(
                                '${_dateFor(_days[i].weekday).day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: on
                                      ? c.ctaInk
                                      : const Color(0xFF111111),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<InjuryScript?>(
                  valueListenable: InjuryMode.current,
                  builder: (context, local, _) =>
                      (_trainingContext.injuryWarning ||
                          local != null ||
                          _trainingContext.error != null)
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: metalWell(c),
                          child: Text(
                            _trainingContext.error ??
                                'Reported discomfort is active${_trainingContext.reportStatus.isEmpty ? '' : ' (${_trainingContext.reportStatus})'}. Switching Gym to Home does not establish injury safety. Review Recover before training.',
                            style: TextStyle(color: c.ink),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (!d.isRestDay)
                  TrainingVariantPanel(
                    key: ValueKey(d.id),
                    day: d,
                    service:
                        widget.homeService ??
                        HomeWorkoutService(_workouts.client),
                    location: _location,
                    initialMinutes: _trainingContext.minutes,
                    onLocation: (value) => setState(() => _location = value),
                    onStart: (proposal) => _startSession(d, home: proposal),
                    moveBuilder: (move) => _MoveRow(c: c, move: move),
                  ),
                const SizedBox(height: 18),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: d.isRestDay ? 'Recovery' : 'Exercises ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      TextSpan(
                        text: d.isRestDay
                            ? ' - Your scheduled rest day'
                            : 'in saved order',
                        style: TextStyle(fontSize: 13, color: c.faint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_location == 'gym' || d.isRestDay)
                  AnimatedSwitcher(
                    duration: ArcMotion.base,
                    child: Column(
                      key: ValueKey(_dayIndex),
                      children: [
                        for (var i = 0; i < d.regions.length; i++)
                          FadeSlideIn(
                            index: i,
                            delayStep: const Duration(milliseconds: 30),
                            child: _RegionTile(
                              c: c,
                              region: d.regions[i],
                              expanded: open == i,
                              onTap: () =>
                                  setState(() => open = open == i ? null : i),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: metalPanel(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASK THE COACH',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          color: c.faint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Swap a machine · shorten the session.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep the region. Change what is in front of you.',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                      const SizedBox(height: 12),
                      PressScale(
                        onTap: _openCoach,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: metalPrimary(c),
                          child: Text(
                            'Ask coach',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.ctaInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (d.canStart && _location == 'gym')
                  MetalBtn(
                    label: _starting
                        ? 'Opening session...'
                        : 'Start / resume session',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => _startSession(d),
                  )
                else if (_location == 'gym' || d.isRestDay)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: metalWell(c),
                    child: Text(
                      d.isRestDay
                          ? 'Rest Day - Take time to recover.'
                          : d.moves.isEmpty
                          ? 'This saved day has no exercises yet.'
                          : 'A prescribed exercise is unavailable. Have the plan corrected before starting.',
                      style: TextStyle(color: c.muted),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegBar extends StatelessWidget {
  const _SegBar({
    required this.c,
    required this.index,
    required this.labels,
    required this.onTap,
  });
  final ArcColors c;
  final int index;
  final List<String> labels;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: metalWell(c),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == index;
          return Expanded(
            child: PressScale(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: ArcMotion.base,
                curve: ArcMotion.enter,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? c.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: on ? c.ink : c.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.c,
    required this.region,
    required this.expanded,
    required this.onTap,
  });
  final ArcColors c;
  final WorkoutRegion region;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: ArcMotion.base,
        curve: ArcMotion.enter,
        decoration: metalPanel(c, glow: expanded),
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            '${region.moves.length} prescribed exercises',
                            style: TextStyle(fontSize: 12, color: c.faint),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: ArcMotion.base,
                      curve: ArcMotion.enter,
                      child: Icon(Icons.chevron_right, color: c.faint),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: ArcMotion.base,
              curve: ArcMotion.enter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          for (var i = 0; i < region.moves.length; i++)
                            FadeSlideIn(
                              index: i,
                              delayStep: const Duration(milliseconds: 40),
                              dy: 8,
                              child: _MoveRow(c: c, move: region.moves[i]),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.c, required this.move});
  final ArcColors c;
  final WorkoutMove move;

  void _showGif(BuildContext context) {
    showExerciseDetails(
      context,
      name: move.name,
      target: move.primaryTarget,
      equipment: move.machine,
      instructions: move.instructions,
      mediaPath: move.gifPath ?? move.gifUrl,
      exerciseId: move.exerciseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGif(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: metalWell(c),
        child: Row(
          children: [
            PressScale(
              onTap: () => _showGif(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.raised,
                      Color.lerp(c.raised, Colors.black, 0.2)!,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded, color: c.ink, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    move.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  if (move.notes?.isNotEmpty == true)
                    Text(move.notes!, style: TextStyle(color: c.muted)),
                  Text(
                    '${move.machine} · ${move.scheme} · ${move.restLabel}',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
