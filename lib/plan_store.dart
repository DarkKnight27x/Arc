import 'package:flutter/foundation.dart';

class PlanSnapshot {
  const PlanSnapshot({
    required this.trainTitle,
    required this.trainMeta,
    required this.eatDinner,
    required this.todayLine,
    required this.chips,
    required this.receiptTitle,
    required this.receiptSession,
    required this.receiptIntensity,
    this.trainRegions = const [],
    this.injuredRegions = const [],
  });

  final String trainTitle;
  final String trainMeta;
  final String eatDinner;
  final String todayLine;
  final List<String> chips;
  final String receiptTitle;
  final String receiptSession;
  final String receiptIntensity;
  final List<String> trainRegions;
  final List<String> injuredRegions;
}

const planDefault = PlanSnapshot(
  trainTitle: '35 min · full-body',
  trainMeta: 'Home · Strength, steady breathing, no jumping',
  eatDinner: 'Egg bhurji + 1 roti + salad',
  todayLine: 'Today is a controlled full-body session.',
  chips: ['Lose fat', 'Surgery-prep caution'],
  receiptTitle: 'Built from your Thread',
  receiptSession: '4 days · 30–45 min',
  receiptIntensity: 'Low impact while surgery-prep is on',
  trainRegions: ['chest', 'arm', 'shoulder', 'core', 'thigh'],
  injuredRegions: [],
);

const planKnee = PlanSnapshot(
  trainTitle: '25 min · upper + core',
  trainMeta: 'Seated / standing · No squat, lunge, or floor impact',
  eatDinner: 'Dal + rice + curd · skip long standing at the stove',
  todayLine: 'Knee is protected. Upper body stays; legs unload.',
  chips: ['Lose fat', 'Surgery-prep caution', 'Knee protected'],
  receiptTitle: 'Knee protected — week rewritten',
  receiptSession: 'Upper + core · 25 min',
  receiptIntensity: 'No squat / lunge / jump',
  trainRegions: ['chest', 'arm', 'shoulder', 'core'],
  injuredRegions: ['knee', 'thigh', 'calf', 'leg'],
);

const planBack = PlanSnapshot(
  trainTitle: '20 min · hinge-safe upper',
  trainMeta: 'Seated · No bend, twist, or floor sit-up',
  eatDinner: 'Khichdi + curd · eat supported, no long standing',
  todayLine: 'Back is protected. No flexion. Upper body stays light.',
  chips: ['Lose fat', 'Surgery-prep caution', 'Back protected'],
  receiptTitle: 'Back protected — week rewritten',
  receiptSession: 'Seated upper · 20 min',
  receiptIntensity: 'No bend / twist / sit-up',
  trainRegions: ['arm', 'shoulder', 'chest'],
  injuredRegions: ['back', 'spine', 'core', 'torso'],
);

final planStore = ValueNotifier<PlanSnapshot>(planDefault);

void applyPlanFromText(String text) {
  final t = text.toLowerCase();
  if (t.contains('knee')) {
    planStore.value = planKnee;
  } else if (t.contains('back') || t.contains('spine') || t.contains('lumbar')) {
    planStore.value = planBack;
  }
}