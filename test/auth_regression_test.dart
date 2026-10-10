import 'dart:async';

import 'package:arc/auth/login_page.dart';
import 'package:arc/data/auth_diagnostics.dart';
import 'package:arc/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_test.dart' show testClient;
import 'profile_widget_test.dart' show widgetClient;

class LoginFailure extends AuthService {
  LoginFailure(super.client, this.problem);
  final Object problem;
  @override
  Future<AuthResponse> login(String email, String password) async =>
      throw problem;
}

class PendingLogin extends AuthService {
  PendingLogin(super.client);
  final pending = Completer<AuthResponse>();
  @override
  Future<AuthResponse> login(String email, String password) => pending.future;
}

void main() {
  test('diagnostics and messages omit secrets and retain safe auth/RLS metadata', () {
    const secret =
        'private-email secret-password secret-access-token secret-refresh-token private-profile-value';
    final problems = <Object>[
      const AuthException(
        secret,
        statusCode: '400',
        code: 'invalid_credentials',
      ),
      const PostgrestException(
        message: secret,
        code: '42501',
        details: secret,
        hint: secret,
      ),
      PlatformException(code: secret, message: secret, details: secret),
      http.ClientException(
        secret,
        Uri.parse('https://private.example.invalid/?token=secret'),
      ),
      const FormatException(secret, secret),
    ];
    for (final problem in problems) {
      final log = AuthDiagnostics.formatFailure(
        AuthStage.loginUi,
        problem,
        StackTrace.fromString(
          'private_path/$secret\n#1 package:arc/auth/login_page.dart:80:4',
        ),
      );
      expect(log, contains('stage=loginUi'));
      expect(log, contains('package:arc/auth/login_page.dart:80:4'));
      for (final marker in secret.split(' ')) {
        expect(log, isNot(contains(marker)));
        expect(AuthDiagnostics.message(problem), isNot(contains(marker)));
      }
    }
    expect(
      AuthDiagnostics.formatFailure(AuthStage.loginRequest, problems.first),
      contains('status=400 code=invalid_credentials'),
    );
    expect(
      AuthDiagnostics.formatFailure(AuthStage.profileLoad, problems[1]),
      contains('category=profile_api'),
    );
    expect(
      AuthDiagnostics.formatFailure(AuthStage.profileLoad, problems[1]),
      contains('code=42501'),
    );
  });

  test(
    'actual SDK classifies failed transport independently of profile/storage',
    () async {
      final client = testClient(
        (_) async =>
            throw http.ClientException('Failed host lookup: fixture.invalid'),
      );
      addTearDown(client.dispose);
      Object? caught;
      try {
        await AuthService(client)
            .login('fixture@example.invalid', 'fixture-password');
      } catch (error) {
        caught = error;
      }
      expect(caught, isA<AuthRetryableFetchException>());
      expect(AuthDiagnostics.category(caught!), 'network');
      expect(client.auth.currentSession, isNull);
    },
  );

  for (final (name, problem, expected) in <(String, Object, String)>[
    (
      'DNS transport',
      AuthRetryableFetchException(
        message: 'Failed host lookup: private.invalid',
      ),
      'Could not reach ARC.',
    ),
    (
      'direct network',
      http.ClientException('private-network-error'),
      'Could not reach ARC.',
    ),
    (
      'timeout',
      TimeoutException('private-transport-details'),
      'The request took too long.',
    ),
    (
      'storage',
      PlatformException(code: 'private-platform-code'),
      'Could not access local session storage.',
    ),
    (
      'invalid credentials',
      const AuthException(
        'private server body',
        statusCode: '400',
        code: 'invalid_credentials',
      ),
      'Check your email and password',
    ),
    (
      'response parsing',
      const FormatException('private-server-response'),
      'Could not sign in.',
    ),
  ]) {
    testWidgets('$name yields safe distinct UI and stage diagnostic', (
      tester,
    ) async {
      final client = await widgetClient(
        tester,
        (_) async => http.Response('', 500),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final logs = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        var entered = false;
        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(
              auth: LoginFailure(client, problem),
              onLoggedIn: () => entered = true,
              onCreateAccount: () {},
              onForgot: () {},
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextField).at(0),
          'fixture@example.invalid',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'fixture-password',
        );
        await tester.tap(find.textContaining('Continue'));
        await tester.pumpAndSettle();
        expect(find.textContaining(expected), findsOneWidget);
        expect(find.textContaining('Something went wrong'), findsNothing);
        expect(entered, false);
        expect(logs.where((s) => s.contains('stage=loginUi')), hasLength(1));
        expect(logs.join(), isNot(contains('fixture-password')));
        expect(logs.join(), isNot(contains('fixture@example.invalid')));
        expect(logs.join(), isNot(contains('private')));
      } finally {
        debugPrint = previous;
      }
    });
  }

  testWidgets(
    'the new 20-second UI timeout is explicit and does not invoke navigation',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => http.Response('', 500),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final auth = PendingLogin(client);
      var entered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            auth: auth,
            onLoggedIn: () => entered = true,
            onCreateAccount: () {},
            onForgot: () {},
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'fixture@example.invalid',
      );
      await tester.enterText(find.byType(TextField).at(1), 'fixture-password');
      await tester.tap(find.textContaining('Continue'));
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.textContaining('The request took too long'), findsOneWidget);
      expect(entered, false);
      auth.pending.complete(AuthResponse());
      await tester.pump();
      expect(entered, false);
    },
  );

  testWidgets(
    'navigation callback failure is not mislabeled as an auth failure',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => http.Response('', 500),
      );
      addTearDown(() => tester.runAsync(client.dispose));
      final auth = PendingLogin(client);
      final logs = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(
              auth: auth,
              onLoggedIn: () => throw StateError('private-navigation-context'),
              onCreateAccount: () {},
              onForgot: () {},
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextField).at(0),
          'fixture@example.invalid',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'fixture-password',
        );
        await tester.tap(find.textContaining('Continue'));
        auth.pending.complete(AuthResponse());
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Signed in, but could not open ARC'),
          findsOneWidget,
        );
        expect(logs.where((s) => s.contains('stage=navigation')), hasLength(1));
        expect(logs.where((s) => s.contains('stage=loginUi')), isEmpty);
      } finally {
        debugPrint = previous;
      }
    },
  );
}
