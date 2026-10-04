import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'body_server.dart';
import 'theme_ctrl.dart';

class AnatomyTestPage extends StatefulWidget {
  const AnatomyTestPage({super.key});

  @override
  State<AnatomyTestPage> createState() => _AnatomyTestPageState();
}

class _AnatomyTestPageState extends State<AnatomyTestPage> {
  final BodyServer _server = BodyServer();
  late final WebViewController _controller;
  bool _loading = true;
  bool _isBackView = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
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
    final url = 'http://127.0.0.1:${_server.port}/index.html';
    await _controller.loadRequest(Uri.parse(url));
  }

  void _toggleView() {
    setState(() {
      _isBackView = !_isBackView;
    });
    _controller.runJavaScript('toggleView()');
  }

  void _resetFocus() {
    _controller.runJavaScript('clearAll()');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Muscle selection reset'),
        duration: Duration(seconds: 1),
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (_, mode, __) {
        final c = ArcColors.of(context);

        return Scaffold(
          backgroundColor: c.page,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Anatomy Focus Map',
              style: TextStyle(color: c.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            iconTheme: IconThemeData(color: c.ink),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _controller.reload(),
                tooltip: 'Reload Viewer',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header Label
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap Muscles to Prioritize',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Body Anatomy Rendered Directly on Page (No Container / Box Window)
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: WebViewWidget(controller: _controller),
                      ),
                      if (_loading)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),

                // Liquid Metal Control Buttons Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      // Liquid Metal Flip Button
                      Expanded(
                        child: InkWell(
                          onTap: _toggleView,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 52,
                            decoration: metalPanel(c, radius: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flip_rounded,
                                  color: c.brand,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isBackView ? 'Showing: Back' : 'Showing: Front',
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Liquid Metal Reset Button
                      Expanded(
                        child: InkWell(
                          onTap: _resetFocus,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 52,
                            decoration: metalPanel(c, radius: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restart_alt_rounded,
                                  color: c.muted,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reset Focus',
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}
