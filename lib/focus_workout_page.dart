import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_ctrl.dart';

class MuscleFocus {
  static final selected = ValueNotifier<List<String>>([]);
}

class FocusWorkoutPage extends StatefulWidget {
  const FocusWorkoutPage({super.key, required this.muscles});

  final List<String> muscles;

  @override
  State<FocusWorkoutPage> createState() => _FocusWorkoutPageState();
}

class _FocusWorkoutPageState extends State<FocusWorkoutPage> {
  bool loading = true;
  String? error;
  Map<String, List<Map<String, dynamic>>> grouped = {};

  static const aliases = {
    'abs': ['abs', 'abdominal', 'core'],
    'chest': ['chest', 'pectoral'],
    'shoulders': ['shoulder', 'deltoid'],
    'deltoids': ['deltoid', 'shoulder'],
    'biceps': ['bicep'],
    'triceps': ['tricep'],
    'forearm': ['forearm'],
    'forearms': ['forearm'],
    'back': ['back', 'lat'],
    'upper-back': ['upper back', 'lat', 'back'],
    'lower-back': ['lower back', 'back'],
    'lats': ['lat', 'back'],
    'quads': ['quad', 'quadricep'],
    'quadriceps': ['quad', 'quadricep'],
    'hamstrings': ['hamstring'],
    'hamstring': ['hamstring'],
    'glutes': ['glute'],
    'gluteal': ['glute'],
    'calves': ['calf', 'calves'],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('exercise_library')
          .select('name, body_part, target_muscle, equipment, gif_path')
          .eq('is_published', true);
      final next = <String, List<Map<String, dynamic>>>{};
      for (final muscle in widget.muscles) {
        final keys = aliases[muscle.toLowerCase()] ?? [muscle.toLowerCase()];
        final matches = (rows as List).where((row) {
          final blob = '${row['body_part']} ${row['target_muscle']} ${row['name']}'.toLowerCase();
          return keys.any(blob.contains);
        }).cast<Map<String, dynamic>>().take(6).toList();
        next[muscle] = matches;
      }
      if (!mounted) return;
      setState(() {
        grouped = next;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  String? _gif(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return Supabase.instance.client.storage.from('exercise-gifs').getPublicUrl(path);
  }

  void _showGif(String name, String detail, String gif) {
    final c = ArcColors.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: metalPanel(c, radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  gif,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator(color: c.brand)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.ink)),
                    const SizedBox(height: 8),
                    Text(detail, style: TextStyle(color: c.muted)),
                    const SizedBox(height: 16),
                    MetalBtn(label: 'Close', ghost: true, onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        title: Text('Priority muscles', style: TextStyle(color: c.ink, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, style: TextStyle(color: c.ink))))
          : ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(widget.muscles.join(' · '), style: TextStyle(color: c.muted, letterSpacing: 1.1, fontSize: 12)),
          const SizedBox(height: 16),
          for (final muscle in widget.muscles) ...[
            Text(muscle, style: TextStyle(color: c.ink, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if ((grouped[muscle] ?? []).isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text('No exercises for $muscle yet.', style: TextStyle(color: c.muted)),
              )
            else
              for (final row in grouped[muscle]!) _card(c, row),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _card(ArcColors c, Map<String, dynamic> row) {
    final gif = _gif(row['gif_path'] as String?);
    final name = '${row['name'] ?? ''}';
    final detail = '${row['target_muscle'] ?? row['body_part']} · ${row['equipment'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: gif == null ? null : () => _showGif(name, detail, gif),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: gif == null
                    ? ColoredBox(color: c.raised, child: Icon(Icons.fitness_center, color: c.muted))
                    : Image.network(gif, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: c.muted)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: c.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(color: c.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}