import 'dart:convert';

import 'package:arc/data/auth_service.dart';
import 'package:arc/data/auth_diagnostics.dart';
import 'package:arc/data/auth_session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_onboarding_test.dart' show sessionJson;
import 'profile_test.dart' show testUserId;

class FailingWriteStorage extends EmptyLocalStorage {
  @override
  Future<void> persistSession(String persistSessionString) =>
      AuthDiagnostics.trace(AuthStage.storageWrite, () async {
        throw PlatformException(
          code: 'fixture_write_failure',
          message: 'synthetic-private-storage-value',
        );
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SDK storage-write failure is independently logged and does not reject successful sign-in', () async {
    SharedPreferences.setMockInitialValues({});
    final transport = MockClient(
      (_) async => http.Response(jsonEncode(sessionJson(testUserId)), 200),
    );
    final logs = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await Supabase.initialize(
        url: 'https://storage-fixture.example.invalid',
        publishableKey: 'fixture-publishable-key',
        httpClient: transport,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          localStorage: FailingWriteStorage(),
          detectSessionInUri: false,
          autoRefreshToken: false,
        ),
      );
      final response = await AuthService(Supabase.instance.client)
          .login('fixture@example.invalid', 'fixture-password');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(response.session, isNotNull);
      expect(Supabase.instance.client.auth.currentUser?.id, testUserId);
      expect(
        logs.any(
          (line) =>
              line.contains('stage=storageWrite category=platform_storage'),
        ),
        true,
      );
      expect(logs.join(), isNot(contains('synthetic-private-storage-value')));
      expect(logs.join(), isNot(contains('fixture-password')));
    } finally {
      debugPrint = previous;
      await Supabase.instance.dispose();
      transport.close();
    }
  });
  test('guarded SDK storage persists, restores and respects immediate logout', () async {
    SharedPreferences.setMockInitialValues({});
    final transport = MockClient(
      (req) async => req.url.path.endsWith('/logout')
          ? http.Response('', 204)
          : http.Response(jsonEncode(sessionJson(testUserId)), 200),
    );
    Future<void> initialize() async {
      final storage = AuthSessionStorage(
        persistSessionKey: 'sb-auth-fixture-auth-token',
        readSession: () => Supabase.instance.client.auth.currentSession,
      );
      await Supabase.initialize(
        url: 'https://auth-fixture.example.invalid',
        publishableKey: 'fixture-publishable-key',
        httpClient: transport,
        // No platform deep links or refresh timers in this disposable fixture.
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          autoRefreshToken: false,
          localStorage: storage,
        ),
      );
      storage.finishInitialization();
    }

    await initialize();
    addTearDown(() async {
      await Supabase.instance.dispose();
      transport.close();
    });
    expect(Supabase.instance.client.auth.currentSession, isNull);
    await AuthService(Supabase.instance.client)
        .login('fixture@example.invalid', 'fixture-password');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sb-auth-fixture-auth-token'), isNotNull);
    await Supabase.instance.dispose();
    await initialize();
    expect(Supabase.instance.client.auth.currentUser?.id, testUserId);
    await AuthService(Supabase.instance.client).logout();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(prefs.containsKey('sb-auth-fixture-auth-token'), false);
  });
}
