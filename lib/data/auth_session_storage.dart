import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_diagnostics.dart';

/// Keep the SDK's SharedPreferences format/key while preventing a delayed
/// startup read from restoring the identity that has just signed out.
class AuthSessionStorage extends SharedPreferencesLocalStorage {
  AuthSessionStorage({
    required super.persistSessionKey,
    required this.readSession,
  });
  final Session? Function() readSession;
  bool _initializing = true;

  void finishInitialization() => _initializing = false;

  @override
  Future<void> initialize() =>
      AuthDiagnostics.trace(AuthStage.storageInitialize, super.initialize);

  @override
  Future<void> persistSession(String persistSessionString) =>
      AuthDiagnostics.trace(
        AuthStage.storageWrite,
        () => super.persistSession(persistSessionString),
      );

  @override
  Future<void> removePersistedSession() => AuthDiagnostics.trace(
    AuthStage.storageClear,
    super.removePersistedSession,
  );

  @override
  Future<String?> accessToken() async {
    final before = readSession();
    // Only initialization may restore a persisted session without a current
    // identity. The SDK's subsequent background recovery must respect logout.
    if (!_initializing && before == null) return null;
    final persisted = await AuthDiagnostics.trace(
      AuthStage.storageRead,
      super.accessToken,
    );
    return identical(before, readSession()) ? persisted : null;
  }
}
