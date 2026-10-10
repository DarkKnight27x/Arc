import 'dart:async';
import 'dart:convert';

import 'package:arc/auth/auth_gate.dart';
import 'package:arc/auth/login_page.dart';
import 'package:arc/auth/onboarding_page.dart';
import 'package:arc/auth/signup_page.dart';
import 'package:arc/data/auth_service.dart';
import 'package:arc/data/onboarding_answers.dart';
import 'package:arc/data/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_test.dart' show testClient, testSession, testUser, testUserId;
import 'profile_widget_test.dart' show widgetClient;

const userB = '00000000-0000-0000-0000-000000000002';

OnboardingAnswers validAnswers() => OnboardingAnswers()
  ..goal = 'Build muscle'
  ..sex = 'Male'
  ..age = '25'
  ..heightCm = '175.5'
  ..weightKg = '70'
  ..level = 'Beginner'
  ..days = '3'
  ..diet = 'Veg'
  ..allergies = ['None'];

Map<String, dynamic> sessionJson(String id, {bool expired = false}) {
  final expiry = expired ? 1 : 4102444800;
  final jwt = base64Url
      .encode(utf8.encode(jsonEncode({'exp': expiry, 'sub': id})))
      .replaceAll('=', '');
  return {
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$jwt.test',
    'refresh_token': 'fixture-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': expiry,
    'user': testUser(id, 'Fixture'),
  };
}

class GateAuth extends AuthService {
  GateAuth(super.client);
  Session? identity;
  final events = StreamController<AuthState>.broadcast();
  Completer<AuthResponse>? recovery;
  @override
  Session? get session => identity;
  @override
  User? get user => identity?.user;
  @override
  Stream<AuthState> get onAuth => events.stream;
  void switchTo(String? id, {bool expired = false}) {
    identity = id == null
        ? null
        : Session.fromJson(sessionJson(id, expired: expired));
    events.add(
      AuthState(
        id == null ? AuthChangeEvent.signedOut : AuthChangeEvent.signedIn,
        identity,
      ),
    );
  }

  @override
  Future<AuthResponse> refresh() =>
      (recovery = Completer<AuthResponse>()).future;
  @override
  Future<void> logout() async => switchTo(null);
}

class GateProfiles extends ProfileService {
  GateProfiles(super.client, this.auth);
  final GateAuth auth;
  final loads = <(String, Completer<ProfileRow?>)>[];
  @override
  String? get currentUserId => auth.user?.id;
  @override
  Future<ProfileRow?> fetch(String userId) {
    final pending = Completer<ProfileRow?>();
    loads.add((userId, pending));
    return pending.future;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('required onboarding values reject malformed, nonfinite and out-of-range inputs', () {
    expect(validAnswers().completionPatch()['onboarding_complete'], true);
    for (final bad in ['', 'abc', 'NaN', 'Infinity', '-1', '251']) {
      expect(
        () => (validAnswers()..heightCm = bad).completionPatch(),
        throwsFormatException,
      );
    }
    for (final bad in ['', 'abc', '12', '121', '25.5', '32768']) {
      expect(
        () => (validAnswers()..age = bad).completionPatch(),
        throwsFormatException,
      );
    }
    expect(
      () => (validAnswers()..allergies = ['None', 'Nuts']).completionPatch(),
      throwsFormatException,
    );
    expect(
      () => (validAnswers()..diet = null).completionPatch(),
      throwsFormatException,
    );
    expect(
      () => (validAnswers()..weightKg = '0').completionPatch(),
      throwsFormatException,
    );
  });

  test('confirmation signup returns a user without a session and writes no profile', () async {
    final requests = <http.Request>[];
    final client = testClient((req) async {
      requests.add(req);
      expect(req.url.path, '/auth/v1/signup');
      return http.Response(jsonEncode(testUser(testUserId, 'New')), 200);
    });
    addTearDown(client.dispose);
    final response = await AuthService(client).signup(
      email: ' new@example.invalid ',
      password: 'fixture-password',
      displayName: ' New ',
    );
    expect(response.user?.id, testUserId);
    expect(response.session, isNull);
    expect(client.auth.currentSession, isNull);
    expect(requests, hasLength(1));
    final body = jsonDecode(requests.single.body);
    expect(body['email'], 'new@example.invalid');
    expect(body['data']['display_name'], 'New');
  });

  test('login restores SDK session; serialization recovers it and logout clears it', () async {
    final client = testClient(
      (req) async => req.url.path.endsWith('/logout')
          ? http.Response('', 204)
          : http.Response(jsonEncode(sessionJson(testUserId)), 200),
    );
    final restored = testClient((_) async => http.Response('', 500));
    addTearDown(client.dispose);
    addTearDown(restored.dispose);
    await AuthService(client).login(' fixture@example.invalid ', 'password');
    expect(client.auth.currentUser?.id, testUserId);
    await restored.auth.recoverSession(
      jsonEncode(client.auth.currentSession!.toJson()),
    );
    expect(restored.auth.currentUser?.id, testUserId);
    await AuthService(client).logout();
    expect(client.auth.currentSession, isNull);
  });

  for (final (code, message) in [
    ('invalid_credentials', 'Invalid login credentials'),
    ('user_already_exists', 'User already registered'),
  ]) {
    test('auth server rejection is surfaced: $code', () async {
      final client = testClient(
        (_) async =>
            http.Response(jsonEncode({'code': code, 'msg': message}), 400),
      );
      addTearDown(client.dispose);
      expect(
        AuthService(client).login('fixture@example.invalid', 'bad'),
        throwsA(isA<AuthException>()),
      );
      expect(
        AuthService(client).signup(
          email: 'fixture@example.invalid',
          password: 'password',
          displayName: 'Fixture',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  }

  test('onboarding saves all validated fields and requires returned owner/completion', () async {
    late Map<String, dynamic> written;
    final client = testClient((req) async {
      expect(req.method, 'PATCH');
      expect(req.url.queryParameters['user_id'], 'eq.$testUserId');
      expect(req.url.queryParameters['onboarding_complete'], 'eq.false');
      written = Map<String, dynamic>.from(jsonDecode(req.body));
      return http.Response(
        jsonEncode([
          {'user_id': testUserId, ...written},
        ]),
        200,
      );
    });
    addTearDown(client.dispose);
    await testSession(client);
    final saved = await ProfileService(client)
        .completeOnboarding(userId: testUserId, answers: validAnswers());
    expect(saved.onboardingComplete, true);
    expect(saved.age, 25);
    expect(written, validAnswers().completionPatch());
    expect(written.containsKey('user_id'), false);
  });

  test(
    'missing row cannot be treated as a successful onboarding save',
    () async {
      final client = testClient((_) async => http.Response('[]', 200));
      addTearDown(client.dispose);
      await testSession(client);
      expect(
        ProfileService(client)
            .completeOnboarding(userId: testUserId, answers: validAnswers()),
        throwsStateError,
      );
    },
  );

  test(
    'lost acknowledgement retry accepts only the identical completed profile',
    () async {
      var different = false;
      final client = testClient(
        (req) async => req.method == 'PATCH'
            ? http.Response('[]', 200)
            : http.Response(
                jsonEncode([
                  {
                    'user_id': testUserId,
                    ...validAnswers().completionPatch(),
                    if (different) 'age': 30,
                  },
                ]),
                200,
              ),
      );
      addTearDown(client.dispose);
      await testSession(client);
      final service = ProfileService(client);
      expect(
        (await service.completeOnboarding(
          userId: testUserId,
          answers: validAnswers(),
        )).onboardingComplete,
        true,
      );
      different = true;
      expect(
        service.completeOnboarding(userId: testUserId, answers: validAnswers()),
        throwsStateError,
      );
    },
  );

  test(
    'interrupted save fails and can retry; account switch rejects late success',
    () async {
      var fail = true;
      Completer<http.Response>? pending;
      final client = testClient((req) async {
        if (fail) throw http.ClientException('Fixture network interruption');
        if (pending != null) return pending.future;
        return http.Response(
          jsonEncode([
            {'user_id': testUserId, ...jsonDecode(req.body)},
          ]),
          200,
        );
      });
      addTearDown(client.dispose);
      await testSession(client);
      final service = ProfileService(client);
      await expectLater(
        service.completeOnboarding(userId: testUserId, answers: validAnswers()),
        throwsA(isA<http.ClientException>()),
      );
      fail = false;
      expect(
        (await service.completeOnboarding(
          userId: testUserId,
          answers: validAnswers(),
        )).onboardingComplete,
        true,
      );
      pending = Completer<http.Response>();
      final save = service.completeOnboarding(
        userId: testUserId,
        answers: validAnswers(),
      );
      final rejected = expectLater(save, throwsA(isA<AuthException>()));
      await testSession(client, id: userB);
      pending.complete(
        http.Response(
          jsonEncode([
            {'user_id': testUserId, ...validAnswers().completionPatch()},
          ]),
          200,
        ),
      );
      await rejected;
      expect(
        service.completeOnboarding(userId: testUserId, answers: validAnswers()),
        throwsA(isA<AuthException>()),
      );
    },
  );

  Future<(GateAuth, GateProfiles)> mountGate(
    WidgetTester tester, {
    String? id,
    bool expired = false,
    Widget? app,
  }) async {
    final client = await widgetClient(
      tester,
      (_) async => http.Response('[]', 200),
    );
    final auth = GateAuth(client)..switchTo(id, expired: expired);
    final profiles = GateProfiles(client, auth);
    addTearDown(
      () => tester.runAsync(() async {
        await auth.events.close();
        await client.dispose();
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          auth: auth,
          profiles: profiles,
          app: app ?? const Scaffold(body: Text('AUTHORIZED HOME')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (auth, profiles);
  }

  testWidgets(
    'no session routes to login; incomplete profile routes to onboarding',
    (tester) async {
      final (auth, profiles) = await mountGate(tester);
      expect(find.byType(LoginPage), findsOneWidget);
      auth.switchTo(testUserId);
      await tester.pump();
      await tester.pump();
      profiles.loads.last.$2.complete(const ProfileRow(userId: testUserId));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('AUTHORIZED HOME'), findsNothing);
    },
  );

  testWidgets(
    'missing profile and network errors fail closed; retry handles delayed availability',
    (tester) async {
      final (_, profiles) = await mountGate(tester, id: testUserId);
      profiles.loads.last.$2.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.text('AUTHORIZED HOME'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      profiles.loads.last.$2.completeError(Exception('Fixture offline'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your profile.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      profiles.loads.last.$2.complete(
        const ProfileRow(userId: testUserId, onboardingComplete: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('AUTHORIZED HOME'), findsOneWidget);
    },
  );

  testWidgets(
    'account switch cannot reuse prior completed profile or in-flight response',
    (tester) async {
      final (auth, profiles) = await mountGate(tester, id: testUserId);
      final old = profiles.loads.last.$2;
      auth.switchTo(userB);
      await tester.pump();
      await tester.pump();
      old.complete(
        const ProfileRow(userId: testUserId, onboardingComplete: true),
      );
      profiles.loads.last.$2.complete(const ProfileRow(userId: userB));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('AUTHORIZED HOME'), findsNothing);
      await tester.tap(find.text('Build muscle'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      auth.switchTo(testUserId);
      await tester.pump();
      await tester.pump();
      profiles.loads.last.$2.complete(const ProfileRow(userId: testUserId));
      await tester.pumpAndSettle();
      expect(find.text('What are you here for?'), findsOneWidget);
    },
  );

  testWidgets(
    'completed profile survives remount; logout removes pushed signed-in routes',
    (tester) async {
      final (auth, profiles) = await mountGate(
        tester,
        id: testUserId,
        app: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('PRIVATE ROUTE')),
                ),
              ),
              child: const Text('OPEN PRIVATE'),
            ),
          ),
        ),
      );
      profiles.loads.last.$2.complete(
        const ProfileRow(userId: testUserId, onboardingComplete: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN PRIVATE'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE ROUTE'), findsOneWidget);
      auth.switchTo(null);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('PRIVATE ROUTE'), findsNothing);
      auth.switchTo(testUserId);
      await tester.pump();
      await tester.pump();
      profiles.loads.last.$2.complete(
        const ProfileRow(userId: testUserId, onboardingComplete: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.text('OPEN PRIVATE'), findsOneWidget);
    },
  );

  testWidgets('expired session does not open Home before refresh succeeds', (
    tester,
  ) async {
    final (auth, profiles) = await mountGate(
      tester,
      id: testUserId,
      expired: true,
    );
    expect(profiles.loads, isEmpty);
    auth.recovery!.completeError(const AuthException('Refresh failed'));
    await tester.pumpAndSettle();
    expect(find.text('AUTHORIZED HOME'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    auth.switchTo(testUserId);
    auth.recovery!.complete(AuthResponse(session: auth.session));
    await tester.pump();
    await tester.pump();
    profiles.loads.last.$2.complete(
      const ProfileRow(userId: testUserId, onboardingComplete: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('AUTHORIZED HOME'), findsOneWidget);
  });

  testWidgets(
    'all onboarding steps retain answers after a failed save and complete only on success',
    (tester) async {
      var offline = true;
      var calls = 0;
      final client = await widgetClient(tester, (req) async {
        calls++;
        if (offline) throw http.ClientException('Fixture offline');
        return http.Response(
          jsonEncode([
            {'user_id': testUserId, ...jsonDecode(req.body)},
          ]),
          200,
        );
      });
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.runAsync(() => testSession(client));
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            userId: testUserId,
            service: ProfileService(client),
            onComplete: () => completed = true,
          ),
        ),
      );
      Future<void> next() async {
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Build muscle'));
      await next();
      await tester.tap(find.text('Male'));
      await next();
      await tester.enterText(find.byType(TextField), '121');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '25');
      await next();
      await tester.enterText(find.byType(TextField).at(0), 'NaN');
      await tester.enterText(find.byType(TextField).at(1), '70');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField).at(0), '175.5');
      await next();
      await tester.tap(find.text('Beginner'));
      await next();
      await tester.tap(find.text('3'));
      await next();
      await tester.tap(find.text('Veg'));
      await next();
      await tester.tap(find.text('None'));
      await next();
      expect(calls, 0); // Intermediate steps never mark completion.
      await tester.tap(find.text('Enter Arc'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
      expect(completed, false);
      expect(
        find.textContaining('Could not save your profile'),
        findsOneWidget,
      );
      offline = false;
      await tester.tap(find.text('Enter Arc'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
      expect(completed, true);
      expect(calls, 2);
    },
  );

  testWidgets(
    'signup no-session guidance and late login error do not navigate or crash',
    (tester) async {
      final pending = Completer<http.Response>();
      final client = await widgetClient(
        tester,
        (req) async => req.url.path.endsWith('/signup')
            ? http.Response(jsonEncode(testUser(testUserId, 'New')), 200)
            : pending.future,
      );
      addTearDown(() => tester.runAsync(client.dispose));
      var entered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SignupPage(
            auth: AuthService(client),
            onDone: () => entered = true,
            onHaveAccount: () {},
          ),
        ),
      );
      final fields = find.byType(TextField);
      for (var i = 0; i < 4; i++) {
        await tester.enterText(
          fields.at(i),
          ['New', 'new@example.invalid', 'password123', 'password123'][i],
        );
      }
      final signupButton = find.text('Create account');
      await tester.scrollUntilVisible(
        signupButton,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(signupButton);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('verification link'), findsOneWidget);
      expect(entered, false);
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            auth: AuthService(client),
            onLoggedIn: () => entered = true,
            onCreateAccount: () {},
            onForgot: () {},
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'new@example.invalid',
      );
      await tester.enterText(find.byType(TextField).at(1), 'bad');
      await tester.tap(find.textContaining('Continue'));
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      pending.complete(
        http.Response('{"msg":"Invalid login credentials"}', 400),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(entered, false);
    },
  );
}
