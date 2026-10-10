import 'dart:convert';

import 'data/training_metadata.dart';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'body_server.dart';
import 'focus_workout_page.dart';
import 'theme_ctrl.dart';
import 'widgets/arc_plan_theme.dart';

class AnatomyTestPage extends StatefulWidget {
  const AnatomyTestPage({
    super.key,
    this.prioritySelection = false,
    this.initialPriorities = const [],
  });
  final bool prioritySelection;
  final List<String> initialPriorities;

  @override
  State<AnatomyTestPage> createState() => _AnatomyTestPageState();
}

class _AnatomyTestPageState extends State<AnatomyTestPage> {
  final BodyServer _server = BodyServer();
  final List<String> _selected = [];
  late final WebViewController _controller;
  bool _loading = true;
  bool _selectionLoadFailed = false;
  bool _isBackView = false;

  @override
  void initState() {
    super.initState();
    if (widget.prioritySelection) {
      _selected.addAll(widget.initialPriorities.map(canonicalMuscle));
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'ArcMuscle',
        onMessageReceived: (msg) {
          if (widget.prioritySelection) {
            if (_loading || _selectionLoadFailed) return;
            Object? raw;
            try {
              raw = jsonDecode(msg.message);
            } on FormatException {
              return;
            }
            if (raw is! List || !mounted) return;
            final ids = raw
                .whereType<String>()
                .where(anatomyPriorityIds.contains)
                .map(canonicalMuscle)
                .toSet();
            if (ids.length <= 3) {
              setState(() {
                _selected
                  ..clear()
                  ..addAll(ids);
              });
            }
            return;
          }
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
          onWebResourceError: (error) {
            if (widget.prioritySelection &&
                error.isForMainFrame == true &&
                mounted) {
              setState(() {
                _loading = false;
                _selectionLoadFailed = true;
              });
            }
          },
          onPageFinished: (_) async {
            if (widget.prioritySelection) {
              final raw = anatomyPriorityIds
                  .where((id) => _selected.contains(canonicalMuscle(id)))
                  .toList();
              try {
                await _controller.runJavaScript(
                  'configurePrioritySelection(${jsonEncode(raw)}, ${jsonEncode(anatomyPriorityIds)})',
                );
              } catch (_) {
                if (mounted) {
                  setState(() {
                    _loading = false;
                    _selectionLoadFailed = true;
                  });
                }
                return;
              }
            }
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      await _server.start();
      if (!mounted) {
        _server.stop();
        return;
      }
      await _controller.loadRequest(
        Uri.parse('http://127.0.0.1:${_server.port}/index.html'),
      );
    } catch (_) {
      if (!widget.prioritySelection) rethrow;
      if (mounted) {
        setState(() {
          _loading = false;
          _selectionLoadFailed = true;
        });
      }
    }
  }

  void _toggleView() {
    setState(() => _isBackView = !_isBackView);
    _controller.runJavaScript('toggleView()');
  }

  void _resetFocus() {
    setState(_selected.clear);
    if (!widget.prioritySelection) MuscleFocus.selected.value = [];
    _controller.runJavaScript('clearAll()');
  }

  void _openWorkout() {
    if (widget.prioritySelection) {
      Navigator.of(context).pop(List<String>.of(_selected));
      return;
    }
    if (_selected.isEmpty) return;
    MuscleFocus.selected.value = List.of(_selected);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusWorkoutPage(muscles: List.of(_selected)),
      ),
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

    final page = Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        title: Text(
          widget.prioritySelection
              ? 'Select Priority Muscles'
              : 'Anatomy Focus Map',
          style: TextStyle(
            color: c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.prioritySelection
                      ? 'Choose up to 3 priorities'
                      : 'Tap Muscles to Prioritize',
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_selectionLoadFailed)
                    Center(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectionLoadFailed = false;
                            _loading = true;
                          });
                          _startServer();
                        },
                        child: const Text('Retry anatomy map'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  if (widget.prioritySelection)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _selected.isEmpty
                            ? 'Optional: keep balanced training with no extra emphasis.'
                            : _selected.map(trainingLabel).join(', '),
                        style: TextStyle(color: c.ink),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _barButton(
                          c,
                          Icons.flip_rounded,
                          _isBackView ? 'Showing: Back' : 'Showing: Front',
                          _toggleView,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _barButton(
                          c,
                          Icons.restart_alt_rounded,
                          'Reset Focus',
                          _resetFocus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          widget.prioritySelection &&
                              (_loading || _selectionLoadFailed)
                          ? null
                          : _openWorkout,
                      style: FilledButton.styleFrom(
                        backgroundColor: ready ? c.ink : c.chip,
                        foregroundColor: ready ? c.page : c.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        widget.prioritySelection
                            ? 'Continue'
                            : ready
                            ? 'Get workout · ${_selected.join(', ')}'
                            : 'Tap a muscle',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return widget.prioritySelection ? ArcPlanTheme(child: page) : page;
  }

  Widget _barButton(
    ArcColors c,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
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
            Text(
              label,
              style: TextStyle(
                color: c.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
