import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRow {
  const ProfileRow({
    required this.userId,
    this.displayName,
    this.avatarPath,
    this.onboardingComplete = false,
    this.accountType = 'client',
    this.userState,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fitnessGoal,
    this.experienceLevel,
    this.workoutLocation,
    this.sessionDurationMinutes,
    this.dietType,
  });

  final String userId;
  final String? displayName;
  final String? avatarPath;
  final bool onboardingComplete;
  final String accountType;
  final Map<String, dynamic>? userState;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? fitnessGoal;
  final String? experienceLevel;
  final String? workoutLocation;
  final int? sessionDurationMinutes;
  final String? dietType;
}

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  Future<ProfileRow?> fetchCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return fetch(userId);
  }

  Future<ProfileRow?> fetch(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;

    final dobValue = row['date_of_birth'];
    final heightValue = row['height_cm'];
    final weightValue = row['weight_kg'];
    final sessionValue = row['session_duration_minutes'];

    return ProfileRow(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String?,
      avatarPath: row['avatar_path'] as String?,
      onboardingComplete: row['onboarding_complete'] as bool? ?? false,
      accountType: (row['account_type'] as String?) ?? 'client',
      userState: row['user_state'] as Map<String, dynamic>?,
      dateOfBirth: dobValue == null ? null : DateTime.tryParse(dobValue.toString()),
      gender: row['gender'] as String?,
      heightCm: heightValue == null ? null : (heightValue as num).toDouble(),
      weightKg: weightValue == null ? null : (weightValue as num).toDouble(),
      fitnessGoal: row['fitness_goal'] as String?,
      experienceLevel: row['experience_level'] as String?,
      workoutLocation: row['workout_location'] as String?,
      sessionDurationMinutes: sessionValue == null ? null : (sessionValue as num).toInt(),
      dietType: row['diet_type'] as String?,
    );
  }

  Future<void> upsertClient({
    required String userId,
    String? displayName,
  }) {
    return _client.from('profiles').upsert({
      'user_id': userId,
      'display_name': displayName,
      'account_type': 'client',
      'onboarding_complete': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}