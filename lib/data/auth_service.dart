import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class AuthService {
  AuthService(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileService _profiles;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;

  Stream<AuthState> get onAuth => _client.auth.onAuthStateChange;

  Future<AuthResponse> login(String email, String password) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
    final uid = res.user?.id;
    if (uid != null) {
      await _profiles.upsertClient(
        userId: uid,
        displayName: displayName.trim(),
      );
    }
    return res;
  }

  Future<void> sendReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> logout() => _client.auth.signOut();
}