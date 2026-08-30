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

    if (path.isEmpty) {
      path = 'index.html';
    }

    if (path.endsWith('/')) {
      path += 'index.html';
    }

    final assetPath = 'assets/3d_viewer/$path';

    try {
      final data = await rootBundle.load(assetPath);

      final bytes = data.buffer.asUint8List();

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': _contentType(path),
          'Cache-Control': 'no-cache',
        },
      );
    } catch (e) {
      print('BODY SERVER 404: $assetPath');

      return Response.notFound(
        'Asset not found: $path',
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

    return 'application/octet-stream';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}