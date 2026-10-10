import 'package:supabase_flutter/supabase_flutter.dart';

/// Media is presentation metadata, never exercise/programming eligibility.
class ExerciseMediaPath {
  // Preserve source values in provenance snapshots; normalization is display-only.
  static String? storedPath(Object? value) => value is String ? value : null;
  static String? normalize(Object? value) {
    if (value is! String) return null;
    final path = value.trim();
    if (path.isEmpty || RegExp(r'[\x00-\x1f\\]').hasMatch(path)) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty &&
              uri.userInfo.isEmpty
          ? path
          : null;
    }
    if (path.startsWith('/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.any((s) => s == '..' || s == '.')) {
      return null;
    }
    return path;
  }

  static String? resolve(Object? value, {String Function(String)? storageUrl}) {
    final path = normalize(value);
    if (path == null) return null;
    if (Uri.parse(path).hasScheme || path.startsWith('assets/')) return path;
    try {
      return normalize(storageUrl?.call(path));
    } catch (_) {
      return null;
    }
  }

  static String? publicUrl(Object? path) => resolve(
    path,
    storageUrl: (p) =>
        Supabase.instance.client.storage.from('exercise-gifs').getPublicUrl(p),
  );

  /// Fetch only current public media, independently of frozen session history.
  /// The caller retains its snapshot media when offline or denied by RLS.
  static Future<Object?> latest(String id, {SupabaseClient? client}) async {
    final row = await (client ?? Supabase.instance.client)
        .from('exercise_library')
        .select('gif_path')
        .eq('id', id)
        .eq('is_published', true)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));
    return row?['gif_path'];
  }
}
