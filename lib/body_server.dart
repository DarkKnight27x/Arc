import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class BodyServer {
  HttpServer? _server;

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_handleRequest);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      0,
    );

    print('BODY SERVER STARTED: http://127.0.0.1:$port');
  }

  Future<Response> _handleRequest(Request request) async {
    var path = request.url.path;
    if (path == 'favicon.ico') {
      return Response.notFound('');
    }

    print('BODY REQUEST: "$path"');

    // Browser requesting the main page.
    if (path.isEmpty || path == '/') {
      path = 'index.html';
    }

    // Remove leading slash.
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Explicitly map the model.
    if (path == 'human.glb') {
      return _loadAsset(
        'assets/3d_viewer/human.glb',
        'human.glb',
      );
    }

    // Everything else is relative to assets/3d_viewer.
    final assetPath = 'assets/3d_viewer/$path';

    return _loadAsset(assetPath, path);
  }

  Future<Response> _loadAsset(
      String assetPath,
      String requestPath,
      ) async {
    print('BODY ASSET: "$assetPath"');

    try {
      final data = await rootBundle.load(assetPath);

      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      print(
        'BODY 200: "$assetPath" (${bytes.length} bytes)',
      );

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': _contentType(requestPath),
          'Cache-Control': 'no-cache',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      print('BODY 404: "$assetPath"');
      print('BODY ERROR: $e');

      return Response.notFound(
        'Asset not found: $assetPath',
      );
    }
  }

  String _contentType(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.html')) {
      return 'text/html; charset=utf-8';
    }

    if (lower.endsWith('.js')) {
      return 'application/javascript; charset=utf-8';
    }

    if (lower.endsWith('.css')) {
      return 'text/css; charset=utf-8';
    }

    if (lower.endsWith('.json')) {
      return 'application/json; charset=utf-8';
    }

    if (lower.endsWith('.glb')) {
      return 'model/gltf-binary';
    }

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.svg')) {
      return 'image/svg+xml';
    }

    if (lower.endsWith('.woff')) {
      return 'font/woff';
    }

    if (lower.endsWith('.woff2')) {
      return 'font/woff2';
    }

    return 'application/octet-stream';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}