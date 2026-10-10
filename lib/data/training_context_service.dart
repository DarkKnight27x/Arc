import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class TrainingContext {
  const TrainingContext({
    this.location = 'gym',
    this.minutes,
    this.injuryWarning = false,
    this.reportStatus = '',
    this.error,
  });
  final String location, reportStatus;
  final int? minutes;
  final bool injuryWarning;
  final String? error;
}

class TrainingContextService {
  TrainingContextService(this.client);
  final SupabaseClient client;
  Future<TrainingContext> load() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const TrainingContext();
    final profile = await ProfileService(client).fetchCurrentUser();
    final reports = await client
        .from('rehab_cases')
        .select('body_region,status')
        .eq('user_id', userId)
        .inFilter('status', ['active', 'improving', 'needs_review'])
        .timeout(const Duration(seconds: 20));
    if (client.auth.currentUser?.id != userId) {
      throw const AuthException('Your account changed.');
    }
    final state = profile?.userState ?? const <String, dynamic>{};
    final reported =
        state['injury'] != null &&
        state['injury'] != false &&
        state['injury'] != '';
    return TrainingContext(
      location: profile?.workoutLocation?.toLowerCase() == 'home'
          ? 'home'
          : 'gym',
      minutes: [15, 30].contains(profile?.sessionDurationMinutes)
          ? profile?.sessionDurationMinutes
          : null,
      injuryWarning: reports.isNotEmpty || reported,
      reportStatus: reports
          .map((r) => r['status'] as String)
          .toSet()
          .join(', '),
    );
  }
}
