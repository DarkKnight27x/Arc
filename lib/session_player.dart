import 'injury_mode.dart';

import 'dart:async';

import 'data/workout_session.dart';
import 'data/workout_session_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/workout_models.dart';
import 'theme_ctrl.dart';
import 'widgets/exercise_media.dart';
import 'widgets/health_visuals.dart';

class SessionPlayer extends StatefulWidget {
  const SessionPlayer({
    super.key,
    required this.session,
    required this.service,
  });

  final WorkoutSession session;
  final WorkoutSessionService service;
  String get dayTitle => session.dayTitle;
  List<WorkoutMove> get exercises => session.exercises;

  @override
  State<SessionPlayer> createState() => _SessionPlayerState();
}

class _SessionPlayerState extends State<SessionPlayer> {
  int get _currentIndex => widget.session.currentIndex;
  set _currentIndex(int value) {
    if (value != widget.session.currentIndex) widget.session.revision++;
    widget.session.currentIndex = value;
  }

  bool _saving = false;
  bool _closing = false;
  bool _allowPop = false;
  String _saveMessage = 'Saving session...';
  Future<void> _saveQueue = Future.value();
  Future<void> _draftQueue = Future.value();
  bool _resting = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = widget.service.client.auth.onAuthStateChange.listen((
      _,
    ) {
      if (mounted) setState(() {});
    });
    unawaited(_save());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _save() async {
    var success = false;
    // Capture immutable snapshots and serialize writes to prevent old saves
    // overwriting newer set toggles or a terminal session on slow networks.
    final snapshot = WorkoutSession.fromMap(widget.session.toMap());
    // Local progress must not wait behind a slow or unavailable network.
    final draftSaved = _draftQueue.then(
      (_) => widget.service.saveDraft(snapshot),
    );
    _draftQueue = draftSaved.catchError((Object error) {});
    _saveQueue = _saveQueue.then((_) async {
      if (mounted) {
        setState(() {
          _saving = true;
          _saveMessage = 'Saving...';
        });
      }
      try {
        await draftSaved;
        await widget.service.save(snapshot, writeDraft: false);
        widget.session.baseRevision = snapshot.revision;
        success = true;
        if (mounted) setState(() => _saveMessage = 'Saved to your account');
      } catch (e) {
        if (mounted) {
          setState(
            () => _saveMessage = e is SessionPersistenceException
                ? e.message
                : 'Save failed. Keep this session open and retry.',
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
    await _saveQueue;
    return success;
  }

  Future<void> _leave() async {
    if (_closing) return;
    _closing = true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text(
          'Keep your progress to resume later, or record this session as discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _closing = false;
    if (!mounted || action == null) return;
    if (action == 'discard') {
      if (widget.session.status == WorkoutSessionStatus.inProgress) {
        widget.session.finish(discard: true);
      }
      final saved = await _save();
      if (mounted) {
        setState(() => _allowPop = saved);
        if (saved) Navigator.of(context).pop();
      }
      return; // A failed cloud discard remains reviewable and retryable.
    }
    try {
      await _draftQueue;
      await widget.service.saveDraft(widget.session);
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _saveMessage = 'Could not keep the draft. Retry before leaving.',
        );
      }
    }
  }

  void _next() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() => _currentIndex++);
      unawaited(_save());
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      unawaited(_save());
    }
  }

  Future<void> _finish() async {
    if (_closing || _saving) return;
    _closing = true;
    final session = widget.session;
    if (session.status == WorkoutSessionStatus.inProgress) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            session.allComplete
                ? 'Complete session?'
                : 'Finish partially completed?',
          ),
          content: Text(
            '${session.doneSets} of ${session.totalSets} sets checked. Unchecked sets remain incomplete.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(session.allComplete ? 'Complete' : 'Finish partial'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) {
        _closing = false;
        return;
      }
      session.finish();
      setState(() => _resting = false);
    }
    final saved = await _save();
    _closing = false;
    if (!mounted || !saved) return;
    final message = switch (session.outcome) {
      'completed' => 'Completed session saved.',
      'partial' => 'Partially completed session saved.',
      _ => 'Discarded session recorded.',
    };
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleSet(int index) {
    if (widget.session.status != WorkoutSessionStatus.inProgress) return;
    HapticFeedback.mediumImpact();
    setState(() {
      widget.session.toggle(_currentIndex, index);
      _resting =
          widget.session.completion[_currentIndex][index] &&
          widget.exercises[_currentIndex].timerSeconds > 0;
    });
    unawaited(_save());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, _, _) {
        final c = ArcColors.of(context);
        if (widget.service.client.auth.currentUser?.id !=
            widget.session.userId) {
          return Scaffold(
            backgroundColor: c.page,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your account changed. Sign in again to resume this session.',
                      style: TextStyle(color: c.ink),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final ex = widget.exercises[_currentIndex];
        final sets = widget.session.completion[_currentIndex];

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_leave());
          },
          child: Scaffold(
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${widget.session.doneSets}/${widget.session.totalSets} sets checked. $_saveMessage',
                                    style: TextStyle(color: c.muted),
                                  ),
                                  if (widget.session.trainingLocation == 'home')
                                    Text(
                                      'Home alternative - ${widget.session.equipment.join(', ')} - ${widget.session.requestedMinutes == null ? 'Full available session' : '${widget.session.requestedMinutes} min budget'}',
                                      style: TextStyle(color: c.ink),
                                    ),
                                  ValueListenableBuilder<InjuryScript?>(
                                    valueListenable: InjuryMode.current,
                                    builder: (context, local, _) =>
                                        widget.session.injuryWarning ||
                                            local != null
                                        ? Text(
                                            'Reported discomfort: this workout has no injury clearance. Review Recover before continuing.',
                                            style: TextStyle(color: c.ink),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            unawaited(_save());
                                          },
                                    child: const Text('Retry save'),
                                  ),
                                  if (widget.session.status !=
                                      WorkoutSessionStatus.inProgress)
                                    Text(
                                      'Session ended: ${widget.session.outcome}. Retry saving or keep the draft.',
                                      style: TextStyle(color: c.ink),
                                    ),
                                ],
                              ),
                            ),
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
                  if (_resting) _restOverlay(c),
                ],
              ),
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
            onPressed: _leave,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.dayTitle.toUpperCase()} - ${widget.session.trainingLocation.toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
          ),
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
            ExerciseMedia(
              key: ValueKey(ex.exerciseId ?? ex.id),
              path: ex.gifPath ?? ex.gifUrl,
              exerciseId: ex.exerciseId,
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
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
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
                        color: Colors.white.withValues(alpha: 0.7),
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
          '${ex.scheme} · ${ex.restLabel}',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: c.faint,
          ),
        ),
        if (ex.notes?.isNotEmpty == true)
          Text(ex.notes!, style: TextStyle(color: c.muted)),
        for (final instruction in ex.instructions)
          Text(instruction, style: TextStyle(color: c.muted)),
        const SizedBox(height: 12),
        for (int i = 0; i < sets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SetRow(
              index: i + 1,
              reps: ex.reps ?? 'Unspecified',
              done: sets[i],
              c: c,
              onTap: () => _toggleSet(i),
            ),
          ),
      ],
    );
  }

  Widget _navigationBar(ArcColors c) {
    final previous = _sessionButton(
      c,
      label: 'Previous',
      ghost: true,
      onTap: _prev,
    );
    final next = _sessionButton(
      c,
      label: widget.session.status != WorkoutSessionStatus.inProgress
          ? 'Save & close'
          : _currentIndex == widget.exercises.length - 1
          ? 'Finish'
          : 'Next Exercise',
      onTap: () {
        if (_saving || _closing) return;
        if (widget.session.status != WorkoutSessionStatus.inProgress) {
          unawaited(_finish());
        } else {
          _next();
        }
      },
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.shell,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 380) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [previous, const SizedBox(height: 8), next],
            );
          }
          return Row(
            children: [
              Expanded(child: previous),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: next),
            ],
          );
        },
      ),
    );
  }

  Widget _sessionButton(
    ArcColors c, {
    required String label,
    required VoidCallback onTap,
    bool ghost = false,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: ghost ? metalWell(c) : metalPrimary(c),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ghost ? c.ink : c.ctaInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _restOverlay(ArcColors c) {
    return Positioned.fill(
      child: Container(
        color: c.page.withValues(alpha: 0.96),
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
                duration: Duration(
                  seconds: widget.exercises[_currentIndex].timerSeconds,
                ),
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
        decoration: done ? metalWell(c, radius: 20) : metalPanel(c, radius: 20),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.brand : c.chip,
                border: Border.all(color: c.line.withValues(alpha: 0.3)),
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
                color: c.ink,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                reps,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text('reps', style: TextStyle(fontSize: 11, color: c.faint)),
          ],
        ),
      ),
    );
  }
}
