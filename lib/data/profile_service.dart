import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_validation.dart';
import 'onboarding_answers.dart';

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
    this.age,
    this.trainDays,
    this.allergies = const [],
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
  final int? age;
  final int? trainDays;
  final List<String> allergies;

  factory ProfileRow.fromMap(Map<String, dynamic> row) {
    double? number(dynamic value) {
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      return parsed?.isFinite == true ? parsed : null;
    }

    return ProfileRow(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String?,
      avatarPath: row['avatar_path'] as String?,
      onboardingComplete: row['onboarding_complete'] as bool? ?? false,
      accountType: row['account_type'] as String? ?? 'client',
      userState: row['user_state'] is Map
          ? Map<String, dynamic>.from(row['user_state'] as Map)
          : null,
      dateOfBirth: DateTime.tryParse(row['date_of_birth']?.toString() ?? ''),
      gender: row['gender'] as String?,
      heightCm: number(row['height_cm']),
      weightKg: number(row['weight_kg']),
      fitnessGoal: row['fitness_goal'] as String?,
      experienceLevel: row['experience_level'] as String?,
      workoutLocation: row['workout_location'] as String?,
      sessionDurationMinutes: number(row['session_duration_minutes'])?.toInt(),
      dietType: row['diet_type'] as String?,
      age: number(row['age'])?.toInt(),
      trainDays: number(row['train_days'])?.toInt(),
      allergies: List<String>.unmodifiable(
        (row['allergies'] as List?)?.whereType<String>() ?? const <String>[],
      ),
    );
  }

  int? ageAt(DateTime today) {
    if (age != null) return age; // Onboarding saves age, not date_of_birth.
    final dob = dateOfBirth;
    if (dob == null || dob.isAfter(today)) return null;
    final birthdayPending =
        today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day);
    return today.year - dob.year - (birthdayPending ? 1 : 0);
  }

  Map<String, dynamic> get editableFields => {
    'display_name': displayName,
    'fitness_goal': fitnessGoal,
    'experience_level': experienceLevel,
    'train_days': trainDays,
    'workout_location': workoutLocation,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'diet_type': dietType,
    'allergies': allergies,
    'age': age,
  };
}

class ProfileSaveResult {
  const ProfileSaveResult({
    required this.profile,
    required this.metadataSynced,
  });
  final ProfileRow profile;
  final bool metadataSynced;
}

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  /// An invalidation signal only: no shared cached identity or personal data.
  static final changes = ValueNotifier<int>(0);

  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

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

    return ProfileRow.fromMap(row);
  }

  Future<ProfileSaveResult> updateCurrentUser({
    required ProfileRow original,
    required Map<String, dynamic> patch,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || original.userId != userId) {
      throw const AuthException('Your session changed. Please sign in again.');
    }
    patch = Map<String, dynamic>.of(patch);
    ProfileValidation.validatePatch(patch);
    var saved = original;
    if (patch.isNotEmpty) {
      final row = await _client
          .from('profiles')
          .update(patch)
          .eq('user_id', userId)
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 20));
      if (row == null) {
        throw StateError(
          'No profile was updated. Refresh your profile and try again.',
        );
      }
      saved = ProfileRow.fromMap(row);
      if (_client.auth.currentUser?.id != userId) {
        throw const AuthException(
          'Your session changed. Please sign in again.',
        );
      }
      changes.value++;
    }

    // profiles is authoritative. Auth metadata is a secondary name mirror.
    final name = saved.displayName;
    if (name != null &&
        _client.auth.currentUser?.userMetadata?['display_name'] != name) {
      try {
        if (_client.auth.currentUser?.id != userId) {
          throw const AuthException(
            'Your session changed. Please sign in again.',
          );
        }
        final response = await _client.auth
            .updateUser(UserAttributes(data: {'display_name': name}))
            .timeout(const Duration(seconds: 20));
        if (_client.auth.currentUser?.id != userId ||
            response.user?.id != userId) {
          throw const AuthException(
            'Your session changed. Please sign in again.',
          );
        }
        if (response.user?.userMetadata?['display_name'] != name) {
          return ProfileSaveResult(profile: saved, metadataSynced: false);
        }
      } catch (_) {
        if (_client.auth.currentUser?.id != userId) rethrow;
        return ProfileSaveResult(profile: saved, metadataSynced: false);
      }
    }
    return ProfileSaveResult(profile: saved, metadataSynced: true);
  }

  Future<ProfileRow> completeOnboarding({
    required String userId,
    required OnboardingAnswers answers,
  }) async {
    void checkIdentity() {
      if (_client.auth.currentUser?.id != userId) {
        throw const AuthException(
          'Your session changed. Please sign in again.',
        );
      }
    }

    checkIdentity();
    final patch = answers.completionPatch();
    final row = await _client
        .from('profiles')
        .update(patch)
        .eq('user_id', userId)
        .eq('onboarding_complete', false)
        .select()
        .maybeSingle()
        .timeout(const Duration(seconds: 20));
    checkIdentity();
    // A retry after a lost acknowledgement can already be committed. Never
    // overwrite an existing completed profile or silently accept a missing row.
    final saved =
        row ??
        await _client
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 20));
    checkIdentity();
    if (saved == null ||
        saved['user_id'] != userId ||
        patch.entries.any((entry) {
          final actual = saved[entry.key];
          return entry.value is List
              ? actual is! List || !listEquals(actual, entry.value as List)
              : actual != entry.value;
        })) {
      throw StateError(
        'Your profile was not saved. Please retry or sign in again.',
      );
    }
    changes.value++;
    return ProfileRow.fromMap(saved);
  }
}
