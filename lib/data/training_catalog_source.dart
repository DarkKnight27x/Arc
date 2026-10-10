import 'package:supabase_flutter/supabase_flutter.dart';

import 'training_plan_models.dart';

abstract interface class TrainingCatalogSource {
  Future<TrainingCatalog> load();
}

/// Read-only and paginated; there is no static count or exercise allowlist in code.
class SupabaseTrainingCatalogSource implements TrainingCatalogSource {
  SupabaseTrainingCatalogSource(this.client, {this.pageSize = 500}) {
    if (pageSize < 1 || pageSize > 1000) {
      throw ArgumentError('Invalid catalog page size');
    }
  }
  final SupabaseClient client;
  final int pageSize;

  Future<List<Map<String, dynamic>>> _rows(String table, String columns) async {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};
    final order = table == 'exercise_library' ? 'id' : 'exercise_id';
    for (var offset = 0; ;) {
      var query = client.from(table).select(columns).order(order);
      if (table != 'exercise_library') {
        query = query.order('version');
      }
      final page = await query
          .range(offset, offset + pageSize - 1)
          .timeout(const Duration(seconds: 20));
      if (page.isEmpty) return result;
      for (final row in page) {
        final identity = table == 'exercise_library'
            ? row['id'].toString()
            : '${row['exercise_id']}:${row['version']}';
        if (!seen.add(identity)) {
          throw const FormatException('Catalog changed during pagination');
        }
      }
      result.addAll(page);
      // A server may impose a row cap below pageSize. Advance by returned rows,
      // and stop on an empty page, rather than silently truncating the catalog.
      offset += page.length;
    }
  }

  @override
  Future<TrainingCatalog> load() async {
    final owner = client.auth.currentUser?.id;
    final issues = <TrainingIssue>[];
    try {
      final library = await _rows('exercise_library', '*');
      if (client.auth.currentUser?.id != owner) {
        return TrainingCatalog(
          [],
          issues: [
            TrainingIssue(
              TrainingIssueCode.catalogUnavailable,
              'Your account changed while loading training data.',
            ),
          ],
        );
      }
      return TrainingCatalog(
        library.map(TrainingCatalogExercise.fromMap),
        issues: issues,
      );
    } catch (_) {
      // No raw server/profile/auth details reach a future preview screen.
      return TrainingCatalog(
        [],
        issues: [
          TrainingIssue(
            TrainingIssueCode.catalogUnavailable,
            'Unable to verify the exercise catalog. Retry before generating a program.',
          ),
        ],
      );
    }
  }
}
