import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arc/data/profile_service.dart';
import 'package:arc/data/profile_validation.dart';

const testUserId = '00000000-0000-0000-0000-000000000001';

class FixturePkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

Map<String, dynamic> testUser(String id, String name) => {
  'id': id,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'profile-test@example.invalid',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': <String, dynamic>{},
  'user_metadata': {'display_name': name},
};

Future<void> testSession(
  SupabaseClient client, {
  String id = testUserId,
  String name = 'Original',
}) async {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'exp': 4102444800, 'sub': id})))
      .replaceAll('=', '');
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.test',
      'refresh_token': 'test-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': 4102444800,
      'user': testUser(id, name),
    }),
  );
}

SupabaseClient testClient(
  Future<http.Response> Function(http.Request) handler,
) => SupabaseClient(
  'https://profile-test.example.invalid',
  'test-publishable-key',
  httpClient: MockClient((request) async {
    final response = await handler(request);
    // PostgREST returns an object for singular PATCH requests, including
    // a 406 response for zero rows; reproduce that wire protocol locally.
    if (request.method == 'PATCH' && response.statusCode == 200) {
      final rows = jsonDecode(response.body);
      if (rows is List) {
        return rows.isEmpty
            ? http.Response(
                '{"code":"PGRST116","message":"No rows","details":"Results contain 0 rows"}',
                406,
                request: request,
              )
            : http.Response(jsonEncode(rows.single), 200, request: request);
      }
    }
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }),
  authOptions: AuthClientOptions(
    autoRefreshToken: false,
    pkceAsyncStorage: FixturePkceStorage(),
  ),
  postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
);

void main() {
  test('maps onboarding fields, numeric strings and nullable fields', () {
    final p = ProfileRow.fromMap({
      'user_id': testUserId,
      'age': 29,
      'train_days': 4,
      'allergies': ['Dairy', 'Nuts'],
      'height_cm': '178.5',
      'weight_kg': 76,
    });
    expect(p.age, 29);
    expect(p.trainDays, 4);
    expect(p.allergies, ['Dairy', 'Nuts']);
    expect(p.heightCm, 178.5);
    expect(p.weightKg, 76);
    expect(p.displayName, isNull);
    final empty = ProfileRow.fromMap({
      'user_id': testUserId,
      'allergies': null,
    });
    expect(empty.allergies, isEmpty);
    expect(empty.age, isNull);
    expect(empty.trainDays, isNull);
    expect(empty.onboardingComplete, false);
    expect(empty.editableFields['height_cm'], isNull);
  });

  test('saved age is authoritative, DOB is an accurate fallback', () {
    final dob = DateTime(2000, 10, 10);
    expect(
      ProfileRow(
        userId: testUserId,
        age: 30,
        dateOfBirth: dob,
      ).ageAt(DateTime(2026, 10, 9)),
      30,
    );
    expect(
      ProfileRow(
        userId: testUserId,
        dateOfBirth: dob,
      ).ageAt(DateTime(2026, 10, 9)),
      25,
    );
    expect(
      ProfileRow(
        userId: testUserId,
        dateOfBirth: dob,
      ).ageAt(DateTime(2026, 10, 10)),
      26,
    );
    expect(const ProfileRow(userId: testUserId).ageAt(DateTime.now()), isNull);
  });

  test('validation rejects unrealistic and nonfinite measurements', () {
    expect(ProfileValidation.name('  '), isNotNull);
    expect(ProfileValidation.name('Alex'), isNull);
    for (final field in ['height_cm', 'weight_kg', 'age', 'train_days']) {
      for (final value in ['-1', '0', 'NaN', 'Infinity', 'word', '999']) {
        expect(
          ProfileValidation.numeric(value, field),
          isNotNull,
          reason: '$field: $value',
        );
      }
      expect(ProfileValidation.numeric('', field), isNull);
    }
    expect(ProfileValidation.numeric('178.5', 'height_cm'), isNull);
    expect(ProfileValidation.numeric('3.5', 'train_days'), isNotNull);
    expect(ProfileValidation.numeric('29.5', 'age'), isNotNull);
    expect(
      () => ProfileValidation.validatePatch({'diet_type': 'Vegetarian'}),
      throwsArgumentError,
    );
    for (final diet in ProfileValidation.diets) {
      expect(
        () => ProfileValidation.validatePatch({'diet_type': diet}),
        returnsNormally,
      );
    }
    expect(
      () => ProfileValidation.validatePatch({
        'allergies': ['None', 'Nuts'],
      }),
      throwsArgumentError,
    );
    expect(
      () => ProfileValidation.validatePatch({'user_state': {}}),
      throwsArgumentError,
    );
  });

  test(
    'partial changes preserve untouched fields and ignore allergy ordering',
    () {
      final original = <String, dynamic>{
        ...const ProfileRow(
          userId: testUserId,
          displayName: 'Original',
          age: 29,
          allergies: ['Dairy', 'Nuts'],
        ).editableFields,
        'onboarding_complete': true,
        'user_state': {'injury': true},
        'gender': 'female',
      };
      expect(
        ProfileValidation.changedFields(original, {
          ...original,
          'display_name': 'Edited',
          'allergies': ['Nuts', 'Dairy'],
          'onboarding_complete': false,
        }),
        {'display_name': 'Edited'},
      );
      expect(original['user_state'], {'injury': true});
      expect(ProfileValidation.changedFields(original, {'weight_kg': 70}), {
        'weight_kg': 70,
      });
      expect(ProfileValidation.changedFields(original, {'age': null}), {
        'age': null,
      });
    },
  );

  test(
    'writes only the patch for authenticated ID and signals Home refresh',
    () async {
      final requests = <http.Request>[];
      final client = testClient((request) async {
        requests.add(request);
        if (request.method == 'PATCH') {
          return http.Response(
            jsonEncode([
              {
                'user_id': testUserId,
                'display_name': 'Edited',
                'age': 29,
                'onboarding_complete': true,
                'user_state': {'injury': true},
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(testUser(testUserId, 'Edited')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.dispose);
      await testSession(client);
      final changes = ProfileService.changes.value;
      final result = await ProfileService(client).updateCurrentUser(
        original: const ProfileRow(userId: testUserId, displayName: 'Original'),
        patch: {'display_name': 'Edited'},
      );
      expect(result.metadataSynced, true);
      expect(result.profile.age, 29);
      expect(result.profile.userState, {'injury': true});
      expect(result.profile.onboardingComplete, true);
      expect(ProfileService.changes.value, changes + 1);
      expect(requests.first.method, 'PATCH');
      expect(requests.first.url.queryParameters['user_id'], 'eq.$testUserId');
      expect(jsonDecode(requests.first.body), {'display_name': 'Edited'});
      expect(requests.last.url.path, '/auth/v1/user');
      expect(jsonDecode(requests.last.body)['data'], {
        'display_name': 'Edited',
      });
    },
  );

  test('metadata failure reports partial save; retry does not repeat profile write', () async {
    var failMetadata = true;
    var writes = 0;
    final client = testClient((request) async {
      if (request.method == 'PATCH') {
        writes++;
        return http.Response(
          jsonEncode([
            {'user_id': testUserId, 'display_name': 'Edited'},
          ]),
          200,
        );
      }
      return failMetadata
          ? http.Response('{"msg":"Unavailable"}', 503)
          : http.Response(jsonEncode(testUser(testUserId, 'Edited')), 200);
    });
    addTearDown(client.dispose);
    await testSession(client);
    final service = ProfileService(client);
    final first = await service.updateCurrentUser(
      original: const ProfileRow(userId: testUserId, displayName: 'Original'),
      patch: {'display_name': 'Edited'},
    );
    expect(first.metadataSynced, false);
    expect(first.profile.displayName, 'Edited');
    failMetadata = false;
    final retry = await service.updateCurrentUser(
      original: first.profile,
      patch: {},
    );
    expect(retry.metadataSynced, true);
    expect(writes, 1);
  });

  test(
    'absent session, mismatched identity and protected fields cause no request',
    () async {
      var requests = 0;
      final client = testClient((_) async {
        requests++;
        return http.Response('[]', 200);
      });
      addTearDown(client.dispose);
      final service = ProfileService(client);
      await expectLater(
        service.updateCurrentUser(
          original: const ProfileRow(userId: testUserId),
          patch: {'age': 30},
        ),
        throwsA(isA<AuthException>()),
      );
      await testSession(client);
      await expectLater(
        service.updateCurrentUser(
          original: const ProfileRow(userId: 'another-user'),
          patch: {'age': 30},
        ),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        service.updateCurrentUser(
          original: const ProfileRow(userId: testUserId),
          patch: {'onboarding_complete': false},
        ),
        throwsArgumentError,
      );
      expect(requests, 0);
    },
  );

  test(
    'zero updated rows never signals success or attempts metadata',
    () async {
      var requests = 0;
      final client = testClient((_) async {
        requests++;
        return http.Response('[]', 200);
      });
      addTearDown(client.dispose);
      await testSession(client);
      final changes = ProfileService.changes.value;
      await expectLater(
        ProfileService(client).updateCurrentUser(
          original: const ProfileRow(userId: testUserId),
          patch: {'display_name': 'Edited'},
        ),
        throwsStateError,
      );
      expect(requests, 1);
      expect(ProfileService.changes.value, changes);
    },
  );
}
