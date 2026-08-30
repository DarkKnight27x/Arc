import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'body_server.dart';

class BodyAvatar extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const BodyAvatar({
    super.key,
    this.height = 350,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(20),
    ),
  });

  @override
  State<BodyAvatar> createState() => _BodyAvatarState();
}

class _BodyAvatarState extends State<BodyAvatar> {
  final BodyServer server = BodyServer();

  late final WebViewController controller;

  bool loading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint(
              'BODY WEBVIEW STARTED: $url',
            );
          },
          onPageFinished: (url) {
            debugPrint(
              'BODY WEBVIEW FINISHED: $url',
            );

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              'BODY WEBVIEW ERROR: '
                  'code=${error.errorCode}, '
                  'description=${error.description}, '
                  'url=${error.url}',
            );
          },
        ),
      );

    _startServer();
  }

  Future<void> _startServer() async {
    await server.start();

    final url =
        'http://127.0.0.1:${server.port}/';

    debugPrint(
      'BODY VIEWER URL: $url',
    );

    await controller.loadRequest(
      Uri.parse(url),
    );
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(
                controller: controller,
              ),
            ),

            if (loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xFF111111),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}