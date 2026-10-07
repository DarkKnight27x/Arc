import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'theme_ctrl.dart';
import 'widgets/location_label.dart';

class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  State<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> {
  final note = TextEditingController();
  final picker = ImagePicker();
  String? muscle;
  String? photoPath;

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

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _openWhere() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhereSheet(
        muscles: muscles,
        selected: muscle,
        onSave: (value) => setState(() => muscle = value),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final c = ArcColors.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: c.chip,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: c.ink),
              title: Text('Upload a photo', style: TextStyle(color: c.ink)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: c.ink),
              title: Text('Take a photo', style: TextStyle(color: c.ink)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null || !mounted) return;
    setState(() => photoPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
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
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                        child: const ArcLogo(),
                      ),
                      const Spacer(),
                      LocationLabel(c: c),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('RECOVER', style: TextStyle(color: c.muted, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
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
                        label: Text(muscle == null ? 'Choose muscle' : muscle!),
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
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhysioListPage()));
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
                  if (photoPath != null) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(photoPath!), height: 140, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
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
                    IconButton(onPressed: _pickPhoto, icon: Icon(Icons.add, color: c.ink)),
                    Expanded(
                      child: TextField(
                        controller: note,
                        style: TextStyle(color: c.ink),
                        decoration: InputDecoration(
                          hintText: 'Report your injury',
                          hintStyle: TextStyle(color: c.muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_upward_rounded, color: c.page, size: 18),
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
  const _WhereSheet({required this.muscles, required this.selected, required this.onSave});

  final List<String> muscles;
  final String? selected;
  final ValueChanged<String> onSave;

  @override
  State<_WhereSheet> createState() => _WhereSheetState();
}

class _WhereSheetState extends State<_WhereSheet> {
  String? muscle;
  bool open = true;

  @override
  void initState() {
    super.initState();
    muscle = widget.selected ?? 'Shoulders';
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
                  for (final item in widget.muscles)
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
              onPressed: muscle == null
                  ? null
                  : () {
                widget.onSave(muscle!);
                Navigator.pop(context);
              },
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

class PhysioListPage extends StatelessWidget {
  const PhysioListPage({super.key});

  static const items = [
    ('Motion Lab Physio', 'Thane West · 1.2 km', 'Sports · shoulder', '4.6', '₹900', 'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?auto=format&fit=crop&w=800&q=80'),
    ('Restore Clinic', 'Naupada · 2.1 km', 'Post-op · strength', '4.4', '₹800', 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=800&q=80'),
    ('Hiranandani Physio', 'Powai · 6.4 km', 'Knee · spine', '4.7', '₹1100', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80'),
    ('Bandra Sports PT', 'Bandra West · 18 km', 'Lifters · return to gym', '4.5', '₹1200', 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        title: Text('Physio', style: TextStyle(color: c.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final p in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.chip,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(p.$6, height: 140, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(p.$1, style: TextStyle(color: c.ink, fontSize: 16, fontWeight: FontWeight.w700))),
                              Text(p.$5, style: TextStyle(color: c.ink, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p.$2, style: TextStyle(color: c.muted, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${p.$4} · ${p.$3}', style: TextStyle(color: c.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
