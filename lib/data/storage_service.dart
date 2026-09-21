import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  static const mealImagesBucket = 'meal-images';

  String? mealImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return _client.storage.from(mealImagesBucket).getPublicUrl(path);
  }
}