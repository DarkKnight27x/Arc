import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'injury_mode.dart';
import 'theme_ctrl.dart';

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

  Future<List<Map<String, dynamic>>> physios() async {
    final body = await _get('/recover/physios');
    final value = body['physios'];
    if (value is! List) return const [];
    return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
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
}

class RecoverApiException implements Exception {
  RecoverApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}

/// Quiet Recover page. Arc records the report. It does not diagnose.
class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  State<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> {
  final note = TextEditingController();
  final api = RecoverApi();
  final thread = <({String role, String text})>[];
  String? muscle;
  String? photoName;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    themeCtrl.addListener(_onTheme);
  }

  void _onTheme() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeCtrl.removeListener(_onTheme);
    note.dispose();
    super.dispose();
  }

  Future<void> _openWhere() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhereSheet(selected: muscle),
    );
    if (picked == null || !mounted) return;
    setState(() => muscle = picked);
  }

  Future<void> _send() async {
    final text = note.text.trim();
    if (text.isEmpty && muscle == null) {
      _toast('Type the injury, or choose a muscle.');
      return;
    }
    // Typed note wins. The chip is only a fallback, so a leftover
    // Shoulders pick cannot override "chest feels tight".
    final fromText = InjuryMode.match(text);
    final fromChip = InjuryMode.match(muscle ?? '');
    final script = fromText ?? fromChip ?? InjuryScript.ask;
    InjuryMode.apply(fromText != null ? text : (muscle ?? ''));
    final spoken = text.isEmpty ? 'Reported ${muscle ?? 'it'}.' : text;
    note.clear();
    setState(() {
      thread.add((role: 'user', text: spoken));
      thread.add((role: 'arc', text: script.reply));
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: c.page,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                children: [
                  Row(
                    children: [
                      Text('RECOVER', style: TextStyle(color: c.muted, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: toggleArcTheme,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.line),
                          ),
                          child: Text(
                            dark ? 'Dark' : 'Light',
                            style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Report an injury.', style: TextStyle(fontSize: 36, height: 1.02, fontWeight: FontWeight.w500, color: c.ink)),
                  const SizedBox(height: 8),
                  Text('Arc records what you report. It does not diagnose.', style: TextStyle(color: c.muted, fontSize: 15, height: 1.35)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _openWhere,
                        icon: Icon(Icons.accessibility_new_rounded, size: 18, color: c.page),
                        label: Text(muscle ?? 'Choose muscle'),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.ink,
                          foregroundColor: c.page,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhysioListPage(api: api)));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: c.chip,
                          foregroundColor: c.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: const Text('Physio'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final line in thread)
                    Align(
                      alignment: line.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: line.role == 'user' ? c.ink : c.chip,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.line),
                        ),
                        child: Text(
                          line.text,
                          style: TextStyle(color: line.role == 'user' ? c.page : c.ink, height: 1.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                decoration: BoxDecoration(
                  color: c.chip,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => photoName = photoName == null ? 'report.jpg' : null),
                      icon: Icon(photoName == null ? Icons.add : Icons.image_outlined, color: c.ink),
                    ),
                    Expanded(
                      child: TextField(
                        controller: note,
                        style: TextStyle(color: c.ink),
                        cursorColor: c.ink,
                        decoration: InputDecoration(
                          hintText: 'Report your injury',
                          hintStyle: TextStyle(color: c.muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: sending ? null : _send,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                        child: sending
                            ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.page),
                        )
                            : Icon(Icons.arrow_upward_rounded, color: c.page, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhereSheet extends StatefulWidget {
  const _WhereSheet({required this.selected});

  final String? selected;

  @override
  State<_WhereSheet> createState() => _WhereSheetState();
}

class _WhereSheetState extends State<_WhereSheet> {
  String? muscle;
  bool open = true;

  @override
  void initState() {
    super.initState();
    muscle = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Where', style: TextStyle(color: c.ink, fontSize: 28, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: c.ink)),
            ],
          ),
          Text('MUSCLE', style: TextStyle(color: c.muted, fontSize: 11, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => open = !open),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
              child: Row(
                children: [
                  Text(muscle ?? 'Select a muscle', style: TextStyle(color: c.ink, fontSize: 16)),
                  const Spacer(),
                  Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: c.muted),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(color: c.page, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in RecoverApi.muscles)
                    ListTile(
                      dense: true,
                      title: Text(item, style: TextStyle(color: c.ink)),
                      trailing: item == muscle ? Icon(Icons.check, color: c.ink, size: 18) : null,
                      onTap: () => setState(() {
                        muscle = item;
                        open = false;
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: muscle == null ? null : () => Navigator.pop(context, muscle),
              style: FilledButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.page,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Save report'),
            ),
          ),
        ],
      ),
    );
  }
}

class PhysioListPage extends StatefulWidget {
  const PhysioListPage({super.key, required this.api});

  final RecoverApi api;

  @override
  State<PhysioListPage> createState() => _PhysioListPageState();
}

class _PhysioListPageState extends State<PhysioListPage> {
  late Future<List<Map<String, dynamic>>> physios;

  @override
  void initState() {
    super.initState();
    physios = widget.api.physios();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: c.page,
        elevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        title: Text('Physio', style: TextStyle(color: c.ink)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: physios,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.ink));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Physio list needs the Recover API at ${widget.api.baseUrl}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted),
                ),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              for (final p in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.chip,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['image_url'] != null)
                        Image.network(
                          '${p['image_url']}',
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p['display_name']}',
                                    style: TextStyle(color: c.ink, fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text('₹${p['session_price']}', style: TextStyle(color: c.ink, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${p['city']} · ${p['distance_km']} km', style: TextStyle(color: c.muted, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${p['rating']} · ${(p['specialties'] as List?)?.join(' · ') ?? ''}', style: TextStyle(color: c.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
