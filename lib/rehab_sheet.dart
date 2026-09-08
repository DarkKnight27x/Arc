import 'package:flutter/material.dart';
import 'theme_ctrl.dart';

void showRehabSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final c = ArcColors.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: metalPanel(c),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
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
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Screens what you report. A human when the plan isn’t enough.',
                style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
              ),
              const SizedBox(height: 16),
              const _RehabRow(
                icon: Icons.self_improvement,
                title: 'Unload sessions',
                meta: '8–12 min · no impact · matches the region you marked',
              ),
              const SizedBox(height: 10),
              const _RehabRow(
                icon: Icons.restaurant_outlined,
                title: 'Recovery kitchen',
                meta: 'Light plates for high-stress and prep weeks',
              ),
              const SizedBox(height: 10),
              const _RehabRow(
                icon: Icons.medical_services_outlined,
                title: 'Find a physio',
                meta: 'Near you · Hindi / English · ₹ range on the card',
              ),
              const SizedBox(height: 16),
              MetalBtn(
                label: 'Unlock Rehab',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              Text(
                'ARC follows limits you stated. It does not diagnose or manage surgery.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: c.muted),
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
    final c = ArcColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: metalWell(c),
      child: Row(
        children: [
          Icon(icon, color: c.ice, size: 22),
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
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: c.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 16, color: c.faint),
        ],
      ),
    );
  }
}