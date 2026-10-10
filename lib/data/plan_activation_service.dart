import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'training_plan_models.dart';
import 'workout_service.dart';

class ActivatedTrainingPlan {
  const ActivatedTrainingPlan(this.id, this.version, {this.status = 'active'});
  final String id;
  final int version;
  final String status;
}

enum PlanActivationFailure {
  conflict,
  unavailable,
  network,
  validation,
  account,
}

class PlanActivationException implements Exception {
  const PlanActivationException(this.failure);
  final PlanActivationFailure failure;
  String get message => switch (failure) {
    PlanActivationFailure.conflict => 'Your active plan changed or already exists. Return to Train to review it. Your existing plan was preserved.',
    PlanActivationFailure.unavailable =>
      'Plan activation is not available yet. Your preview is still here.',
    PlanActivationFailure.network => 'We could not confirm the response. Check your connection and retry this same preview safely.',
    PlanActivationFailure.validation => 'This preview could not be activated. Exercises or configuration may have changed. Edit your configuration and generate a fresh preview.',
    PlanActivationFailure.account => 'Your account changed. Please reopen Start My ARC from your signed-in account.',
  };
}

abstract interface class PlanActivationSource {
  Future<ActivatedTrainingPlan> activate(
    TrainingPlanPreview preview,
    String idempotencyKey, {
    ActivatedTrainingPlan? replace,
  });
}

/// Only the RPC writes plan rows. This projection intentionally omits private
/// profile data, exercise labels/snapshots and the client's canActivate flag.
Map<String, Object?> trainingActivationPayload(
  TrainingPlanPreview preview,
  String owner,
  String key, {
  ActivatedTrainingPlan? replace,
}) {
  final c = preview.config;
  return {
    'contract_version': 1,
    'user_id': owner,
    'idempotency_key': key,
    'plan_type': 'training',
    'rule_version': preview.ruleVersion,
    'generator_version': 'arc-2c-generator-v1',
    'block_weeks': preview.blockWeeks,
    'replace_active': replace != null,
    if (replace != null) ...{
      'expected_active_plan_id': replace.id,
      'expected_active_version': replace.version,
    },
    'config': {
      'goal': c.goal.name,
      'experience': c.experience.name,
      'location': c.location,
      'weekdays': c.weekdays,
      'equipment': c.equipment.toList()..sort(),
      'priorities': c.priorities.toList()..sort(),
      'session_minutes': c.sessionMinutes,
      'journey_days': c.journeyDays,
    },
    'days': [
      for (final day in preview.days)
        {
          'weekday': day.weekday,
          'title': day.split,
          'estimated_minutes': (day.estimatedSeconds / 60).ceil(),
          'exercises': [
            for (final (index, move) in day.exercises.indexed)
              {
                'exercise_id': move.exercise.id,
                'sort_order': index,
                'sets': move.sets,
                'reps': move.reps,
                'rest_seconds': move.restSeconds,
              },
          ],
        },
    ],
  };
}

class PlanActivationService implements PlanActivationSource {
  PlanActivationService(this.client);
  final SupabaseClient client;

  @override
  Future<ActivatedTrainingPlan> activate(
    TrainingPlanPreview preview,
    String idempotencyKey, {
    ActivatedTrainingPlan? replace,
  }) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw const PlanActivationException(PlanActivationFailure.account);
    }
    try {
      final raw = await client
          .rpc(
            'activate_generated_training_plan',
            params: {
              'payload': trainingActivationPayload(
                preview,
                owner,
                idempotencyKey,
                replace: replace,
              ),
            },
          )
          .timeout(const Duration(seconds: 30));
      if (owner != client.auth.currentUser?.id) {
        throw const PlanActivationException(PlanActivationFailure.account);
      }
      if (raw is! Map ||
          raw['plan_id'] is! String ||
          !stableExerciseId(raw['plan_id'] as String) ||
          raw['version'] is! int ||
          (raw['version'] as int) < 1 ||
          !{'active', 'archived'}.contains(raw['status'])) {
        throw const PlanActivationException(PlanActivationFailure.unavailable);
      }
      final activated = ActivatedTrainingPlan(
        raw['plan_id'] as String,
        raw['version'] as int,
        status: raw['status'] as String,
      );
      WorkoutService.invalidate(owner);
      return activated;
    } on PlanActivationException {
      rethrow;
    } on TimeoutException {
      throw const PlanActivationException(PlanActivationFailure.network);
    } on http.ClientException {
      throw const PlanActivationException(PlanActivationFailure.network);
    } on PostgrestException catch (e) {
      throw PlanActivationException(switch (e.code) {
        'PT409' || '23505' => PlanActivationFailure.conflict,
        '22023' ||
        '22P02' ||
        '23503' ||
        '23514' => PlanActivationFailure.validation,
        '42501' =>
          {
                'ARC_AUTH_REQUIRED',
                'ARC_OWNER_MISMATCH',
                'ARC_PROFILE_REQUIRED',
              }.contains(e.message)
              ? PlanActivationFailure.account
              : PlanActivationFailure.unavailable,
        'PGRST301' || 'PGRST302' || 'PGRST303' => PlanActivationFailure.account,
        'PGRST202' || '42883' => PlanActivationFailure.unavailable,
        '40001' ||
        '55P03' ||
        '57014' ||
        'PGRST000' ||
        'PGRST001' ||
        'PGRST002' ||
        'PGRST003' ||
        '502' ||
        '503' ||
        '504' => PlanActivationFailure.network,
        _ => PlanActivationFailure.unavailable,
      });
    } on AuthException {
      throw const PlanActivationException(PlanActivationFailure.account);
    } catch (e) {
      if ([
        'SocketException',
        'HandshakeException',
        'HttpException',
      ].contains(e.runtimeType.toString())) {
        throw const PlanActivationException(PlanActivationFailure.network);
      }
      throw const PlanActivationException(PlanActivationFailure.unavailable);
    }
  }
}
