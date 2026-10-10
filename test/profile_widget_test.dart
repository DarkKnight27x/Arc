import 'dart:async';

import 'package:arc/data/profile_service.dart';
import 'package:arc/profile_edit_page.dart';
import 'package:arc/theme_ctrl.dart';
import 'package:arc/you_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_test.dart' show testClient, testSession, testUserId;

// Supabase starts a JSON isolate. Construct it outside the fake widget clock
// so its initialization and disposal futures can finish normally.
Future<SupabaseClient> widgetClient(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler,
) async => (await tester.runAsync(() async {
  final client = testClient(handler);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return client;
}))!;

class ProfileFixture extends ProfileService {
  ProfileFixture(super.client);
  String? identity = testUserId;
  final events = StreamController<AuthState>.broadcast();
  final pending = <Completer<ProfileRow?>>[];
  int loads = 0;
  @override
  String? get currentUserId => identity;
  @override
  Stream<AuthState> get authChanges => events.stream;
  @override
  Future<ProfileRow?> fetchCurrentUser() {
    loads++;
    final request = Completer<ProfileRow?>();
    pending.add(request);
    return request.future;
  }
}

Widget testApp(Widget child, {double scale = 1}) => MaterialApp(
  theme: ThemeData(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    themeCtrl.value = ThemeMode.dark;
  });
  tearDown(() {
    themeCtrl.value = ThemeMode.dark;
  });

  testWidgets(
    'tab activation fetches once; invalidation refreshes without build fetches',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => http.Response('[]', 200),
      );
      final service = ProfileFixture(client);
      addTearDown(
        () => tester.runAsync(() async {
          await client.dispose();
        }),
      );
      addTearDown(() async {
        await service.events.close();
      });
      await tester.pumpWidget(
        testApp(YouPage(isActive: false, service: service)),
      );
      expect(service.loads, 0);
      await tester.pumpWidget(testApp(YouPage(service: service)));
      expect(service.loads, 1);
      service.pending.last.complete(
        const ProfileRow(userId: testUserId, displayName: 'Current profile'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current profile'), findsOneWidget);
      await tester.pumpWidget(testApp(YouPage(service: service)));
      expect(service.loads, 1);
      ProfileService.changes.value++;
      expect(service.loads, 2);
      service.pending.last.complete(
        const ProfileRow(userId: testUserId, displayName: 'Edited profile'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edited profile'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'account switch clears identity and rejects stale fetch completion',
    (tester) async {
      final client = await widgetClient(
        tester,
        (_) async => http.Response('[]', 200),
      );
      final service = ProfileFixture(client);
      addTearDown(
        () => tester.runAsync(() async {
          await client.dispose();
        }),
      );
      addTearDown(() async {
        await service.events.close();
      });
      await tester.pumpWidget(testApp(YouPage(service: service)));
      service.pending.first.complete(
        const ProfileRow(userId: testUserId, displayName: 'Previous account'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Previous account'), findsOneWidget);
      ProfileService.changes.value++;
      final oldRequest = service.pending.last;
      service.identity = 'second-user';
      service.events.add(const AuthState(AuthChangeEvent.signedOut, null));
      await tester.pump();
      expect(find.text('Previous account'), findsNothing);
      oldRequest.complete(
        const ProfileRow(userId: testUserId, displayName: 'Stale result'),
      );
      await tester.pump();
      expect(find.text('Stale result'), findsNothing);
      service.pending.last.complete(
        const ProfileRow(userId: 'second-user', displayName: 'Second account'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Second account'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets(
      'editor fits narrow screen with keyboard and large text in $mode',
      (tester) async {
        themeCtrl.value = mode;
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = await widgetClient(
          tester,
          (_) async => http.Response('[]', 200),
        );
        addTearDown(
          () => tester.runAsync(() async {
            await client.dispose();
          }),
        );
        await testSession(client);
        await tester.pumpWidget(
          testApp(
            ProfileEditPage(
              profile: const ProfileRow(
                userId: testUserId,
                displayName:
                    'A very long real profile name that should wrap safely',
                age: 29,
              ),
              service: ProfileService(client),
            ),
            scale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(
          field.style?.color,
          mode == ThemeMode.dark ? ArcColors.dark.ink : ArcColors.cream.ink,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        await tester.ensureVisible(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('name validation remains active after scrolling to Save', (
    tester,
  ) async {
    var writes = 0;
    final client = await widgetClient(tester, (_) async {
      writes++;
      return http.Response('[]', 200);
    });
    addTearDown(
      () => tester.runAsync(() async {
        await client.dispose();
      }),
    );
    await testSession(client);
    await tester.pumpWidget(
      testApp(
        ProfileEditPage(
          profile: const ProfileRow(userId: testUserId),
          service: ProfileService(client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Enter your name.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
