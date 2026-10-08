import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_ctrl.dart';

/// Presentation-only injury script. Chat sets [InjuryMode.current]. Home reads it.
class InjuryMode {
  static final current = ValueNotifier<InjuryScript?>(null);

  static InjuryScript? match(String text) {
    final q = text.toLowerCase();
    if (q.contains('shoulder') || q.contains('delt')) return InjuryScript.shoulder;
    if (q.contains('chest') || q.contains('pec')) return InjuryScript.chest;
    if (q.contains('back') || q.contains('spine') || q.contains('lumbar')) return InjuryScript.back;
    if (q.contains('leg') || q.contains('knee') || q.contains('quad') || q.contains('hamstring') || q.contains('calf') || q.contains('glute')) {
      return InjuryScript.legs;
    }
    return null;
  }

  static void apply(String text) {
    final hit = match(text);
    if (hit != null) current.value = hit;
  }
}

class InjuryScript {
  const InjuryScript({
    required this.id,
    required this.label,
    required this.avoid,
    required this.reply,
    required this.queries,
  });

  final String id;
  final String label;
  final String avoid;
  final String reply;
  final List<String> queries;

  static const shoulder = InjuryScript(
    id: 'shoulder',
    label: 'Shoulders',
    avoid: 'No overhead press, lateral raise, or upright row.',
    reply:
    'Recorded: shoulders. Arc will not diagnose this.\n\n'
        'Injury mode is on. Leave the shoulder alone today.\n'
        'Train around it: leg press, seated leg curl, hip thrust, calf raise.\n'
        'Open Injury mode on Home to see the list.',
    queries: ['leg press', 'seated leg curl', 'hip thrust', 'calf raise'],
  );

  static const chest = InjuryScript(
    id: 'chest',
    label: 'Chest',
    avoid: 'No bench, fly, or dip.',
    reply:
    'Recorded: chest. Arc will not diagnose this.\n\n'
        'Injury mode is on. Leave the press alone today.\n'
        'Train around it: seated row, lat pulldown, leg press, leg curl.\n'
        'Open Injury mode on Home to see the list.',
    queries: ['seated row', 'lat pulldown', 'leg press', 'leg curl'],
  );

  static const back = InjuryScript(
    id: 'back',
    label: 'Back',
    avoid: 'No deadlift, row, or pulldown.',
    reply:
    'Recorded: back. Arc will not diagnose this.\n\n'
        'Injury mode is on. Leave hinges and rows today.\n'
        'Train around it: leg press, leg extension, hip abduction, seated calf raise.\n'
        'Open Injury mode on Home to see the list.',
    queries: ['leg press', 'leg extension', 'hip abduction', 'seated calf raise'],
  );

  static const legs = InjuryScript(
    id: 'legs',
    label: 'Legs',
    avoid: 'No squat, lunge, or leg press.',
    reply:
    'Recorded: legs. Arc will not diagnose this.\n\n'
        'Injury mode is on. Leave squats and lunges today.\n'
        'Train around it: machine chest press, pec deck, lat pulldown, biceps curl.\n'
        'Open Injury mode on Home to see the list.',
    queries: ['chest press', 'pec deck', 'lat pulldown', 'biceps curl'],
  );

  static const ask = InjuryScript(
    id: 'ask',
    label: '',
    avoid: '',
    reply: 'Say chest, shoulder, back, or legs. Arc records that note. It does not diagnose.',
    queries: [],
  );
}

class InjuryModeCard extends StatelessWidget {
  const InjuryModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InjuryScript?>(
      valueListenable: InjuryMode.current,
      builder: (context, script, _) {
        final c = ArcColors.of(context);
        final on = script != null && script.queries.isNotEmpty;
        return InkWell(
          onTap: () => showInjurySheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.chip,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INJURED',
                        style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: c.muted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        on ? '${script.label} off today\'s session' : 'No injury reported',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showInjurySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _InjurySheet(),
  );
}

class _InjurySheet extends StatefulWidget {
  const _InjurySheet();

  @override
  State<_InjurySheet> createState() => _InjurySheetState();
}

class _InjurySheetState extends State<_InjurySheet> {
  bool loading = true;
  List<_Move> moves = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final script = InjuryMode.current.value;
    final kept = todayWithout(script);
    if (script == null || script.queries.isEmpty) {
      setState(() => loading = false);
      return;
    }
    final client = Supabase.instance.client;
    final found = <_Move>[];
    for (final slot in kept) {
      try {
        final rows = await client
            .from('exercise_library')
            .select('name, equipment, gif_path')
            .ilike('name', '%${slot.query}%')
            .limit(1);
        if (rows.isEmpty) {
          final loose = await client
              .from('exercise_library')
              .select('name, equipment, gif_path')
              .ilike('name', '%${slot.query.split(' ').first}%')
              .not('gif_path', 'is', null)
              .limit(1);
          if (loose.isEmpty) {
            found.add(_Move(slot.query, slot.area, null));
            continue;
          }
          final row = Map<String, dynamic>.from(loose.first as Map);
          found.add(_Move(
            row['name'] as String? ?? slot.query,
            row['equipment'] as String? ?? slot.area,
            _gif(client, row['gif_path'] as String?),
          ));
          continue;
        }
        final row = Map<String, dynamic>.from(rows.first as Map);
        found.add(_Move(
          row['name'] as String? ?? slot.query,
          row['equipment'] as String? ?? slot.area,
          _gif(client, row['gif_path'] as String?),
        ));
      } catch (_) {
        found.add(_Move(slot.query, slot.area, null));
      }
    }
    if (!mounted) return;
    setState(() {
      moves = found;
      loading = false;
    });
  }

  String? _gif(SupabaseClient client, String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return client.storage.from('exercise-gifs').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final script = InjuryMode.current.value;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
      decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Text('Injured', style: TextStyle(color: c.ink, fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            script == null || script.queries.isEmpty
                ? 'Report chest, shoulder, back, or legs in Recover first.'
                : 'Today\'s session, ${script.label.toLowerCase()} removed.',
            style: TextStyle(color: c.muted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: c.ink)),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final move in moves)
                    InkWell(
                      onTap: () => _showGif(context, move),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.page,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: move.gif == null
                                    ? ColoredBox(color: c.chip, child: Icon(Icons.fitness_center, color: c.muted))
                                    : Image.network(move.gif!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(move.name, style: TextStyle(color: c.ink, fontWeight: FontWeight.w600)),
                                  if (move.equipment.isNotEmpty)
                                    Text(move.equipment, style: TextStyle(color: c.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (move.gif != null) Icon(Icons.play_arrow_rounded, color: c.ink) else Icon(Icons.play_arrow_rounded, color: c.muted),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showGif(BuildContext context, _Move move) {
    final c = ArcColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: c.page,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(move.name, style: TextStyle(color: c.ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (move.gif == null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No gif in exercise_library for this one.', style: TextStyle(color: c.muted)),
                )
              else
                Image.network(
                  move.gif!,
                  height: 280,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gif failed to load.', style: TextStyle(color: c.muted)),
                  ),
                ),
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Close', style: TextStyle(color: c.ink))),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayMove {
  const TodayMove(this.area, this.query);
  final String area;
  final String query;
}

const todaySession = [
  TodayMove('chest', 'dumbbell bench press'),
  TodayMove('chest', 'pec deck'),
  TodayMove('shoulder', 'dumbbell front raise'),
  TodayMove('shoulder', 'dumbbell shoulder press'),
  TodayMove('triceps', 'tricep pushdown'),
  TodayMove('triceps', 'overhead extension'),
];

List<TodayMove> todayWithout(InjuryScript? script) {
  if (script == null || script.id.isEmpty) return todaySession;
  return todaySession.where((move) => move.area != script.id).toList();
}

class _Move {
  const _Move(this.name, this.equipment, this.gif);
  final String name;
  final String equipment;
  final String? gif;
}
