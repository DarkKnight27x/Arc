import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_ctrl.dart';
import 'widgets/exercise_media.dart';
import 'widgets/exercise_detail_dialog.dart';

class MuscleFocus {
  static final selected = ValueNotifier<List<String>>([]);
}

class FocusWorkoutPage extends StatefulWidget {
  const FocusWorkoutPage({super.key, required this.muscles, this.client});

  final List<String> muscles;
  final SupabaseClient? client;

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
      final rows = await (widget.client ?? Supabase.instance.client)
          .from('exercise_library')
          .select(
            'id, name, body_part, target_muscle, equipment, gif_path, instructions',
          )
          .eq('is_published', true);
      final next = <String, List<Map<String, dynamic>>>{};
      for (final muscle in widget.muscles) {
        final keys = aliases[muscle.toLowerCase()] ?? [muscle.toLowerCase()];
        final matches = (rows as List)
            .where((row) {
              final blob =
                  '${row['body_part']} ${row['target_muscle']} ${row['name']}'
                      .toLowerCase();
              return keys.any(blob.contains);
            })
            .cast<Map<String, dynamic>>()
            .take(6)
            .toList();
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

  void _showGif(Map<String, dynamic> row) {
    showExerciseDetails(
      context,
      name: row['name'],
      target: row['target_muscle'],
      equipment: row['equipment'],
      instructions: row['instructions'],
      mediaPath: row['gif_path'],
      exerciseId: row['id'],
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
        title: Text(
          'Priority muscles',
          style: TextStyle(
            color: c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, style: TextStyle(color: c.ink)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  widget.muscles.join(' · '),
                  style: TextStyle(
                    color: c.muted,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                for (final muscle in widget.muscles) ...[
                  Text(
                    muscle,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if ((grouped[muscle] ?? []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        'No exercises for $muscle yet.',
                        style: TextStyle(color: c.muted),
                      ),
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
    final name = '${row['name'] ?? ''}';
    final detail =
        '${row['target_muscle'] ?? row['body_part']} · ${row['equipment'] ?? ''}';
    return GestureDetector(
      onTap: () => _showGif(row),
      child: Container(
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
              onTap: () => _showGif(row),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ExerciseMedia(
                    path: row['gif_path'],
                    exerciseId: row['id'] is String
                        ? row['id'] as String
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(detail, style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
