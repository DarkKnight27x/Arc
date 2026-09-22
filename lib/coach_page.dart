import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_ctrl.dart';
import 'widgets/location_label.dart';

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.ink.withOpacity(_animations[index].value),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class CoachPage extends StatefulWidget {
  const CoachPage({super.key, this.coachOnly = false, this.session});

  final bool coachOnly;
  final String? session;

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _Msg {
  const _Msg(this.mine, this.text);
  final bool mine;
  final String text;
}

class _CoachPageState extends State<CoachPage> {
  int tab = 0;
  final search = TextEditingController();
  final input = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _conversationId;

  final lines = <_Msg>[];

  static const physios = [
    ('Motion Lab Physio', 'Thane West · 1.2 km', 'Sports + shoulder'),
    ('Restore Clinic', 'Naupada · 2.1 km', 'Post-op + strength'),
    ('Hiranandani Physio', 'Powai · 6.4 km', 'Knee + spine'),
    ('Bandra Sports PT', 'Bandra W · 18 km', 'Lifters + return to gym'),
  ];

  @override
  void dispose() {
    search.dispose();
    input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (force || maxScroll - currentScroll <= 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _send([String? raw]) async {
    if (_isLoading) return;

    final t = (raw ?? input.text).trim();
    if (t.isEmpty) return;

    input.clear();

    setState(() {
      lines.add(_Msg(true, t));
      _isLoading = true;
    });

    _scrollToBottom(force: true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous_user';
      if (_conversationId == null) {
        _conversationId = widget.session ?? 'conv_${DateTime.now().millisecondsSinceEpoch}';
      }

      final history = lines.map((m) => {
        'role': m.mine ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final conversationHistory = history;

      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
      final url = Uri.parse('$baseUrl/coach/message');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'conversation_id': _conversationId,
          'message': t,
          'conversation': conversationHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['message'] as String? ?? 'No response received.';
        if (mounted) {
          setState(() {
            lines.add(_Msg(false, reply));
          });
        }
      } else {
        if (mounted) {
          setState(() {
            lines.add(const _Msg(false, 'Sorry, I couldn\'t reach the coach right now. Please try again.'));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          lines.add(const _Msg(false, 'A network error occurred. Please check your connection and try again.'));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, __, ___) {
        final c = ArcColors.of(context);
        final q = search.text.trim().toLowerCase();
        final list = physios
            .where((p) =>
        q.isEmpty ||
            p.$1.toLowerCase().contains(q) ||
            p.$2.toLowerCase().contains(q) ||
            p.$3.toLowerCase().contains(q))
            .toList();

        return Scaffold(
          backgroundColor: c.page,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    children: [
                      Row(
                        children: [
                          if (widget.coachOnly)
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back, color: c.ink),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (widget.coachOnly) const SizedBox(width: 12),
                          const ArcLogo(),
                          const Spacer(),
                            LocationLabel(c: c),
                        ],
                      ),
                      const SizedBox(height: 16),
                        Text(
                          widget.coachOnly
                            ? 'COACH  ·  LIVE CONTEXT'
                            : 'RECOVER  ·  LIVE CONTEXT',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.1,
                              color: c.faint,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: widget.coachOnly ? 'Coach\n' : 'Recover\n',
                            style: TextStyle(
                                fontSize: 36,
                                height: 1.02,
                                fontWeight: FontWeight.w500,
                                color: c.ink)),
                        TextSpan(
                            text: 'for today.',
                            style: TextStyle(
                                fontSize: 36,
                                height: 1.02,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: c.ink)),
                      ])),
                      const SizedBox(height: 6),
                      Text(
                          widget.coachOnly
                              ? (widget.session ?? 'Training context')
                              : 'Training · food · recovery',
                          style: TextStyle(fontSize: 14, color: c.muted)),
                      const SizedBox(height: 14),
                      if (!widget.coachOnly)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: metalWell(c),
                          child: Row(
                            children: [
                              _Seg('Rehab', tab == 0, c,
                                  () => setState(() => tab = 0)),
                              _Seg('Physio', tab == 1, c,
                                  () => setState(() => tab = 1)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (widget.coachOnly) _coach(c),
                      if (!widget.coachOnly && tab == 0) _rehab(c),
                      if (!widget.coachOnly && tab == 1) _physio(c, list),
                    ],
                  ),
                ),
                if (widget.coachOnly) _composer(c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coach(ArcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Hint(c, 'Swap this machine', () => _send('Swap this machine')),
            _Hint(c, '10-min cut', () => _send('Give me a 10-min cut')),
            _Hint(c, 'Shoulder feels off', () => _send('Shoulder feels off')),
          ],
        ),
        const SizedBox(height: 14),
        for (final m in lines) _Bubble(c: c, msg: m),
        if (_isLoading)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(14),
              decoration: metalPanel(c),
              child: const _ThinkingIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _composer(ArcColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: metalWell(c),
        child: Row(
          children: [
            PressScale(
              onTap: () => _send('Attached a note'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.raised,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: Icon(Icons.add, color: c.ink, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: input,
                style: TextStyle(color: c.ink),
                cursorColor: c.ice,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Ask anything about today…',
                  hintStyle: TextStyle(color: c.faint, fontSize: 14),
                  filled: true,
                  fillColor: c.chip,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.ice),
                  ),
                  isDense: true,
                ),
              ),
            ),
            PressScale(
              onTap: _send,
              child: Container(
                width: 36,
                height: 36,
                decoration: metalPrimary(c).copyWith(
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(Icons.arrow_forward, color: c.ctaInk, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rehab(ArcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARC screens what you report. It does not diagnose an injury.',
          style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORTED',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1.0, color: c.faint)),
              const SizedBox(height: 6),
              Text('Shoulder tightness · left',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: c.ink)),
              Text('Idle this week · no clinician note uploaded',
                  style: TextStyle(fontSize: 13, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: metalPanel(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In the gym',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
              const SizedBox(height: 8),
              Text('Keep pressing. Drop overhead if it pinches.',
                  style: TextStyle(fontSize: 14, color: c.muted)),
              Text('Prefer supported machines.',
                  style: TextStyle(fontSize: 14, color: c.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MetalBtn(
          label: 'Find a physiotherapist',
          onTap: () => setState(() => tab = 1),
        ),
      ],
    );
  }

  Widget _physio(ArcColors c, List<(String, String, String)> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search real physios near you',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 6),
        Text('Thane / Mumbai · sample until bookings are live.',
            style: TextStyle(fontSize: 13, color: c.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.ink),
          decoration: InputDecoration(
            hintText: 'Name, area, or specialty',
            hintStyle: TextStyle(color: c.faint),
            prefixIcon: Icon(Icons.search, color: c.muted),
            filled: true,
            fillColor: c.chip,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PressScale(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: metalPanel(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.$1,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                    Text(p.$2, style: TextStyle(fontSize: 13, color: c.muted)),
                    Text(p.$3, style: TextStyle(fontSize: 12, color: c.faint)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg(this.label, this.on, this.c, this.tap);
  final String label;
  final bool on;
  final ArcColors c;
  final VoidCallback tap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        onTap: tap,
        child: AnimatedContainer(
          duration: ArcMotion.base,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: on ? c.ink : c.muted)),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.c, this.label, this.onTap);
  final ArcColors c;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: metalWell(c),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: c.ink)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.c, required this.msg});
  final ArcColors c;
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: metalPanel(c),
        child: Text(msg.text,
            style: TextStyle(fontSize: 14, height: 1.4, color: c.ink)),
      ),
    );
  }
}