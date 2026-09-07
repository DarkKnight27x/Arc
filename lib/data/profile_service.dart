import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRow {
  const ProfileRow({
    required this.userId,
    this.displayName,
    this.onboardingComplete = false,
    this.accountType = 'client',
  });

  final String userId;
  final String? displayName;
  final bool onboardingComplete;
  final String accountType;
}

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  Future<ProfileRow?> fetch(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ProfileRow(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String?,
      onboardingComplete: row['onboarding_complete'] as bool? ?? false,
      accountType: (row['account_type'] as String?) ?? 'client',
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