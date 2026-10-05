import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'body_server.dart';
import 'focus_workout_page.dart';
import 'theme_ctrl.dart';

class AnatomyTestPage extends StatefulWidget {
  const AnatomyTestPage({super.key});

  @override
  State<AnatomyTestPage> createState() => _AnatomyTestPageState();
}

class _AnatomyTestPageState extends State<AnatomyTestPage> {
  final BodyServer _server = BodyServer();
  final List<String> _selected = [];
  late final WebViewController _controller;
  bool _loading = true;
  bool _isBackView = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'ArcMuscle',
        onMessageReceived: (msg) {
          final name = msg.message.trim();
          if (!mounted || name.isEmpty) return;
          setState(() {
            if (name == '__clear__') {
              _selected.clear();
            } else if (_selected.contains(name)) {
              _selected.remove(name);
            } else {
              _selected.add(name);
            }
          });
          MuscleFocus.selected.value = List.of(_selected);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    _startServer();
  }

  Future<void> _startServer() async {
    await _server.start();
    await _controller.loadRequest(Uri.parse('http://127.0.0.1:${_server.port}/index.html'));
  }

  void _toggleView() {
    setState(() => _isBackView = !_isBackView);
    _controller.runJavaScript('toggleView()');
  }

  void _resetFocus() {
    setState(_selected.clear);
    MuscleFocus.selected.value = [];
    _controller.runJavaScript('clearAll()');
  }

  void _openWorkout() {
    if (_selected.isEmpty) return;
    MuscleFocus.selected.value = List.of(_selected);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FocusWorkoutPage(muscles: List.of(_selected))),
    );
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final ready = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        title: Text('Anatomy Focus Map', style: TextStyle(color: c.ink, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Tap Muscles to Prioritize', style: TextStyle(color: c.ink, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: WebViewWidget(controller: _controller)),
                  if (_loading) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _barButton(c, Icons.flip_rounded, _isBackView ? 'Showing: Back' : 'Showing: Front', _toggleView)),
                      const SizedBox(width: 12),
                      Expanded(child: _barButton(c, Icons.restart_alt_rounded, 'Reset Focus', _resetFocus)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _openWorkout,
                      style: FilledButton.styleFrom(
                        backgroundColor: ready ? c.ink : c.chip,
                        foregroundColor: ready ? c.page : c.muted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(ready ? 'Get workout · ${_selected.join(', ')}' : 'Tap a muscle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barButton(ArcColors c, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 52,
        decoration: metalPanel(c, radius: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c.ink, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}