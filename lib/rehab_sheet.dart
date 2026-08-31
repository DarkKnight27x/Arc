import 'package:flutter/material.dart';
import 'arc_theme.dart';

void showRehabSheet(BuildContext context) {
  final p = ArcPalette.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ArcCard(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rehab',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Recovery work, plates, and a human when the plan isn’t enough.',
                style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
              ),
              const SizedBox(height: 16),
              const _RehabRow(
                icon: Icons.self_improvement,
                title: 'Unload sessions',
                meta: '8–12 min · no impact · matches the red region on Body',
              ),
              const SizedBox(height: 10),
              const _RehabRow(
                icon: Icons.restaurant_outlined,
                title: 'Recovery kitchen',
                meta: 'Light plates for surgery-prep and high-stress weeks',
              ),
              const SizedBox(height: 10),
              const _RehabRow(
                icon: Icons.medical_services_outlined,
                title: 'Find a physio',
                meta: 'Near you · Hindi / English · ₹ range on the card',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  'Unlock Rehab',
                  style: TextStyle(
                    color: p.onAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Arc follows limits you stated. It does not manage your surgery.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: p.muted),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RehabRow extends StatelessWidget {
  const _RehabRow({
    required this.icon,
    required this.title,
    required this.meta,
  });
  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final p = ArcPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.stroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: p.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(meta, style: TextStyle(fontSize: 12.5, height: 1.35, color: p.muted)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 16, color: p.muted),
        ],
      ),
    );
  }
}