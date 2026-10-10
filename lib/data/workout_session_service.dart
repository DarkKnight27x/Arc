import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'workout_session.dart';

class SessionPersistenceException implements Exception {
  const SessionPersistenceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SessionConflictException implements Exception {
  const SessionConflictException(this.local, this.remote);
  final WorkoutSession local, remote;
  @override
  String toString() =>
      'Device and cloud sessions differ. Choose which exact session to continue.';
}

class WorkoutSessionService {
  WorkoutSessionService(this.client);

  /// UI invalidation only; does not change the session save RPC or payload.
  static final changes = ValueNotifier<({String owner, int revision})?>(null);
  static void invalidate(String owner) => changes.value = (
    owner: owner,
    revision: (changes.value?.revision ?? 0) + 1,
  );
  final SupabaseClient client;
  final Map<String, int> _confirmedRevisions = {};
  String key(String userId, String dayId) => 'arc.session.$userId.$dayId';
  void checkOwner(WorkoutSession session) {
    if (client.auth.currentUser?.id != session.userId) {
      throw const SessionPersistenceException(
        'Your account changed. Sign in to the original account to save.',
      );
    }
  }

  Future<void> saveDraft(WorkoutSession session) async {
    checkOwner(session);
    final prefs = await SharedPreferences.getInstance();
    checkOwner(session);
    if (!await prefs.setString(
      key(session.userId, session.dayId),
      jsonEncode(session.toMap()),
    )) {
      throw const SessionPersistenceException(
        'Could not keep a local draft. Keep this session open and retry.',
      );
    }
  }

  Future<WorkoutSession?> resume(String dayId, {bool reconcile = false}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const SessionPersistenceException('Please sign in.');
    }
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(key(userId, dayId));
    WorkoutSession? local;
    if (draft != null) {
      final session = WorkoutSession.fromMap(
        Map<String, dynamic>.from(jsonDecode(draft) as Map),
      );
      checkOwner(session);
      if (session.dayId != dayId) {
        throw const SessionPersistenceException(
          'The local draft does not match this workout.',
        );
      }
      if (!reconcile) return session;
      local = session;
    }
    List<Map<String, dynamic>> rows;
    try {
      var query = client
          .from('workout_sessions')
          .select()
          .eq('user_id', userId)
          .eq('workout_day_id', dayId);
      if (local != null) {
        if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(local.id)) {
          throw const SessionPersistenceException('Invalid draft identity.');
        }
        query = query.or('status.eq.in_progress,id.eq.${local.id}');
      } else {
        query = query.eq('status', 'in_progress');
      }
      rows = await query
          .order('started_at', ascending: false)
          .order('id', ascending: true)
          .limit(1)
          .timeout(const Duration(seconds: 20));
    } on PostgrestException catch (e) {
      if (missingSchema(e)) return local;
      if (local != null && e.code != '42501') return local;
      rethrow;
    } catch (e) {
      if (local != null &&
          client.auth.currentUser?.id == userId &&
          e is! SessionPersistenceException) {
        return local;
      }
      rethrow;
    }
    if (client.auth.currentUser?.id != userId) {
      throw const SessionPersistenceException('Your account changed.');
    }
    if (rows.isEmpty) return local;
    final row = rows.single;
    final sets = await client
        .from('workout_session_sets')
        .select()
        .eq('session_id', row['id'])
        .order('exercise_position', ascending: true)
        .order('set_number', ascending: true)
        .timeout(const Duration(seconds: 20));
    final prescription = row['prescription'] as List;
    final completion = prescription
        .map((m) => List.filled((m['sets'] as int?) ?? 1, false))
        .toList();
    final expectedCount = completion.fold<int>(
      0,
      (n, flags) => n + flags.length,
    );
    final coordinates = <String>{};
    if (sets.length != expectedCount) {
      throw const SessionPersistenceException(
        'The saved session has missing set records. Retry loading.',
      );
    }
    for (final set in sets) {
      final exercise = set['exercise_position'] as int;
      final number = set['set_number'] as int;
      if (exercise < 0 ||
          exercise >= completion.length ||
          number < 1 ||
          number > completion[exercise].length ||
          !coordinates.add('$exercise:$number')) {
        throw const SessionPersistenceException(
          'The saved session has invalid set records.',
        );
      }
      completion[exercise][number - 1] = set['completed'] as bool;
    }
    final envelope = row['snapshot'] as Map?;
    final session = WorkoutSession.fromMap({
      ...row,
      if (envelope != null) 'workout_plan_id': envelope['workout_plan_id'],
      if (envelope != null) 'workout_day_id': envelope['workout_day_id'],
      'completion': completion,
    });
    checkOwner(session);
    _confirmedRevisions[session.id] = session.revision;
    if (local != null) {
      final localMap = local.toMap()..remove('base_revision');
      final remoteMap = session.toMap()..remove('base_revision');
      if (jsonEncode(localMap) == jsonEncode(remoteMap)) return session;
      if (local.id == session.id &&
          local.status == WorkoutSessionStatus.inProgress &&
          session.status == WorkoutSessionStatus.inProgress &&
          local.revision > session.revision &&
          local.baseRevision == session.revision) {
        return local;
      }
      throw SessionConflictException(local, session);
    }
    return session;
  }

  static bool missingSchema(PostgrestException e) =>
      ['42P01', 'PGRST205', 'PGRST202', '42883'].contains(e.code);

  /// Today's saved status, including sessions finished across midnight.
  /// Reads only the authenticated owner's history for the selected plan day.
  Future<WorkoutSessionStatus?> currentDayStatus(
    String dayId, {
    DateTime? now,
  }) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw const SessionPersistenceException('Please sign in.');
    }
    final day = now ?? DateTime.now();
    final start = DateTime(
      day.year,
      day.month,
      day.day,
    ).toUtc().toIso8601String();
    final end = DateTime(
      day.year,
      day.month,
      day.day + 1,
    ).toUtc().toIso8601String();
    final rows = await client
        .from('workout_sessions')
        .select('status')
        .eq('user_id', owner)
        .eq('workout_day_id', dayId)
        .or(
          'and(started_at.gte.$start,started_at.lt.$end),'
          'and(completed_at.gte.$start,completed_at.lt.$end)',
        )
        .timeout(const Duration(seconds: 20));
    if (owner != client.auth.currentUser?.id) {
      throw const SessionPersistenceException('Your account changed.');
    }
    final statuses = rows.map((row) {
      return switch (row['status']) {
        'completed' => WorkoutSessionStatus.completed,
        'in_progress' => WorkoutSessionStatus.inProgress,
        'abandoned' => WorkoutSessionStatus.abandoned,
        _ => throw const FormatException('Invalid saved session status'),
      };
    }).toSet();
    for (final status in [
      WorkoutSessionStatus.completed,
      WorkoutSessionStatus.inProgress,
      WorkoutSessionStatus.abandoned,
    ]) {
      if (statuses.contains(status)) return status;
    }
    return null;
  }

  Future<void> save(WorkoutSession session, {bool writeDraft = true}) async {
    checkOwner(session);
    if (writeDraft) await saveDraft(session);
    checkOwner(session);
    try {
      final payload = session.toMap();
      payload['base_revision'] =
          _confirmedRevisions[session.id] ?? session.baseRevision;
      final result = await client
          .rpc('save_workout_session', params: {'payload': payload})
          .timeout(const Duration(seconds: 20));
      checkOwner(session);
      if (result != session.id) {
        throw const SessionPersistenceException(
          'The server did not confirm this session. Retry saving.',
        );
      }
      _confirmedRevisions[session.id] = session.revision;
      final currentPrefs = await SharedPreferences.getInstance();
      final currentRaw = currentPrefs.getString(
        key(session.userId, session.dayId),
      );
      if (currentRaw != null) {
        final current = Map<String, dynamic>.from(
          jsonDecode(currentRaw) as Map,
        );
        if (current['id'] == session.id) {
          current['base_revision'] = session.revision;
          await currentPrefs.setString(
            key(session.userId, session.dayId),
            jsonEncode(current),
          );
        }
      }
      if (session.status != WorkoutSessionStatus.inProgress) {
        final prefs = await SharedPreferences.getInstance();
        checkOwner(session);
        final current = prefs.getString(key(session.userId, session.dayId));
        if (current != null &&
            (jsonDecode(current) as Map)['id'] == session.id) {
          await prefs.remove(key(session.userId, session.dayId));
        }
      }
    } on PostgrestException catch (e) {
      throw SessionPersistenceException(
        e.code == '40001'
            ? 'The cloud session changed. Keep your draft and reopen to resolve the conflict.'
            : missingSchema(e)
            ? 'Cloud saving is unavailable until the session migration is applied. Your draft is kept on this device.'
            : 'Cloud save failed. Your draft is kept on this device. Retry saving.',
      );
    }
    checkOwner(session);
    invalidate(session.userId);
  }

  Future<void> resolveConflict(
    WorkoutSession selected,
    WorkoutSession other,
  ) async {
    checkOwner(selected);
    checkOwner(other);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'arc.session.conflict.${other.userId}.${other.id}.${other.revision}',
      jsonEncode(other.toMap()),
    );
    if (selected.id == other.id &&
        selected.status == WorkoutSessionStatus.inProgress &&
        other.status == WorkoutSessionStatus.inProgress) {
      final selectedBlueprint = selected.toMap()
        ..removeWhere(
          (key, value) => [
            'completion',
            'status',
            'outcome',
            'completed_at',
            'current_index',
            'revision',
            'base_revision',
            'injury_warning',
          ].contains(key),
        );
      final otherBlueprint = other.toMap()
        ..removeWhere(
          (key, value) => [
            'completion',
            'status',
            'outcome',
            'completed_at',
            'current_index',
            'revision',
            'base_revision',
            'injury_warning',
          ].contains(key),
        );
      if (jsonEncode(selectedBlueprint) != jsonEncode(otherBlueprint)) {
        throw const SessionPersistenceException(
          'The immutable session prescriptions conflict. They cannot replace one another.',
        );
      }
      final confirmed = _confirmedRevisions[selected.id];
      if (confirmed != null && selected.revision <= confirmed) {
        selected.baseRevision = confirmed;
        selected.revision = confirmed + 1;
      }
    }
    await saveDraft(selected);
  }
}
