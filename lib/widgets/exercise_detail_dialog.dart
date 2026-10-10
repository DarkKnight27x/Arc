import 'package:flutter/material.dart';

import '../data/exercise_media.dart';
import '../theme_ctrl.dart';
import 'exercise_media.dart';

/// Display already-loaded catalog metadata. Only demo refresh needs a lookup.
/// The dialog owns its pop context, even inside the signed-in Navigator.
Future<void> showExerciseDetails(
  BuildContext context, {
  required Object? name,
  Object? target,
  Object? equipment,
  Object? instructions,
  Object? mediaPath,
  Object? exerciseId,
  Future<Object?> Function(String) lookup = ExerciseMediaPath.latest,
}) => showDialog<void>(
  context: context,
  useRootNavigator: true,
  routeSettings: const RouteSettings(name: '/exercise-detail'),
  builder: (dialogContext) => _ExerciseDetails(
    name: name,
    target: target,
    equipment: equipment,
    instructions: instructions,
    mediaPath: mediaPath,
    exerciseId: exerciseId,
    lookup: lookup,
  ),
);

String _text(Object? value, String fallback) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;

class _ExerciseDetails extends StatefulWidget {
  const _ExerciseDetails({
    required this.name,
    required this.target,
    required this.equipment,
    required this.instructions,
    required this.mediaPath,
    required this.exerciseId,
    required this.lookup,
  });
  final Object? name, target, equipment, instructions, mediaPath, exerciseId;
  final Future<Object?> Function(String) lookup;
  @override
  State<_ExerciseDetails> createState() => _ExerciseDetailsState();
}

class _ExerciseDetailsState extends State<_ExerciseDetails> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final raw = widget.instructions;
    final instructions = raw is List
        ? raw
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : raw is String && raw.trim().isNotEmpty
        ? [raw.trim()]
        : <String>[];
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        padding: const EdgeInsets.all(16),
        decoration: metalPanel(c, radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _text(widget.name, 'Exercise'),
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Back',
                  icon: Icon(Icons.arrow_back, color: c.ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: ExerciseMedia(
                          key: ValueKey(attempt),
                          path: widget.mediaPath,
                          exerciseId: widget.exerciseId is String
                              ? widget.exerciseId as String
                              : null,
                          lookup: widget.lookup,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => attempt++),
                      child: Text(
                        'Demo unavailable? Retry',
                        style: TextStyle(color: c.ink),
                      ),
                    ),
                    Text(
                      'Target muscle: ${_text(widget.target, 'Not specified')}',
                      style: TextStyle(color: c.muted),
                    ),
                    Text(
                      _text(widget.equipment, 'Equipment not specified'),
                      style: TextStyle(color: c.muted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Instructions',
                      style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (instructions.isEmpty)
                      Text(
                        'Instructions are not available yet.',
                        style: TextStyle(color: c.muted),
                      ),
                    for (final instruction in instructions)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          instruction,
                          style: TextStyle(color: c.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            MetalBtn(
              label: 'Close',
              ghost: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
