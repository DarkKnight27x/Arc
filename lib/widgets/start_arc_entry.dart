import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/plan_activation_service.dart';
import '../data/workout_models.dart';
import '../data/workout_service.dart';
import '../data/workout_session.dart';
import '../data/workout_session_service.dart';
import '../start_arc_page.dart';
import '../theme_ctrl.dart';
import 'arc_plan_theme.dart';

/// Home's training view uses the same active-plan reader as Train.
/// Unknown/loading/failed reads never imply that the owner has no plan.
class StartArcEntry extends StatefulWidget {
  const StartArcEntry({
    super.key,
    this.client,
    this.workoutService,
    this.sessionService,
    this.now,
    this.isActive = true,
    this.openBuilder,
    this.onActivated,
    this.onOpenTrain,
    this.planBuilder,
  });
  final SupabaseClient? client;
  final WorkoutService? workoutService;
  final WorkoutSessionService? sessionService;
  final DateTime Function()? now;
  final bool isActive;
  final VoidCallback? openBuilder, onActivated, onOpenTrain;
  final WidgetBuilder? planBuilder;
  @override
  State<StartArcEntry> createState() => _StartArcEntryState();
}

class _StartArcEntryState extends State<StartArcEntry>
    with WidgetsBindingObserver {
  late final SupabaseClient client;
  late final WorkoutService workouts;
  late final WorkoutSessionService sessions;
  StreamSubscription<AuthState>? auth;
  String? owner;
  List<WorkoutDay>? days;
  WorkoutSessionStatus? status;
  DateTime? checkedDay;
  bool failed = false, historyFailed = false, loading = false;
  bool running = false, queued = false, scheduled = false;
  int request = 0;

  @override
  void initState() {
    super.initState();
    client =
        widget.client ??
        widget.workoutService?.client ??
        Supabase.instance.client;
    workouts = widget.workoutService ?? WorkoutService(client);
    sessions = widget.sessionService ?? WorkoutSessionService(client);
    assert(
      identical(workouts.client, client) && identical(sessions.client, client),
    );
    owner = client.auth.currentUser?.id;
    WidgetsBinding.instance.addObserver(this);
    WorkoutService.changes.addListener(planChanged);
    WorkoutSessionService.changes.addListener(sessionChanged);
    auth = client.auth.onAuthStateChange.listen((_) {
      if (!mounted) return;
      final next = client.auth.currentUser?.id;
      if (next == owner) return;
      request++;
      running = queued = false;
      setState(() {
        owner = next;
        days = null;
        status = null;
        failed = historyFailed = loading = false;
      });
      if (widget.isActive) refresh();
    });
    if (widget.isActive) refresh();
  }

  void planChanged() {
    if (WorkoutService.changes.value?.owner == client.auth.currentUser?.id) {
      scheduleRefresh();
    }
  }

  void sessionChanged() {
    if (WorkoutSessionService.changes.value?.owner ==
        client.auth.currentUser?.id) {
      scheduleRefresh();
    }
  }

  void scheduleRefresh() {
    if (!widget.isActive || scheduled) return;
    scheduled = true;
    scheduleMicrotask(() {
      scheduled = false;
      if (mounted && widget.isActive) refresh();
    });
  }

  @override
  void didUpdateWidget(covariant StartArcEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) scheduleRefresh();
  }

  @override
  void dispose() {
    request++;
    auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WorkoutService.changes.removeListener(planChanged);
    WorkoutSessionService.changes.removeListener(sessionChanged);
    super.dispose();
  }

  bool valid(int token, String user) =>
      mounted &&
      token == request &&
      owner == user &&
      client.auth.currentUser?.id == user;

  Future<void> refresh() async {
    final user = client.auth.currentUser?.id;
    if (user == null) return;
    if (running) {
      queued = true;
      return;
    }
    running = true;
    final token = ++request;
    final today = (widget.now ?? DateTime.now)();
    setState(() {
      loading = true;
      failed = historyFailed = false;
      days = null;
      status = null;
    });
    try {
      final result = await workouts.fetchWorkoutPlan();
      if (!valid(token, user)) return;
      final current = dayFor(result, today.weekday);
      WorkoutSessionStatus? savedStatus;
      bool historyError = false;
      if (current != null && !current.isRestDay) {
        try {
          savedStatus = await sessions.currentDayStatus(current.id, now: today);
        } catch (_) {
          historyError = true;
        }
      }
      if (!valid(token, user)) return;
      setState(() {
        days = result;
        status = savedStatus;
        checkedDay = today;
        historyFailed = historyError;
      });
    } catch (_) {
      if (valid(token, user)) setState(() => failed = true);
    } finally {
      if (valid(token, user)) {
        running = false;
        setState(() => loading = false);
        if (queued) {
          queued = false;
          scheduleRefresh();
        }
      }
    }
  }

  WorkoutDay? dayFor(List<WorkoutDay> week, int weekday) {
    for (final day in week) {
      if (day.weekday == weekday) return day;
    }
    return null;
  }

  Future<void> open() async {
    if (widget.openBuilder != null) {
      widget.openBuilder!();
      return;
    }
    final user = owner;
    final revision = WorkoutService.changes.value?.revision;
    final activated = await Navigator.of(context).push<ActivatedTrainingPlan>(
      MaterialPageRoute(
        builder: widget.planBuilder ?? (_) => const StartArcPage(),
      ),
    );
    if (!mounted || owner != user || client.auth.currentUser?.id != user) {
      return;
    }
    if (revision == WorkoutService.changes.value?.revision) {
      scheduleRefresh();
    }
    if (activated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activated.status == 'active'
                ? 'ARC activated. Your weekly plan is ready in Train.'
                : 'This ARC was previously activated. Train shows your current plan.',
          ),
        ),
      );
      widget.onActivated?.call();
    }
  }

  @override
  Widget build(BuildContext context) => ArcPlanTheme(child: _entry(context));

  Widget _entry(BuildContext context) {
    final c = ArcColors.of(context);
    if (owner == null || owner != client.auth.currentUser?.id) {
      return Text(
        'Sign in to see your training status.',
        style: TextStyle(color: c.muted),
      );
    }
    if (loading || (days == null && !failed)) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Checking your ARC…', style: TextStyle(color: c.muted)),
          ),
        ],
      );
    }
    if (failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your training status is unavailable. Please retry.',
            style: TextStyle(color: c.muted),
          ),
          TextButton(
            onPressed: refresh,
            child: const Text('Retry training plan check'),
          ),
        ],
      );
    }
    if (days!.isEmpty) {
      return FilledButton.icon(
        onPressed: open,
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Start My ARC'),
      );
    }
    final weekday = checkedDay!.weekday;
    final current = dayFor(days!, weekday);
    WorkoutDay? next;
    for (int offset = 1; offset <= 7; offset++) {
      final candidate = dayFor(days!, (weekday - 1 + offset) % 7 + 1);
      if (candidate != null && !candidate.isRestDay) {
        next = candidate;
        break;
      }
    }
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final isRest = current == null || current.isRestDay;
    final completion = historyFailed
        ? 'Workout status unavailable.'
        : switch (status) {
            WorkoutSessionStatus.completed => 'Workout completed today',
            WorkoutSessionStatus.inProgress => 'Workout in progress',
            WorkoutSessionStatus.abandoned => 'Session ended',
            null => 'Not completed today',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARC ACTIVE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRest ? 'Rest day' : current.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
        if (!isRest) ...[
          if (current.muscles.isNotEmpty || current.estimatedMinutes != null)
            Text(
              [
                current.muscles,
                if (current.estimatedMinutes != null)
                  '${current.estimatedMinutes} min',
              ].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(color: c.muted),
            ),
          const SizedBox(height: 6),
          Text(completion, style: TextStyle(color: c.muted)),
        ],
        if (next != null) ...[
          const SizedBox(height: 8),
          Text(
            'Next: ${next.title} · ${weekdays[next.weekday - 1]}',
            style: TextStyle(color: c.muted),
          ),
        ],
        if (historyFailed)
          TextButton(
            onPressed: refresh,
            child: const Text('Retry workout status'),
          ),
        if (widget.onOpenTrain != null)
          TextButton(
            onPressed: widget.onOpenTrain,
            child: const Text('Open Train'),
          ),
      ],
    );
  }
}
