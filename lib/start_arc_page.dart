import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'anatomy_test_page.dart';
import 'data/arc_plan_builder_service.dart';
import 'data/profile_service.dart';
import 'data/plan_activation_service.dart';
import 'data/training_plan_models.dart';
import 'theme_ctrl.dart';
import 'widgets/arc_plan_theme.dart';
import 'widgets/exercise_media.dart';

typedef ArcPriorityPicker = Future<List<String>?> Function(
  BuildContext context,
  List<String> current,
);

class StartArcPage extends StatefulWidget {
  const StartArcPage({
    super.key,
    this.source,
    this.priorityPicker,
    this.activation,
    this.onActivated,
  });
  final ArcPlanBuilderSource? source;
  final ArcPriorityPicker? priorityPicker;
  final PlanActivationSource? activation;
  final ValueChanged<ActivatedTrainingPlan>? onActivated;
  @override
  State<StartArcPage> createState() => _StartArcPageState();
}

class _StartArcPageState extends State<StartArcPage> {
  late final ArcPlanBuilderSource source;
  StreamSubscription<AuthState>? auth;
  String? owner;
  ProfileRow? profile;
  bool loading = true, busy = false;
  String? error;
  int request = 0;
  int step = 0, journeyDays = 30;
  int? minutes;
  TrainingGoal? goal;
  TrainingExperience? experience;
  String? location;
  List<String> priorities = [];
  Set<int> weekdays = {};
  Set<String> equipment = {};
  Set<String> equipmentOptions = {};
  TrainingGenerationResult? result;
  bool activating = false;
  bool confirmed = false;
  String? activationKey;
  PlanActivationException? activationError;

  Future<void> confirm() async {
    if (activating || confirmed || result?.available != true) return;
    final preview = result!.preview!;
    if (preview.config.location != 'gym') return;
    final token = request;
    activationKey ??= const Uuid().v4();
    setState(() {
      activating = true;
      activationError = null;
    });
    try {
      final activated =
          await (widget.activation ??
                  PlanActivationService(Supabase.instance.client))
              .activate(preview, activationKey!)
              .timeout(const Duration(seconds: 35));
      if (!mounted || token != request) return;
      setState(() {
        activating = false;
        confirmed = true;
      });
      // PopScope must rebuild before the successful programmatic pop.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || token != request) return;
      if (widget.onActivated != null) {
        widget.onActivated!(activated);
      } else {
        Navigator.of(context).pop(activated);
      }
    } catch (e) {
      if (!mounted || token != request) return;
      setState(
        () => activationError = e is PlanActivationException
            ? e
            : PlanActivationException(
                e is TimeoutException
                    ? PlanActivationFailure.network
                    : PlanActivationFailure.unavailable,
              ),
      );
    } finally {
      if (mounted && token == request && activating) {
        setState(() => activating = false);
      }
    }
  }

  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  @override
  void initState() {
    super.initState();
    source = widget.source ?? ArcPlanBuilderService(Supabase.instance.client);
    if (widget.source == null) {
      owner = Supabase.instance.client.auth.currentUser?.id;
      auth = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (Supabase.instance.client.auth.currentUser?.id != owner && mounted) {
          request++;
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
    load();
  }

  @override
  void dispose() {
    request++;
    auth?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final token = ++request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await source.profile().timeout(const Duration(seconds: 20));
      final catalog = await source.catalog().timeout(
        const Duration(seconds: 25),
      );
      if (!mounted || token != request) return;
      if (p == null) throw StateError('Missing profile');
      if (catalog.issues.isNotEmpty) throw StateError('Unavailable catalog');
      setState(() {
        profile = p;
        goal = profileTrainingGoal(p.fitnessGoal);
        experience = profileTrainingExperience(p.experienceLevel);
        weekdays = (suggestedTrainingWeekdays[p.trainDays] ?? <int>[]).toSet();
        location =
            {'gym', 'home'}.contains(p.workoutLocation?.trim().toLowerCase())
            ? p.workoutLocation!.trim().toLowerCase()
            : null;
        minutes = p.sessionDurationMinutes;
        equipmentOptions = catalog.exercises
            .where((e) => e.usable)
            .expand((e) => e.metadata.requiredEquipment)
            .toSet();
        // Availability is explicitly selected; location does not imply ownership.
        equipment = equipmentOptions.contains('bodyweight')
            ? {'bodyweight'}
            : {};
        loading = false;
      });
    } catch (_) {
      if (mounted && token == request) {
        setState(() {
          loading = false;
          error =
              'We could not load your training preferences. Please try again.';
        });
      }
    }
  }

  Future<void> selectPriorities() async {
    if (busy || activating) return;
    final selected =
        await (widget.priorityPicker?.call(context, priorities) ??
            Navigator.of(context).push<List<String>>(
              MaterialPageRoute(
                builder: (_) => AnatomyTestPage(
                  prioritySelection: true,
                  initialPriorities: priorities,
                ),
              ),
            ));
    if (!mounted || selected == null) return;
    final normalized = selected.map(canonicalMuscle).toSet();
    if (normalized.length > 3) return;
    setState(() {
      priorities = normalized.toList();
      step = 1;
      result = null;
      activationKey = null;
      activationError = null;
    });
  }

  Future<void> generate() async {
    // Guard the callback too: a second tap can arrive before the disabled frame.
    if (busy || activating) return;
    if (goal == null ||
        experience == null ||
        location == null ||
        minutes == null ||
        weekdays.length < 2 ||
        weekdays.length > 6 ||
        equipment.isEmpty) {
      setState(
        () => error = 'Choose a goal, experience, location, duration, 2–6 days and available equipment.',
      );
      return;
    }
    final token = ++request;
    setState(() {
      busy = true;
      activationKey = null;
      activationError = null;
      error = null;
      result = null;
    });
    try {
      final generated = await source
          .generate(
            TrainingPlanConfig(
              goal: goal!,
              experience: experience!,
              weekdays: weekdays,
              equipment: equipment,
              sessionMinutes: minutes!,
              journeyDays: journeyDays,
              age: profile!.ageAt(DateTime.now()) ?? 0,
              priorities: priorities,
              location: location!,
              hasReportedLimitations:
                  profile!.userState?['injury'] != null &&
                  profile!.userState?['injury'] != false &&
                  profile!.userState?['injury'] != '',
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (mounted && token == request) {
        setState(() {
          result = generated;
          if (generated.issues.any(
            (i) => i.code == TrainingIssueCode.catalogUnavailable,
          )) {
            error = 'We could not load the exercise catalog. Please try again.';
            step = 1;
          } else {
            step = 2;
          }
        });
      }
    } catch (_) {
      if (mounted && token == request) {
        setState(() {
          step = 1;
          error = 'We could not generate your preview. Please try again.';
        });
      }
    } finally {
      if (mounted && token == request) setState(() => busy = false);
    }
  }

  Widget field<T>(
    String label,
    T? value,
    List<T> values,
    String Function(T) text,
    void Function(T?) onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: values.contains(value) ? value : null,
      style: TextStyle(
        color: busy ? ArcColors.of(context).muted : ArcColors.of(context).ink,
      ),
      dropdownColor: ArcColors.of(context).surface,
      iconEnabledColor: ArcColors.of(context).muted,
      iconDisabledColor: ArcColors.of(context).muted,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(text(v))))
          .toList(),
      onChanged: busy ? null : onChanged,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !activating,
    child: ArcPlanTheme(child: Builder(builder: _buildPage)),
  );

  Widget _buildPage(BuildContext context) {
    final c = ArcColors.of(context);
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        automaticallyImplyLeading: !activating,
        title: Text(
          step == 1
              ? 'Configure ARC'
              : step == 2
              ? 'Your ARC Preview'
              : 'Start My ARC',
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : busy
          ? Center(
              child: Semantics(
                liveRegion: true,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Generating your plan…'),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (activationError != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        activationError!.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (error != null && profile != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          TextButton(
                            onPressed: generate,
                            child: const Text('Retry generation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    // Each step gets a fresh viewport instead of inheriting the form's
                    // bottom offset and hiding the preview/unavailable heading.
                    key: ValueKey('arc-step-$step'),
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (profile == null) ...[
                        Text(error ?? 'Training preferences are unavailable.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: load,
                          child: const Text('Try again'),
                        ),
                      ] else if (step == 0) ...[
                        Text(
                          'Build your ARC',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Choose up to 3 priority muscles. ARC keeps balanced training and adds a little emphasis to your selections.',
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: selectPriorities,
                          child: const Text('Select Priority Muscles'),
                        ),
                      ] else if (step == 1) ...[
                        Text(
                          priorities.isEmpty
                              ? 'Balanced training · No extra priorities'
                              : 'Priorities: ${priorities.map(trainingLabel).join(', ')}',
                        ),
                        TextButton(
                          onPressed: busy ? null : selectPriorities,
                          child: const Text('Edit priorities'),
                        ),
                        const Text(
                          'Your existing profile preferences are filled in where available. These choices apply to this preview.',
                        ),
                        const SizedBox(height: 20),
                        field(
                          'Fitness goal',
                          goal,
                          TrainingGoal.values,
                          (g) => switch (g) {
                            TrainingGoal.buildMuscle => 'Build muscle',
                            TrainingGoal.loseFat => 'Lose fat',
                            TrainingGoal.consistency => 'Stay consistent',
                          },
                          (v) => setState(() => goal = v),
                        ),
                        field(
                          'Experience',
                          experience,
                          TrainingExperience.values,
                          (v) => trainingLabel(v.name),
                          (v) => setState(() => experience = v),
                        ),
                        field(
                          'Workout location',
                          location,
                          const ['gym', 'home'],
                          trainingLabel,
                          (v) => setState(() => location = v),
                        ),
                        field(
                          'Session duration',
                          minutes,
                          ({20, 30, 45, 60, 90, 120, ?minutes}.toList()
                            ..sort()),
                          (v) => '$v minutes',
                          (v) => setState(() => minutes = v),
                        ),
                        field(
                          'ARC journey',
                          journeyDays,
                          const [30, 60, 90],
                          (v) => '$v days',
                          (v) => setState(() => journeyDays = v!),
                        ),
                        const Text('Training days · Choose 2–6'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            7,
                            (i) => FilterChip(
                              label: Text(
                                dayNames[i],
                                style: TextStyle(
                                  color: busy
                                      ? c.muted
                                      : weekdays.contains(i + 1)
                                      ? c.page
                                      : c.ink,
                                ),
                              ),
                              checkmarkColor: busy ? c.muted : c.page,
                              selected: weekdays.contains(i + 1),
                              onSelected: busy
                                  ? null
                                  : (yes) => setState(() {
                                      yes
                                          ? weekdays.add(i + 1)
                                          : weekdays.remove(i + 1);
                                    }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Available equipment · Select what you can use',
                        ),
                        Wrap(
                          spacing: 8,
                          children: (equipmentOptions.toList()..sort())
                              .map(
                                (id) => FilterChip(
                                  label: Text(
                                    trainingLabel(id),
                                    style: TextStyle(
                                      color: busy
                                          ? c.muted
                                          : equipment.contains(id)
                                          ? c.page
                                          : c.ink,
                                    ),
                                  ),
                                  checkmarkColor: busy ? c.muted : c.page,
                                  selected: equipment.contains(id),
                                  onSelected: busy
                                      ? null
                                      : (yes) => setState(() {
                                          yes
                                              ? equipment.add(id)
                                              : equipment.remove(id);
                                        }),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Check the exercise setup before training. Equipment and time estimates may not describe every support surface. This preview does not prescribe weight increases.',
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy ? null : generate,
                          child: Text(busy ? 'Generating…' : 'Generate Plan'),
                        ),
                      ] else ...[
                        Text(
                          '$journeyDays-day ARC journey',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          priorities.isEmpty
                              ? 'Balanced training'
                              : 'Priority emphasis: ${priorities.map(trainingLabel).join(', ')}',
                        ),
                        const SizedBox(height: 20),
                        if (result!.available) ...[
                          Text(
                            'Your first ${result!.preview!.blockWeeks}-week block',
                          ),
                          const Text(
                            'Priorities receive one extra set while the rest of your body stays covered. Review your preview, then explicitly confirm to activate your plan.',
                          ),
                          const SizedBox(height: 16),
                          if (result!.preview!.config.location == 'gym')
                            FilledButton.icon(
                              key: const ValueKey('confirm-my-arc'),
                              onPressed: activating || confirmed
                                  ? null
                                  : confirm,
                              icon: activating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                activating
                                    ? 'Activating your ARC…'
                                    : confirmed
                                    ? 'ARC activated'
                                    : 'Confirm My ARC',
                              ),
                            )
                          else
                            const Text(
                              'Activation currently starts with a Gym plan. Home adaptation requires approved mappings. Edit configuration to choose Gym.',
                            ),
                          const SizedBox(height: 16),
                          for (final day in result!.preview!.week)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dayNames[(day['weekday'] as int) - 1]} · ${day['title']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (day['rest_day'] == false) ...[
                                      Text(
                                        'About ${day['estimated_minutes']} minutes · includes warm-up',
                                      ),
                                      for (final raw
                                          in day['exercises'] as List)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 64,
                                                height: 64,
                                                child: ExerciseMedia(
                                                  path:
                                                      (raw as Map)['gif_path'],
                                                  exerciseId:
                                                      raw['exercise_id']
                                                          as String?,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${raw['name']}\n${raw['sets']} sets × ${raw['reps']} reps · ${raw['rest_seconds']} sec rest',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ] else
                                      const Text('Rest and recover'),
                                  ],
                                ),
                              ),
                            ),
                        ] else ...[
                          const Icon(Icons.event_busy_outlined, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            "This training combination isn't available yet. ARC is still adding exercises for some required muscle groups, or your schedule and equipment need adjustment.",
                          ),
                          if (_missingAreas().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Required areas needing coverage: ${_missingAreas().map(trainingLabel).join(', ')}',
                              ),
                            ),
                          if (result!.issues.any(
                            (i) =>
                                i.code ==
                                TrainingIssueCode.safetyReviewRequired,
                          ))
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'This builder currently supports adults without reported limitations. Review your suitability before training.',
                              ),
                            ),
                          if (_missingPriorities().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Priorities needing coverage: ${_missingPriorities().map(trainingLabel).join(', ')}',
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Try editing your priorities, available equipment, session time or training days. ARC will keep the balanced baseline.',
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: activating
                              ? null
                              : () => setState(() {
                                  step = 1;
                                  result = null;
                                  activationKey = null;
                                  activationError = null;
                                }),
                          child: const Text('Edit configuration'),
                        ),
                        TextButton(
                          onPressed: activating ? null : selectPriorities,
                          child: const Text('Edit priorities'),
                        ),
                        if (!result!.available)
                          TextButton(
                            onPressed: generate,
                            child: const Text('Retry generation'),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Set<String> _missingPriorities() => result!.issues
      .where(
        (i) => {
          TrainingIssueCode.missingMuscles,
          TrainingIssueCode.unsupportedPriority,
          TrainingIssueCode.equipmentUnavailable,
          TrainingIssueCode.experienceUnavailable,
        }.contains(i.code),
      )
      .expand((i) => i.details)
      .toSet()
      .intersection(priorities.toSet());

  List<String> _missingAreas() =>
      (result!.issues
          .where((i) => i.code == TrainingIssueCode.missingMuscles)
          .expand((i) => i.details)
          .where((id) => !id.startsWith('day:'))
          .toSet()
          .toList()
        ..sort());
}
