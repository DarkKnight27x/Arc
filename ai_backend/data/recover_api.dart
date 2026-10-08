import 'dart:convert';
import 'dart:io';

/// Temporary Recover client. Talks to ai_backend/recover_server.py.
/// Arc records the report. It does not diagnose.
class RecoverApi {
  RecoverApi({this.baseUrl = 'http://10.0.2.2:8787', this.userId = 'saarthak'});
  final String baseUrl;
  final String userId;

  static const muscles = [
    'Chest',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearm',
    'Abs',
    'Upper back',
    'Lower back',
    'Glutes',
    'Quadriceps',
    'Hamstring',
    'Calves',
  ];

  Future<Map<String, dynamic>> snapshot() {
    return _get('/recover?user_id=$userId');
  }

  Future<List<Map<String, dynamic>>> reports() async {
    final body = await _get('/recover/reports?user_id=$userId');
    return _list(body['reports']);
  }

  Future<List<Map<String, dynamic>>> physios() async {
    final body = await _get('/recover/physios');
    return _list(body['physios']);
  }

  Future<Map<String, dynamic>> report({
    required String bodyRegion,
    required String description,
    String? photoFilename,
    int? photoBytes,
  }) {
    return _post('/recover/reports', {
      'user_id': userId,
      'body_region': bodyRegion,
      'description': description,
      if (photoFilename != null)
        'photo': {
          'filename': photoFilename,
          'byte_size': photoBytes ?? 0,
        },
    });
  }

  Future<Map<String, dynamic>> send({
    required String message,
    String? bodyRegion,
    String? photoFilename,
  }) {
    return _post('/recover/messages', {
      'user_id': userId,
      'message': message,
      if (bodyRegion != null) 'body_region': bodyRegion,
      if (photoFilename != null) 'photo': {'filename': photoFilename},
    });
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$baseUrl$path'));
      final response = await request.close();
      return _read(response);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl$path'));
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      return _read(response);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _read(HttpClientResponse response) async {
    final raw = await response.transform(utf8.decoder).join();
    final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Recover API returned a non-object.');
    }
    final body = Map<String, dynamic>.from(decoded);
    if (response.statusCode >= 400) {
      throw RecoverApiException(response.statusCode, body['error']?.toString() ?? 'Recover API failed.');
    }
    return body;
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}

class RecoverApiException implements Exception {
  RecoverApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}
