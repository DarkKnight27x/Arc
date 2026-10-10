import 'dart:async';

import 'package:flutter/material.dart';

import '../data/exercise_media.dart';
import '../theme_ctrl.dart';

/// Shared, bounded media loading for cards, previews and saved sessions.
class ExerciseMedia extends StatefulWidget {
  const ExerciseMedia({
    super.key,
    this.path,
    this.exerciseId,
    this.fit = BoxFit.cover,
    this.lookup = ExerciseMediaPath.latest,
  });
  final Object? path;
  final String? exerciseId;
  final BoxFit fit;
  final Future<Object?> Function(String) lookup;
  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia>
    with WidgetsBindingObserver {
  Object? path;
  int request = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    path = widget.path;
    refresh();
  }

  @override
  void didUpdateWidget(ExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.exerciseId != widget.exerciseId ||
        oldWidget.lookup != widget.lookup) {
      path = widget.path;
      refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final token = ++request;
    final id = widget.exerciseId;
    if (id == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id)) {
      return;
    }
    try {
      final current = await widget
          .lookup(id)
          .timeout(const Duration(seconds: 15));
      if (mounted && token == request) setState(() => path = current);
    } catch (_) {
      // Offline/RLS failures must not interrupt training or expose raw errors.
    }
  }

  @override
  void dispose() {
    request++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ExerciseMediaPath.publicUrl(path);
    return resolved == null
        ? const ExerciseMediaFallback()
        : _LoadedMedia(
            // A fresh display attempt also retries an earlier missing file at
            // the same URL, without caching an unavailable result forever.
            key: ValueKey((resolved, request)),
            path: resolved,
            fit: widget.fit,
          );
  }
}

class _LoadedMedia extends StatefulWidget {
  const _LoadedMedia({super.key, required this.path, required this.fit});
  final String path;
  final BoxFit fit;
  @override
  State<_LoadedMedia> createState() => _LoadedMediaState();
}

class _LoadedMediaState extends State<_LoadedMedia> {
  Timer? timer;
  bool expired = false;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => expired = true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (expired) return const ExerciseMediaFallback();
    Widget frame(BuildContext context, Widget child, int? frame, bool sync) {
      if (sync || frame != null) {
        timer?.cancel();
        return child;
      }
      return const ExerciseMediaFallback();
    }

    Widget error(BuildContext context, Object error, StackTrace? stack) {
      timer?.cancel();
      return const ExerciseMediaFallback();
    }

    return widget.path.startsWith('assets/')
        ? Image.asset(
            widget.path,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          )
        : Image.network(
            widget.path,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          );
  }
}

class ExerciseMediaFallback extends StatelessWidget {
  const ExerciseMediaFallback({super.key});
  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return ColoredBox(
      color: c.raised,
      child: LayoutBuilder(
        builder: (context, size) => Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: size.maxWidth - 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'COMING SOON',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: size.maxWidth < 100 ? 9 : 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (size.maxWidth >= 180 && size.maxHeight >= 120) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Exercise demo in production',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
