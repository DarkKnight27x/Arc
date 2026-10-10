import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'training_catalog_source.dart';
import 'training_plan_generator.dart';
import 'training_plan_models.dart';
import 'training_context_service.dart';

abstract interface class ArcPlanBuilderSource {
  Future<ProfileRow?> profile();
  Future<TrainingCatalog> catalog();
  Future<TrainingGenerationResult> generate(TrainingPlanConfig config);
}

/// All operations are reads. A preview never calls a persistence RPC.
class ArcPlanBuilderService implements ArcPlanBuilderSource {
  ArcPlanBuilderService(this.client);
  final SupabaseClient client;
  @override
  Future<ProfileRow?> profile() => ProfileService(client).fetchCurrentUser();
  @override
  Future<TrainingCatalog> catalog() =>
      SupabaseTrainingCatalogSource(client).load();
  @override
  Future<TrainingGenerationResult> generate(TrainingPlanConfig config) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) throw const AuthException('Sign in required');
    final context = await TrainingContextService(client).load();
    final current = await profile();
    final library = await catalog();
    if (client.auth.currentUser?.id != owner || current?.userId != owner) {
      throw const AuthException('Account changed');
    }
    return TrainingPlanGenerator().generate(
      TrainingPlanConfig(
        goal: config.goal,
        experience: config.experience,
        weekdays: config.weekdays,
        equipment: config.equipment,
        sessionMinutes: config.sessionMinutes,
        journeyDays: config.journeyDays,
        age: current!.ageAt(DateTime.now()) ?? 0,
        location: config.location,
        priorities: config.priorities,
        hasReportedLimitations:
            config.hasReportedLimitations || context.injuryWarning,
      ),
      library,
    );
  }
}

const suggestedTrainingWeekdays = <int, List<int>>{
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 4, 5],
  6: [1, 2, 3, 4, 5, 6],
};

TrainingGoal? profileTrainingGoal(String? value) =>
    switch (value?.trim().toLowerCase()) {
      'build muscle' => TrainingGoal.buildMuscle,
      'lose fat' => TrainingGoal.loseFat,
      'stay consistent' => TrainingGoal.consistency,
      _ => null,
    };
TrainingExperience? profileTrainingExperience(String? value) =>
    switch (value?.trim().toLowerCase()) {
      'beginner' => TrainingExperience.beginner,
      'intermediate' => TrainingExperience.intermediate,
      'advanced' => TrainingExperience.advanced,
      _ => null,
    };
